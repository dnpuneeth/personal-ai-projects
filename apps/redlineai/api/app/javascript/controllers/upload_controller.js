import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "dragArea", "progress"]
  static values = { url: String }

  connect() {
    this.dragArea = this.dragAreaTarget
    this.setupDragAndDrop()
  }

  setupDragAndDrop() {
    this.dragArea.addEventListener('dragover', (e) => {
      e.preventDefault()
      this.dragArea.classList.add('border-blue-500', 'bg-blue-50')
    })

    this.dragArea.addEventListener('dragleave', (e) => {
      e.preventDefault()
      this.dragArea.classList.remove('border-blue-500', 'bg-blue-50')
    })

    this.dragArea.addEventListener('drop', (e) => {
      e.preventDefault()
      this.dragArea.classList.remove('border-blue-500', 'bg-blue-50')
      
      const files = e.dataTransfer.files
      if (files.length > 0) {
        this.inputTarget.files = files
        this.handleFileSelect()
      }
    })
  }

  handleFileSelect() {
    const file = this.inputTarget.files[0]
    if (file) {
      this.showPreview(file)
      this.uploadFile(file)
    }
  }

  showPreview(file) {
    if (file.type === 'application/pdf') {
      this.previewTarget.innerHTML = `
        <div class="flex items-center p-4 bg-gray-50 rounded-lg">
          <svg class="w-8 h-8 text-red-500 mr-3" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4z" clip-rule="evenodd" />
          </svg>
          <div>
            <p class="text-sm font-medium text-gray-900">${file.name}</p>
            <p class="text-sm text-gray-500">${(file.size / 1024 / 1024).toFixed(2)} MB</p>
          </div>
        </div>
      `
    }
  }

  async uploadFile(file) {
    const formData = new FormData()
    formData.append('file', file)

    try {
      this.showProgress()
      
      const response = await fetch(this.urlValue, {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })

      if (response.ok) {
        const result = await response.json()
        this.handleUploadSuccess(result)
      } else {
        const error = await response.json()
        this.handleUploadError(error)
      }
    } catch (error) {
      this.handleUploadError({ error: 'Upload failed' })
    }
  }

  showProgress() {
    this.progressTarget.innerHTML = `
      <div class="w-full bg-gray-200 rounded-full h-2.5">
        <div class="bg-blue-600 h-2.5 rounded-full animate-pulse" style="width: 45%"></div>
      </div>
      <p class="text-sm text-gray-600 mt-2">Processing document...</p>
    `
  }

  handleUploadSuccess(result) {
    this.progressTarget.innerHTML = `
      <div class="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded">
        <p class="font-medium">Document uploaded successfully!</p>
        <p class="text-sm">Document ID: ${result.document_id}</p>
      </div>
    `
    
    // Redirect to document page after a short delay
    setTimeout(() => {
      window.location.href = `/documents/${result.document_id}`
    }, 2000)
  }

  handleUploadError(error) {
    this.progressTarget.innerHTML = `
      <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
        <p class="font-medium">Upload failed</p>
        <p class="text-sm">${error.error || 'Please try again'}</p>
      </div>
    `
  }
} 