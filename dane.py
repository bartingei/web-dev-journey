from flask import Flask, render_template, request, jsonify
from tensorflow.keras.models import load_model
import cv2
import numpy as np
from PIL import Image
import io
import base64
import sys
import os

# Set default encoding to UTF-8
sys.stdout.reconfigure(encoding='utf-8')

# Set the environment variable to enable OneDNN optimizations
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '1'

template_dir = os.path.abspath('./src/templates')
static_dir = os.path.abspath('./src/static')
app = Flask(__name__, template_folder=template_dir, static_folder=static_dir)

model = None

def load_model_once():
    """This function loads the model only once. It uses a global variable to store the loaded model. If the model is already loaded,
    it does not load it again.
    """
    global model
    if model is None:
        model = load_model('./model/pneumonia_x_rays_v3_0.keras')
        print("Model loaded successfully!")

label_dict = {0: "Pneumonia Negative", 1: "Pneumonia Positive"}

def preprocess(image):
    '''
    Takes in an image and preprocesses it for the model.

    Args:
        image (PIL.Image.Image): An image of any shape.

    Returns:
        np.ndarray: A reshaped image that has been converted to grayscale, resized, normalized, and reshaped.

    Raises:
        ValueError: If the image mode is neither RGB nor RGBA.

    '''
    # Convert image to numpy array
    img_array = np.array(image)

    # Convert to grayscale if the image is not already grayscale
    if img_array.ndim == 3:
        img_array = cv2.cvtColor(img_array, cv2.COLOR_RGB2GRAY)
    elif img_array.ndim == 4 and img_array.shape[2] == 4:
        # If the image has an alpha channel, remove it
        img_array = cv2.cvtColor(img_array, cv2.COLOR_RGBA2GRAY)
    else:
        raise ValueError("Image mode must be either RGB or RGBA.")

    # Resize the image to the required size
    resized_img = cv2.resize(img_array, (224, 224))

    # Normalize the image
    normalized_img = resized_img / 255.0

    # Reshape the image to add the batch and channel dimensions
    reshaped_img = normalized_img.reshape(1, 224, 224, 1)

    return reshaped_img

@app.before_request
def before_first_request():
    '''
    This function is a Flask decorator that runs before the first request to the application.
    It is used to load the model only once, which improves the performance of the application.

    Parameters:
    None

    Returns:
    None
    '''
    load_model_once()

@app.route("/")
def index():
    '''Renders the HTML Template for UI. Html index body for the application'''
    return render_template("index.html")

@app.route("/predict", methods=['POST'])
def predict():
    '''
    Defines a route that handles POST requests to "/predict".
    This function receives an image in base64 format, decodes it,
    preprocesses it, and makes a prediction using the loaded model.
    The prediction is then formatted into a JSON response.

    Args:
        No Args.

    Returns:
        The response as a JSON object.
        If an error occurs during processing, a JSON object with an error message is returned.

    Raises:
        Exception: If any error occurs during processing.
    '''
    try:
        # Receive the image data in JSON format
        message = request.get_json(force=True)

        # Extract the base64 encoded image data
        encoded = message['image']

        # Decode the base64 encoded image data
        decoded = base64.b64decode(encoded)

        # Create a BytesIO object from the decoded image data
        dataBytesIO = io.BytesIO(decoded)

        # Open the image using the BytesIO object
        image = Image.open(dataBytesIO)

        # Print debugging information about the image
        print(f"Image mode: {image.mode}, size: {image.size}")

        # Preprocess the image for the model
        test_image = preprocess(image)

        # Make a prediction using the loaded model
        prediction = model.predict(test_image)

        # Print debugging information about the prediction
        print(f"Prediction shape: {prediction.shape}")
        print(f"Prediction values: {prediction}")

        # Since the model returns a single probability value for the positive class,
        # calculate the probability of the negative class
        positive_probability = float(prediction[0][0])
        negative_probability = 1.0 - positive_probability

        # Format the prediction into a JSON response
        response = {
            'prediction': {
                'result': label_dict[int(positive_probability > 0.5)],
                'accuracy': positive_probability,
                'negative_probability': negative_probability,
                'positive_probability': positive_probability
            }
        }

        # Return the JSON response
        return jsonify(response)

    except Exception as e:
        # Print the error message
        print(f"Error: {e}")

        # Return a JSON response with an error message
        return jsonify({'error': 'Could not process image'}), 500

if __name__ == '__main__':
    app.run(debug=True)
    