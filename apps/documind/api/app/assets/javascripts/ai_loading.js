// AI Loading States and UI Blocking
document.addEventListener('DOMContentLoaded', function() {
  // Create loading overlay
  function createLoadingOverlay() {
    const overlay = document.createElement('div');
    overlay.id = 'ai-loading-overlay';
    overlay.className = 'fixed inset-0 bg-gray-900 bg-opacity-50 flex items-center justify-center z-50';
    overlay.innerHTML = `
      <div class="bg-white rounded-lg p-8 max-w-sm w-full mx-4 text-center">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
        <h3 class="text-lg font-medium text-gray-900 mb-2">AI Analysis in Progress</h3>
        <p class="text-sm text-gray-600">This may take up to 2 minutes. Please don't close this page.</p>
        <div class="mt-4">
          <div class="bg-gray-200 rounded-full h-2">
            <div class="bg-blue-600 h-2 rounded-full animate-pulse" style="width: 60%"></div>
          </div>
        </div>
      </div>
    `;
    document.body.appendChild(overlay);
  }

  // Remove loading overlay
  function removeLoadingOverlay() {
    const overlay = document.getElementById('ai-loading-overlay');
    if (overlay) {
      overlay.remove();
    }
  }

  // Show loading state for AI buttons
  function showAILoading(button, actionName) {
    console.log('showAILoading called for:', actionName);
    
    // Store original content before modifying
    const originalContent = button.innerHTML;
    button.dataset.originalContent = originalContent;

    // Update clicked button with loading state immediately
    button.innerHTML = `
      <svg class="animate-spin -ml-1 mr-3 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      Processing...
    `;

    // Delay the UI blocking slightly to allow form submission
    setTimeout(() => {
      // Disable all AI buttons after form submission starts
      const aiButtons = document.querySelectorAll('.ai-action-btn');
      aiButtons.forEach(btn => {
        btn.disabled = true;
        btn.classList.add('opacity-50', 'cursor-not-allowed');
      });

      // Create and show overlay
      createLoadingOverlay();
    }, 100); // Small delay to allow form submission

    // Set a timeout to ensure we don't block forever (fallback)
    setTimeout(() => {
      removeLoadingOverlay();
      restoreAIButtons();
    }, 150000); // 2.5 minutes fallback timeout
  }

  // Restore AI buttons to normal state
  function restoreAIButtons() {
    const aiButtons = document.querySelectorAll('.ai-action-btn');
    aiButtons.forEach(btn => {
      btn.disabled = false;
      btn.classList.remove('opacity-50', 'cursor-not-allowed');
      
      if (btn.dataset.originalContent) {
        btn.innerHTML = btn.dataset.originalContent;
        delete btn.dataset.originalContent;
      }
    });
  }

  // Attach event listeners to AI action buttons
  const aiActionButtons = document.querySelectorAll('.ai-action-btn');
  console.log(`Found ${aiActionButtons.length} AI action buttons`);
  
  aiActionButtons.forEach(button => {
    button.addEventListener('click', function(e) {
      console.log('AI button clicked:', this);
      
      // Show loading immediately when button is clicked
      const actionName = this.textContent.trim();
      console.log('Action name:', actionName);
      showAILoading(this, actionName);
      
      // For button_to forms, let the form submit naturally
      // The form will submit after this event handler completes
    });
  });

  // Handle question modal submit
  const questionForm = document.querySelector('#question-modal form');
  if (questionForm) {
    questionForm.addEventListener('submit', function(e) {
      const submitBtn = this.querySelector('input[type="submit"]');
      if (submitBtn) {
        showAILoading(submitBtn, 'Ask Question');
      }
      // Close modal
      document.getElementById('question-modal').classList.add('hidden');
    });
  }

  // Handle page unload/navigation away during loading
  window.addEventListener('beforeunload', function(e) {
    const overlay = document.getElementById('ai-loading-overlay');
    if (overlay) {
      e.preventDefault();
      e.returnValue = 'AI analysis is in progress. Are you sure you want to leave?';
      return e.returnValue;
    }
  });

  // Auto-remove loading on page load (in case of redirects)
  window.addEventListener('load', function() {
    removeLoadingOverlay();
    restoreAIButtons();
  });

  // Remove loading overlay if user navigates back
  window.addEventListener('pageshow', function(event) {
    if (event.persisted) {
      removeLoadingOverlay();
      restoreAIButtons();
    }
  });
});