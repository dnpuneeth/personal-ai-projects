// Theme toggle functionality
export function initializeThemeToggle() {
  const themeToggleBtn = document.getElementById('theme-toggle');
  const themePreferenceRadios = document.querySelectorAll('input[name="theme_preference"]');

  // Check for saved theme preference or default to 'auto'
  let currentTheme = localStorage.getItem('theme') || 'auto';

  // Apply the theme on page load
  applyTheme(currentTheme);

  // Set the correct radio button based on current theme
  setRadioButton(currentTheme);
  updateThemeOptionStyles();

  // Theme toggle click handler (bind once)
  if (themeToggleBtn) {
    if (themeToggleBtn.dataset.bound !== 'true') {
      themeToggleBtn.addEventListener('click', handleThemeToggle);
      themeToggleBtn.dataset.bound = 'true';
    }
  }

  // Theme preference radio button handlers
  themePreferenceRadios.forEach(radio => {
    radio.addEventListener('change', function() {
      const selectedTheme = this.value;
      currentTheme = selectedTheme;
      applyTheme(selectedTheme);
      localStorage.setItem('theme', selectedTheme);
      updateThemeOptionStyles();
    });
  });

  function handleThemeToggle(e) {
    if (e) {
      e.preventDefault();
      e.stopPropagation();
    }

    if (currentTheme === 'light') {
      currentTheme = 'dark';
    } else if (currentTheme === 'dark') {
      currentTheme = 'light';
    } else {
      currentTheme = 'light';
    }

    applyTheme(currentTheme);
    setRadioButton(currentTheme);
    localStorage.setItem('theme', currentTheme);
    updateThemeOptionStyles();
    return false;
  }

  // Function to apply theme
  function applyTheme(theme) {
    if (theme === 'dark') {
      document.documentElement.classList.add('dark');
    } else if (theme === 'light') {
      document.documentElement.classList.remove('dark');
    } else {
      // Auto
      if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
        document.documentElement.classList.add('dark');
      } else {
        document.documentElement.classList.remove('dark');
      }
    }
  }

  function setRadioButton(theme) {
    themePreferenceRadios.forEach(radio => {
      radio.checked = (radio.value === theme);
    });
  }

  function updateThemeOptionStyles() {
    const optionLabels = document.querySelectorAll('label.theme-option');
    optionLabels.forEach(label => {
      const input = label.querySelector('input[type="radio"]');
      const checkIcon = label.querySelector('svg.h-5.w-5');
      if (!input) return;

      label.classList.remove('ring-2','ring-blue-500','border-blue-500');
      if (checkIcon) checkIcon.classList.add('hidden');

      if (input.checked) {
        label.classList.add('ring-2','ring-blue-500','border-blue-500');
        if (checkIcon) checkIcon.classList.remove('hidden');
      }
    });
  }

  // Listen for system theme changes when in auto mode
  if (window.matchMedia) {
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function() {
      const saved = localStorage.getItem('theme') || 'auto';
      if (saved === 'auto') {
        applyTheme('auto');
        setRadioButton('auto');
        updateThemeOptionStyles();
      }
    });
  }
}

// Initialize theme toggle on turbo:load
document.addEventListener('turbo:load', initializeThemeToggle);

document.addEventListener('DOMContentLoaded', initializeThemeToggle);

if (document.readyState !== 'loading') {
  initializeThemeToggle();
}
