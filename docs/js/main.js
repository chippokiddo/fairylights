document.addEventListener("DOMContentLoaded", function () {
  const appIcon = document.getElementById("app-icon");
  const fairyLights = document.getElementById("fairy-lights");
  const screenshotWrappers = document.querySelectorAll(".screenshot-wrapper");
  const interactiveElements = document.querySelectorAll(
    ".feature-card, .app-icon, .cta-button, .github-button"
  );

  if (fairyLights && appIcon) {
    appIcon.addEventListener("click", function () {
      toggleFairyLights();
    });

    appIcon.addEventListener("keydown", function (event) {
      if (event.key === "Enter" || event.key === " ") {
        event.preventDefault();
        toggleFairyLights();
      }
    });
  }

  function toggleFairyLights() {
    if (fairyLights.classList.contains("hidden")) {
      fairyLights.classList.remove("hidden");
      appIcon.classList.add("glowing");
    } else {
      fairyLights.classList.add("hidden");
      appIcon.classList.remove("glowing");
    }
  }

  if ("IntersectionObserver" in window) {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.style.opacity = "1";
            entry.target.style.transform = "translateY(0)";
          } else {
            entry.target.style.opacity = "0.8";
            entry.target.style.transform = "translateY(10px)";
          }
        });
      },
      { threshold: 0.1 }
    );

    screenshotWrappers.forEach((wrapper) => {
      wrapper.style.opacity = "0.8";
      wrapper.style.transform = "translateY(10px)";
      wrapper.style.transition = "opacity 0.5s ease, transform 0.5s ease";

      observer.observe(wrapper);
    });
  }

  interactiveElements.forEach((element) => {
    element.addEventListener("mouseenter", () => {
      element.classList.add("hover-active");
    });

    element.addEventListener("mouseleave", () => {
      element.classList.remove("hover-active");
    });
  });
});
