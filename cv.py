from PIL import Image, ImageDraw, ImageFont
img = Image.new('RGB', (100, 30), color='white')
draw = ImageDraw.Draw(img)
font = ImageFont.truetype("consola.ttf", 14)  # Monospace font
draw.text((10, 5), r"\[ \frac{1}{2} \]", font=font, fill="black")
img.save("latex_raw.png")