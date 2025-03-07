document.addEventListener("DOMContentLoaded", function() {
    const THEME_STORAGE_KEY = "fairy-lights-theme-preference";
    
    const THEME_SYSTEM = "system";
    const THEME_LIGHT = "light";
    const THEME_DARK = "dark";
    
    const THEME_SEQUENCE = [THEME_SYSTEM, THEME_LIGHT, THEME_DARK];
    
    const themeToggleButton = document.getElementById("theme-toggle-button");
    
    let currentTheme = localStorage.getItem(THEME_STORAGE_KEY) || THEME_SYSTEM;
    let currentThemeIndex = THEME_SEQUENCE.indexOf(currentTheme);
    
    if (currentThemeIndex === -1) {
      currentThemeIndex = 0;
      currentTheme = THEME_SEQUENCE[currentThemeIndex];
    }
    
    applyTheme(currentTheme);
    
    if (themeToggleButton) {
      themeToggleButton.addEventListener("click", cycleTheme);
      
      themeToggleButton.addEventListener("keydown", function(event) {
        if (event.key === "Enter" || event.key === " ") {
          event.preventDefault();
          cycleTheme();
        }
      });
    }
    
    function cycleTheme() {
      themeToggleButton.classList.add("spinning");
      
      currentThemeIndex = (currentThemeIndex + 1) % THEME_SEQUENCE.length;
      currentTheme = THEME_SEQUENCE[currentThemeIndex];
      
      setTimeout(() => {
        applyTheme(currentTheme);
      }, 150);
      
      localStorage.setItem(THEME_STORAGE_KEY, currentTheme);
      
      setTimeout(() => {
        themeToggleButton.classList.remove("spinning");
      }, 750);
    }

    function applyTheme(theme) {
      document.body.classList.remove("light-theme", "dark-theme", "system-theme");
      
      switch (theme) {
        case THEME_LIGHT:
          document.body.classList.add("light-theme");
          break;
          
        case THEME_DARK:
          document.body.classList.add("dark-theme");
          break;
          
        case THEME_SYSTEM:
        default:
          document.body.classList.add("system-theme");
          
          if (window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches) {
            document.body.classList.add("dark-theme");
          } else {
            document.body.classList.add("light-theme");
          }
          break;
      }
    }
    
    window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", (e) => {
      if (currentTheme === THEME_SYSTEM) {
        if (e.matches) {
          document.body.classList.remove("light-theme");
          document.body.classList.add("dark-theme");
        } else {
          document.body.classList.remove("dark-theme");
          document.body.classList.add("light-theme");
        }
      }
    });
  });