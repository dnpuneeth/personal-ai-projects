// Profile picture upload preview functionality
document.addEventListener('DOMContentLoaded', function() {
  const fileInput = document.getElementById('user_profile_picture');
  const profilePictureContainer = document.querySelector('.profile-picture-container');

  if (fileInput) {
    fileInput.addEventListener('change', function(e) {
      const file = e.target.files[0];
      if (file) {
        // Validate file type
        if (!file.type.match('image.*')) {
          alert('Please select a valid image file.');
          fileInput.value = '';
          return;
        }

        // Validate file size (5MB)
        if (file.size > 5 * 1024 * 1024) {
          alert('File size must be less than 5MB.');
          fileInput.value = '';
          return;
        }

        // Show preview
        const reader = new FileReader();
        reader.onload = function(e) {
          // Update the profile picture display
          const profilePicture = document.querySelector('.profile-picture-display img');
          if (profilePicture) {
            profilePicture.src = e.target.result;
          }
        };
        reader.readAsDataURL(file);
      }
    });
  }

  // Drag and drop functionality
  const dropZone = document.querySelector('.profile-picture-drop-zone');
  if (dropZone) {
    ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
      dropZone.addEventListener(eventName, preventDefaults, false);
    });

    function preventDefaults(e) {
      e.preventDefault();
      e.stopPropagation();
    }

    ['dragenter', 'dragover'].forEach(eventName => {
      dropZone.addEventListener(eventName, highlight, false);
    });

    ['dragleave', 'drop'].forEach(eventName => {
      dropZone.addEventListener(eventName, unhighlight, false);
    });

    function highlight(e) {
      dropZone.classList.add('border-blue-500', 'bg-blue-50', 'dark:bg-blue-900/20');
    }

    function unhighlight(e) {
      dropZone.classList.remove('border-blue-500', 'bg-blue-50', 'dark:bg-blue-900/20');
    }

    dropZone.addEventListener('drop', handleDrop, false);

    function handleDrop(e) {
      const dt = e.dataTransfer;
      const files = dt.files;

      if (files.length > 0) {
        fileInput.files = files;
        fileInput.dispatchEvent(new Event('change'));
      }
    }
  }
});

// Profile picture modal functionality
function openProfilePictureModal(imageSrc, userName) {
  const modal = document.getElementById('profile-picture-modal');
  const modalImage = document.getElementById('modal-image');
  const modalTitle = document.getElementById('modal-title');

  if (modal && modalImage && modalTitle) {
    modalImage.src = imageSrc;
    modalImage.alt = `${userName}'s profile picture`;
    modalTitle.textContent = `${userName}'s Profile Picture`;
    modal.classList.remove('hidden');

    // Close modal when clicking outside
    modal.addEventListener('click', function(e) {
      if (e.target === modal) {
        closeProfilePictureModal();
      }
    });

    // Close modal with Escape key
    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape') {
        closeProfilePictureModal();
      }
    });
  }
}

function closeProfilePictureModal() {
  const modal = document.getElementById('profile-picture-modal');
  if (modal) {
    modal.classList.add('hidden');
  }
}

// Remove profile picture confirmation with better UX
function confirmRemoveProfilePicture() {
  // Create a custom confirmation dialog
  const dialog = document.createElement('div');
  dialog.className = 'fixed inset-0 bg-black bg-opacity-75 z-50 flex items-center justify-center p-4';
  dialog.innerHTML = `
    <div class="bg-white dark:bg-gray-800 rounded-lg max-w-md w-full p-6">
      <div class="flex items-center mb-4">
        <div class="flex-shrink-0">
          <svg class="w-6 h-6 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"></path>
          </svg>
        </div>
        <div class="ml-3">
          <h3 class="text-lg font-medium text-gray-900 dark:text-white">Remove Profile Picture</h3>
        </div>
      </div>
      <div class="mb-6">
        <p class="text-sm text-gray-600 dark:text-gray-400">
          Are you sure you want to remove your profile picture? This action cannot be undone.
        </p>
      </div>
      <div class="flex justify-end space-x-3">
        <button type="button"
                onclick="this.closest('.fixed').remove()"
                class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 dark:focus:ring-offset-gray-800 transition-colors duration-200">
          Cancel
        </button>
        <button type="button"
                onclick="removeProfilePicture()"
                class="px-4 py-2 text-sm font-medium text-white bg-red-600 hover:bg-red-700 border border-transparent rounded-md focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 transition-colors duration-200">
          Remove Picture
        </button>
      </div>
    </div>
  `;

  document.body.appendChild(dialog);

  // Close dialog when clicking outside
  dialog.addEventListener('click', function(e) {
    if (e.target === dialog) {
      dialog.remove();
    }
  });

  // Close dialog with Escape key
  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
      dialog.remove();
    }
  });
}

function removeProfilePicture() {
  // Remove the dialog
  const dialog = document.querySelector('.fixed');
  if (dialog) {
    dialog.remove();
  }

  // Submit the remove form
  document.getElementById('remove-picture-form').submit();
}
