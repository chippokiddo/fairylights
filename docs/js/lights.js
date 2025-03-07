document.addEventListener("DOMContentLoaded", function () {
    const LIGHTS_STORAGE_KEY = "fairy-lights-preference";
    const LIGHTS_ENABLED = "enabled";
    const LIGHTS_DISABLED = "disabled";

    const fairyLights = document.getElementById("fairy-lights");
    const appIcon = document.getElementById("app-icon");

    let isLightsEnabled = localStorage.getItem(LIGHTS_STORAGE_KEY) === LIGHTS_ENABLED;
    let isAnimating = false;
    let animationFrameId = null;
    let bulbs = [];

    const config = {
        colors: {
            red: { base: "#ff5252", glow: "rgba(255, 82, 82, 0.8)" },
            green: { base: "#4caf50", glow: "rgba(76, 175, 80, 0.8)" },
            blue: { base: "#2196f3", glow: "rgba(33, 150, 243, 0.8)" },
            yellow: { base: "#ffc107", glow: "rgba(255, 193, 7, 0.8)" }
        },
        animationSettings: {
            minIntensity: 0.7,
            maxIntensity: 1.0,
            minSwingAngle: -5,
            maxSwingAngle: 5,
            swingDuration: 3000,
            glowDuration: 2000,
            staggerDelay: 500
        }
    };

    function init() {
        if (!fairyLights || !appIcon) {
            console.error("Required DOM elements for fairy lights not found");
            return;
        }

        collectBulbs();

        setupEventListeners();

        initializeBulbs();

        if (isLightsEnabled) {
            showLights();
        } else {
            hideLights();
        }
    }

    function collectBulbs() {
        bulbs = Array.from(fairyLights.querySelectorAll(".bulb"));
    }

    function setupEventListeners() {
        appIcon.addEventListener("click", toggleLights);

        appIcon.addEventListener("keydown", function (event) {
            if (event.key === "Enter" || event.key === " ") {
                event.preventDefault();
                toggleLights();
            }
        });

        document.addEventListener("visibilitychange", handleVisibilityChange);

        document.body.addEventListener("themechange", updateBulbColors);
    }

    function initializeBulbs() {
        bulbs.forEach((bulb, index) => {
            const colorClass = Array.from(bulb.classList)
                .find(cls => cls.startsWith('bulb-'));

            bulb._colorType = colorClass.replace('bulb-', '');
            bulb._initialDelay = index * config.animationSettings.staggerDelay;
            bulb._swingPhase = Math.random() * Math.PI * 2;
            bulb._glowPhase = Math.random() * Math.PI * 2;
        });
    }

    function toggleLights() {
        isLightsEnabled = !isLightsEnabled;

        if (isLightsEnabled) {
            localStorage.setItem(LIGHTS_STORAGE_KEY, LIGHTS_ENABLED);
            showLights();
        } else {
            localStorage.setItem(LIGHTS_STORAGE_KEY, LIGHTS_DISABLED);
            hideLights();
        }
    }

    function showLights() {
        fairyLights.classList.remove("hidden");
        appIcon.classList.add("glowing");

        if (!isAnimating) {
            isAnimating = true;
            animateLights();
        }
    }

    function hideLights() {
        fairyLights.classList.add("hidden");
        appIcon.classList.remove("glowing");

        if (isAnimating) {
            isAnimating = false;
            cancelAnimationFrame(animationFrameId);
        }
    }

    function animateLights(timestamp) {
        if (!isAnimating) return;

        bulbs.forEach((bulb, index) => {
            const adjustedTime = timestamp - bulb._initialDelay;

            const swingProgress = (Math.sin((adjustedTime + bulb._swingPhase) / config.animationSettings.swingDuration * Math.PI * 2) + 1) / 2;
            const swingAngle = config.animationSettings.minSwingAngle +
                swingProgress * (config.animationSettings.maxSwingAngle - config.animationSettings.minSwingAngle);

            const glowProgress = (Math.sin((adjustedTime + bulb._glowPhase) / config.animationSettings.glowDuration * Math.PI * 2) + 1) / 2;
            const intensity = config.animationSettings.minIntensity +
                glowProgress * (config.animationSettings.maxIntensity - config.animationSettings.minIntensity);

            updateBulbStyles(bulb, swingAngle, intensity);
        });

        animationFrameId = requestAnimationFrame(animateLights);
    }

    function updateBulbStyles(bulb, swingAngle, intensity) {
        const colorType = bulb._colorType;
        const colors = config.colors[colorType];

        if (!colors) return;

        bulb.style.transform = `rotate(${swingAngle}deg)`;

        const isDarkTheme = document.body.classList.contains("dark-theme");
        const glowSize = isDarkTheme ? 15 : 20;
        const glowSpread = isDarkTheme ? 5 : 8;

        bulb.style.backgroundColor = colors.base;
        bulb.style.opacity = intensity;

        const shadowSize = (glowSize * intensity);
        const shadowSpread = (glowSpread * intensity);

        if (!isDarkTheme) {
            bulb.style.boxShadow = `0 0 ${shadowSize}px ${shadowSpread}px ${colors.glow}`;
        } else {
            bulb.style.boxShadow = `0 0 ${shadowSize}px ${shadowSpread}px ${colors.glow}`;
        }
    }

    function updateBulbColors() {
        bulbs.forEach(bulb => {
            const swingStyle = bulb.style.transform;
            const intensity = parseFloat(bulb.style.opacity) || config.animationSettings.maxIntensity;

            updateBulbStyles(bulb,
                parseFloat(swingStyle.replace('rotate(', '').replace('deg)', '')) || 0,
                intensity);
        });
    }

    function handleVisibilityChange() {
        if (document.visibilityState === "visible") {
            if (isLightsEnabled && !isAnimating) {
                isAnimating = true;
                animateLights();
            }
        } else {
            isAnimating = false;
            if (animationFrameId) {
                cancelAnimationFrame(animationFrameId);
                animationFrameId = null;
            }
        }
    }

    init();
});