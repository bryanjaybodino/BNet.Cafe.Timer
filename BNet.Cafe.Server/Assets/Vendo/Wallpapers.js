const folderPath = 'Uploads/Wallpapers/';
const imageExtensions = ['.png', '.jpg', '.jpeg', '.webp'];
const sliderContainer = document.getElementById('slider');
const loadingText = document.getElementById('loadingText');

let validImages = [];
let slideIndex = 0;

function checkImageExists(url) {
    return new Promise((resolve) => {
        const img = new Image();
        img.onload = () => resolve(true);
        img.onerror = () => resolve(false);
        img.src = url;
    });
}

async function discoverImages() {
    let index = 1;
    while (true) {
        let found = false;
        for (const ext of imageExtensions) {
            const testPath = `${folderPath}${index}${ext}`;
            if (await checkImageExists(testPath)) {
                validImages.push(testPath);
                found = true;
                break;
            }
        }
        if (!found) break;
        index++;
    }

    if (validImages.length > 0) {
        if (loadingText) loadingText.remove();
        initSlider();
    } else {
        if (loadingText) loadingText.innerText = 'No wallpapers found in Uploads/Wallpapers/';
    }
}

function initSlider() {
    validImages.forEach((src, idx) => {
        const slide = document.createElement('div');
        slide.classList.add('slide');
        if (idx === 0) slide.classList.add('active');
        slide.style.backgroundImage = `url('${src}')`;
        sliderContainer.appendChild(slide);
    });

    if (validImages.length > 1) {
        setInterval(nextSlide, 10000);
    }
}

function nextSlide() {
    const slides = document.querySelectorAll('.slide');
    if (slides.length === 0) return;
    slides[slideIndex].classList.remove('active');
    slideIndex = (slideIndex + 1) % slides.length;
    slides[slideIndex].classList.add('active');
}