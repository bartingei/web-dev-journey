let currentSection = 0;
const sections = document.querySelectorAll(".section");

document.addEventListener("wheel", (event) => {
    if (event.deltaY > 0) {
        // Scrolling Down
        if (currentSection < sections.length - 1) {
            currentSection++;
        }
    } else {
        // Scrolling Up
        if (currentSection > 0) {
            currentSection--;
        }
    }

    sections.forEach((section, index) => {
        section.style.transform = `translateY(-${currentSection * 100}vh)`;
    });

    event.preventDefault(); // Prevent default scrolling
});


