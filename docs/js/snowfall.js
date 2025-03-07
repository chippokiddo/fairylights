document.addEventListener("DOMContentLoaded", function() {
  const SNOWFALL_STORAGE_KEY = "fairy-lights-snowfall-preference";
  const SNOWFALL_ENABLED = "enabled";
  const SNOWFALL_DISABLED = "disabled";
  
  const container = document.getElementById("snowfall-container");
  const toggleButton = document.getElementById("snowfall-toggle-button");
  
  let isEnabled = localStorage.getItem(SNOWFALL_STORAGE_KEY) !== SNOWFALL_DISABLED;
  let isRunning = false;
  let snowflakes = [];
  let animationFrameId = null;
  let lastTimestamp = 0;
  
  const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (prefersReducedMotion) {
    console.log("Reduced motion preference detected, disabling snowfall");
    isEnabled = false;
    localStorage.setItem(SNOWFALL_STORAGE_KEY, SNOWFALL_DISABLED);
  }
  
  const config = {
    get maxFlakes() { return window.innerWidth <= 768 ? 15 : 25; },
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
  
  function init() {
    if (!container || !toggleButton) {
      console.error("Required DOM elements not found");
      return;
    }
    
    updateUIState();
    
    toggleButton.addEventListener("click", toggleSnowfall);
    toggleButton.addEventListener("keydown", function(event) {
      if (event.key === "Enter" || event.key === " ") {
        event.preventDefault();
        toggleSnowfall();
      }
    });
    
    if (isEnabled) {
      startSnowfall();
    }
    
    setupGlobalEventListeners();
  }
  
  function setupGlobalEventListeners() {
    document.addEventListener("visibilitychange", handleVisibilityChange);
    
    window.addEventListener("resize", debounce(handleResize, 200));
    
    window.addEventListener("scroll", handleScroll, { passive: true });
    
    document.body.addEventListener("themechange", updateSnowColor);
  }
  
  function updateUIState() {
    if (isEnabled) {
      toggleButton.classList.add("active");
      container.style.display = "block";
    } else {
      toggleButton.classList.remove("active");
      container.style.display = "none";
    }
  }
  
  function toggleSnowfall() {
    isEnabled = !isEnabled;
    
    if (isEnabled) {
      localStorage.setItem(SNOWFALL_STORAGE_KEY, SNOWFALL_ENABLED);
      startSnowfall();
    } else {
      localStorage.setItem(SNOWFALL_STORAGE_KEY, SNOWFALL_DISABLED);
      stopSnowfall();
    }
    
    updateUIState();
  }
  
  function startSnowfall() {
    if (isRunning) return;
    
    if (snowflakes.length > 0) {
      clearSnowflakes();
    }
    
    createInitialSnowflakes();
    
    isRunning = true;
    lastTimestamp = 0;
    
    if (animationFrameId) {
      cancelAnimationFrame(animationFrameId);
    }
    
    animationFrameId = requestAnimationFrame(animateSnowflakes);
  }
  
  function stopSnowfall() {
    isRunning = false;
    
    if (animationFrameId) {
      cancelAnimationFrame(animationFrameId);
      animationFrameId = null;
    }
  }
  
  function clearSnowflakes() {
    snowflakes.forEach(flake => container.removeChild(flake));
    snowflakes = [];
  }
  
  function createInitialSnowflakes() {
    const maxFlakes = config.maxFlakes;
    
    for (let i = 0; i < maxFlakes; i++) {
      createSnowflake();
    }
  }
  
  function createSnowflake() {
    const flake = document.createElement("div");
    flake.className = "snowflake";
    
    const size = config.minSize + Math.random() * (config.maxSize - config.minSize);
    flake.style.width = `${size}px`;
    flake.style.height = `${size}px`;
    
    flake.style.opacity = config.minOpacity + Math.random() * (config.maxOpacity - config.minOpacity);
    
    applyThemeColorToSnowflake(flake);
    
    flake.style.left = `${Math.random() * 100}%`;
    flake.style.top = `${-20 - Math.random() * 100}px`;
    
    flake._posY = parseFloat(flake.style.top);
    flake._posX = parseFloat(flake.style.left);
    flake._speed = config.minSpeed + Math.random() * (config.maxSpeed - config.minSpeed);
    flake._wobble = config.minWobble + Math.random() * (config.maxWobble - config.minWobble);
    flake._wobbleSpeed = config.minWobbleSpeed + Math.random() * (config.maxWobbleSpeed - config.minWobbleSpeed);
    flake._wobblePos = Math.random() * Math.PI * 2;
    
    container.appendChild(flake);
    snowflakes.push(flake);
    
    return flake;
  }
  
  function applyThemeColorToSnowflake(flake) {
    const isDarkTheme = document.body.classList.contains("dark-theme");
    
    if (isDarkTheme) {
      flake.style.backgroundColor = "white";
      flake.style.boxShadow = "0 0 5px rgba(255, 255, 255, 0.6)";
    } else {
      flake.style.backgroundColor = "white";
      flake.style.boxShadow = "0 0 5px rgba(255, 255, 255, 0.8)";
    }
  }
  
  function updateSnowColor() {
    snowflakes.forEach(flake => {
      applyThemeColorToSnowflake(flake);
    });
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
        resetSnowflake(flake);
      }
    }
    
    if (isRunning) {
      animationFrameId = requestAnimationFrame(animateSnowflakes);
    }
  }
  
  function resetSnowflake(flake) {
    flake._posY = -20 - Math.random() * 50;
    flake.style.left = `${Math.random() * 100}%`;
    flake._speed = config.minSpeed + Math.random() * (config.maxSpeed - config.minSpeed);
    flake._wobble = config.minWobble + Math.random() * (config.maxWobble - config.minWobble);
  }
  
  function handleVisibilityChange() {
    if (document.visibilityState === "visible") {
      if (isEnabled && !isRunning) {
        startSnowfall();
      }
    } else {
      isRunning = false;
      if (animationFrameId) {
        cancelAnimationFrame(animationFrameId);
        animationFrameId = null;
      }
    }
  }
  
  function handleResize() {
    if (!isEnabled) return;
    
    const newMaxFlakes = config.maxFlakes;
    
    while (snowflakes.length < newMaxFlakes) {
      createSnowflake();
    }
    
    while (snowflakes.length > newMaxFlakes) {
      const flake = snowflakes.pop();
      container.removeChild(flake);
    }
  }

  function handleScroll() {
    if (isEnabled && !isRunning) {
      isRunning = true;
      lastTimestamp = 0;
      
      if (animationFrameId) {
        cancelAnimationFrame(animationFrameId);
      }
      
      animationFrameId = requestAnimationFrame(animateSnowflakes);
    }
  }

  function debounce(func, wait) {
    let timeout;
    return function() {
      const context = this;
      const args = arguments;
      clearTimeout(timeout);
      timeout = setTimeout(() => {
        func.apply(context, args);
      }, wait);
    };
  }
  
  init();
});