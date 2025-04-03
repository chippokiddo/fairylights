function setLightsState(isOn) {
    localStorage.setItem(LIGHTS_KEY, isOn);
    const bulbs = document.querySelectorAll('.bulb');

    if (isOn) {
        fairyLights.classList.remove('hidden');
        appIcon.classList.add('glowing');

        bulbs.forEach((bulb) => {
            bulb.classList.add('twinkling');
        });
    } else {
        fairyLights.classList.add('hidden');
        appIcon.classList.remove('glowing');

        bulbs.forEach((bulb) => {
            bulb.classList.remove('twinkling');
        });
    }
}
