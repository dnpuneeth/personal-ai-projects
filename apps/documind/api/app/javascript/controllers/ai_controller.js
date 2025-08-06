import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["question", "answer", "loading", "form"]
  static values = { 
    documentId: Number,
    summarizeUrl: String,
    answerUrl: String,
    redlinesUrl: String
  }

  connect() {
    console.log("AI Controller connected")
  }

  async summarize() {
    await this.performAiAction('summarize', this.summarizeUrlValue)
  }

  async answerQuestion() {
    const question = this.questionTarget.value.trim()
    if (!question) {
      this.showError("Please enter a question")
      return
    }

    const url = `${this.answerUrlValue}?question=${encodeURIComponent(question)}`
    await this.performAiAction('answer', url)
  }

  async proposeRedlines() {
    await this.performAiAction('redlines', this.redlinesUrlValue)
  }

  async performAiAction(action, url) {
    try {
      this.showLoading(action)
      
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })

      if (response.ok) {
        const result = await response.json()
        this.handleSuccess(action, result)
      } else {
        const error = await response.json()
        this.handleError(error)
      }
    } catch (error) {
      this.handleError({ error: `${action} failed` })
    }
  }

  showLoading(action) {
    const actionText = {
      'summarize': 'Analyzing document and identifying risks...',
      'answer': 'Searching for answer...',
      'redlines': 'Analyzing document for improvements...'
    }

    this.loadingTarget.innerHTML = `
      <div class="flex items-center justify-center p-6">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mr-3"></div>
        <p class="text-gray-600">${actionText[action]}</p>
      </div>
    `
    this.loadingTarget.classList.remove('hidden')
  }

  handleSuccess(action, result) {
    this.loadingTarget.classList.add('hidden')
    
    if (action === 'summarize') {
      this.displaySummary(result)
    } else if (action === 'answer') {
      this.displayAnswer(result)
    } else if (action === 'redlines') {
      this.displayRedlines(result)
    }
  }

  displaySummary(result) {
    this.answerTarget.innerHTML = `
      <div class="bg-white rounded-lg shadow p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Document Summary</h3>
        <div class="prose max-w-none">
          <p class="text-gray-700 mb-6">${result.summary}</p>
          
          <h4 class="text-md font-semibold text-gray-900 mb-3">Top Risks</h4>
          <div class="space-y-2 mb-6">
            ${result.top_risks.map(risk => `
              <div class="flex items-start p-3 bg-red-50 rounded-lg">
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800 mr-3">
                  ${risk.severity}
                </span>
                <div>
                  <p class="font-medium text-red-900">${risk.risk}</p>
                  <p class="text-sm text-red-700">${risk.description}</p>
                </div>
              </div>
            `).join('')}
          </div>
          
          <h4 class="text-md font-semibold text-gray-900 mb-3">Citations</h4>
          <div class="space-y-2">
            ${result.citations.map(citation => `
              <div class="p-3 bg-gray-50 rounded-lg">
                <p class="text-sm text-gray-600 mb-1">Chunk ${citation.chunk_id}</p>
                <p class="text-sm text-gray-800 italic">"${citation.quote}"</p>
              </div>
            `).join('')}
          </div>
        </div>
      </div>
    `
  }

  displayAnswer(result) {
    this.answerTarget.innerHTML = `
      <div class="bg-white rounded-lg shadow p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Answer</h3>
        <div class="prose max-w-none">
          <p class="text-gray-700 mb-4">${result.answer}</p>
          
          <div class="flex items-center mb-4">
            <span class="text-sm text-gray-500">Confidence:</span>
            <div class="ml-2 flex-1 bg-gray-200 rounded-full h-2">
              <div class="bg-blue-600 h-2 rounded-full" style="width: ${result.confidence * 100}%"></div>
            </div>
            <span class="ml-2 text-sm text-gray-500">${Math.round(result.confidence * 100)}%</span>
          </div>
          
          <h4 class="text-md font-semibold text-gray-900 mb-3">Sources</h4>
          <div class="space-y-2">
            ${result.citations.map(citation => `
              <div class="p-3 bg-gray-50 rounded-lg">
                <p class="text-sm text-gray-600 mb-1">Chunk ${citation.chunk_id}</p>
                <p class="text-sm text-gray-800 italic">"${citation.quote}"</p>
              </div>
            `).join('')}
          </div>
        </div>
      </div>
    `
  }

  displayRedlines(result) {
    this.answerTarget.innerHTML = `
      <div class="bg-white rounded-lg shadow p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Suggested Redlines</h3>
        <div class="prose max-w-none">
          <div class="space-y-4">
            ${result.edits.map((edit, index) => `
              <div class="border border-gray-200 rounded-lg p-4">
                <div class="flex items-center justify-between mb-3">
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                    ${edit.type}
                  </span>
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                    ${edit.severity}
                  </span>
                </div>
                <p class="text-sm text-gray-600 mb-2">${edit.location}</p>
                <p class="text-sm text-gray-800 mb-2"><strong>Reason:</strong> ${edit.reason}</p>
                ${edit.current_text ? `<p class="text-sm text-red-600 mb-2"><strong>Current:</strong> ${edit.current_text}</p>` : ''}
                ${edit.suggested_text ? `<p class="text-sm text-green-600"><strong>Suggested:</strong> ${edit.suggested_text}</p>` : ''}
              </div>
            `).join('')}
          </div>
        </div>
      </div>
    `
  }

  handleError(error) {
    this.loadingTarget.classList.add('hidden')
    this.answerTarget.innerHTML = `
      <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
        <p class="font-medium">Error</p>
        <p class="text-sm">${error.error || 'Something went wrong. Please try again.'}</p>
      </div>
    `
  }

  showError(message) {
    this.answerTarget.innerHTML = `
      <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
        <p class="font-medium">Error</p>
        <p class="text-sm">${message}</p>
      </div>
    `
  }
} 