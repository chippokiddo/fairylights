document.addEventListener("DOMContentLoaded", function () {
  const SNOWFALL_STORAGE_KEY = "fairy-lights-snowfall-preference";
  const container = document.getElementById("snowfall-container");
  const snowfallToggleButton = document.getElementById("snowfall-toggle-button");
  let snowfallEnabled = localStorage.getItem(SNOWFALL_STORAGE_KEY) !== "disabled";
  let isRunning = true;
  let lastTimestamp = 0;
  const snowflakes = [];

  if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
    console.log("Reduced motion preference detected, disabling snowfall");
    snowfallEnabled = false;
    localStorage.setItem(SNOWFALL_STORAGE_KEY, "disabled");
  }

  if (!snowfallEnabled && container) {
    container.style.display = "none";
  }

  if (snowfallToggleButton) {
    if (snowfallEnabled) {
      snowfallToggleButton.classList.add("active");
    } else {
      snowfallToggleButton.classList.remove("active");
    }
  }

  if (snowfallEnabled && container) {
    initializeSnowfall();
  }

  if (snowfallToggleButton && container) {
    snowfallToggleButton.addEventListener("click", toggleSnowfall);
    snowfallToggleButton.addEventListener("keydown", function (event) {
      if (event.key === "Enter" || event.key === " ") {
        event.preventDefault();
        toggleSnowfall();
      }
    });
  }

  function toggleSnowfall() {
    snowfallEnabled = !snowfallEnabled;

    if (snowfallEnabled) {
      snowfallToggleButton.classList.add("active");
      container.style.display = "block";
      localStorage.setItem(SNOWFALL_STORAGE_KEY, "enabled");

      if (snowflakes.length === 0) {
        initializeSnowfall();
      } else {
        if (!isRunning) {
          isRunning = true;
          lastTimestamp = 0;
          requestAnimationFrame(animateSnowflakes);
        }
      }
    } else {
      snowfallToggleButton.classList.remove("active");
      container.style.display = "none";
      localStorage.setItem(SNOWFALL_STORAGE_KEY, "disabled");
      isRunning = false;
    }
  }

  function initializeSnowfall() {
    if (!container) return;

    const config = {
      maxFlakes: window.innerWidth <= 768 ? 15 : 25,
      minSize: 3,
      maxSize: 6,
      minOpacity: 0.3,
      maxOpacity: 0.9,
      minSpeed: 0.5,
      maxSpeed: 2.0,
      minWobble: 0.2,
      maxWobble: 1.0,
      minWobbleSpeed: 0.02,
      maxWobbleSpeed: 0.05
    };

    for (let i = 0; i < config.maxFlakes; i++) {
      createSnowflake(config);
    }

    requestAnimationFrame(animateSnowflakes);

    document.addEventListener("visibilitychange", handleVisibilityChange);
    window.addEventListener("resize", handleResize.bind(null, config));
  }

  function createSnowflake(config) {
    const flake = document.createElement("div");
    flake.className = "snowflake";

    const size = config.minSize + Math.random() * (config.maxSize - config.minSize);
    flake.style.width = `${size}px`;
    flake.style.height = `${size}px`;

    flake.style.opacity = config.minOpacity + Math.random() * (config.maxOpacity - config.minOpacity);

    flake.style.left = `${Math.random() * 100}%`;
    flake.style.top = `${-20 - Math.random() * 100}px`;

    flake._posY = parseInt(flake.style.top);
    flake._speed = config.minSpeed + Math.random() * (config.maxSpeed - config.minSpeed);
    flake._wobble = config.minWobble + Math.random() * (config.maxWobble - config.minWobble);
    flake._wobbleSpeed = config.minWobbleSpeed + Math.random() * (config.maxWobbleSpeed - config.minWobbleSpeed);
    flake._wobblePos = Math.random() * Math.PI * 2;

    container.appendChild(flake);
    snowflakes.push(flake);

    return flake;
  }

  function animateSnowflakes(timestamp) {
    if (!isRunning) return;

    if (!lastTimestamp) lastTimestamp = timestamp;
    const delta = timestamp - lastTimestamp;
    lastTimestamp = timestamp;

    const maxHeight = window.innerHeight + 50;

    for (let i = 0; i < snowflakes.length; i++) {
      const flake = snowflakes[i];

      flake._posY += flake._speed * (delta / 16);

      flake._wobblePos += flake._wobbleSpeed * (delta / 16);
      const wobbleOffset = Math.sin(flake._wobblePos) * flake._wobble;

      flake.style.transform = `translate(${wobbleOffset}px, ${flake._posY}px)`;

      if (flake._posY > maxHeight) {
        flake._posY = -20 - Math.random() * 50;
        flake.style.left = `${Math.random() * 100}%`;

        flake._speed = config.minSpeed + Math.random() * (config.maxSpeed - config.minSpeed);
        flake._wobble = config.minWobble + Math.random() * (config.maxWobble - config.minWobble);
      }
    }

    requestAnimationFrame(animateSnowflakes);
  }

  function handleVisibilityChange() {
    if (document.visibilityState === "visible") {
      if (snowfallEnabled && !isRunning) {
        isRunning = true;
        lastTimestamp = 0;
        requestAnimationFrame(animateSnowflakes);
      }
    } else {
      isRunning = false;
    }
  }

  function handleResize(config) {
    if (!snowfallEnabled) return;

    const newMaxFlakes = window.innerWidth <= 768 ? 15 : 25;

    while (snowflakes.length < newMaxFlakes) {
      createSnowflake(config);
    }

    while (snowflakes.length > newMaxFlakes) {
      const flake = snowflakes.pop();
      container.removeChild(flake);
    }
  }
});