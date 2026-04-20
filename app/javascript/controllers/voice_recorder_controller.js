import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["status", "title", "description", "budget", "categoryId", "trigger", "aiQuestion", "aiQuestionContainer"]

  connect() {
    console.log("VoiceRecorderController is connected");
    this.isRecording = false
    this.mediaRecorder = null
    this.audioChunks = []
    
    // Reset conversation on page load and form submission
    this.resetConversation()
    
    const form = this.element.querySelector('form')
    if (form) {
      form.addEventListener('submit', () => this.resetConversation())
    }
  }

  async toggleRecording(event) {
    event.preventDefault()
    if (this.isRecording) {
      this.stopRecording()
    } else {
      await this.startRecording()
    }
  }

  async startRecording() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      this.mediaRecorder = new MediaRecorder(stream)
      this.audioChunks = []
      
      this.mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) this.audioChunks.push(event.data)
      }

      this.mediaRecorder.onstop = async () => {
        const audioBlob = new Blob(this.audioChunks, { type: 'audio/webm' })
        await this.processVoice(audioBlob)
        stream.getTracks().forEach(track => track.stop())
      }

      this.mediaRecorder.start()
      this.isRecording = true
      this.updateStatus("Listening...")
      this.triggerTarget.classList.add("recording")
    } catch (err) {
      console.error("Microphone error:", err)
      alert("Please enable microphone access.")
    }
  }

  stopRecording() {
    if (this.mediaRecorder && this.isRecording) {
      this.mediaRecorder.stop()
      this.isRecording = false
      this.updateStatus("Thinking...")
      this.triggerTarget.classList.remove("recording")
    }
  }

  async processVoice(blob) {
    const formData = new FormData()
    formData.append("audio", blob, "task.webm")
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    try {
      const response = await fetch("/api/voice_tasks", {
        method: "POST",
        headers: { "X-CSRF-Token": csrfToken },
        body: formData
      })

      if (!response.ok) throw new Error("Voice processing error")

      const data = await response.json()
      
      // Update form fields if present in response
      if (data.task) {
        if (data.task.title && this.hasTitleTarget) this.titleTarget.value = data.task.title
        if (data.task.description && this.hasDescriptionTarget) this.descriptionTarget.value = data.task.description
        if (data.task.budget && this.hasBudgetTarget) this.budgetTarget.value = data.task.budget
        if (data.task.category_id && this.hasCategoryIdTarget) this.categoryIdTarget.value = data.task.category_id
      }

      if (data.question) {
        this.updateAIQuestion(data.question)
      } else {
        this.hideAIQuestion()
      }

      this.updateStatus("Tap and speak to update...")
    } catch (error) {
      console.error("Error:", error)
      this.updateStatus("Try again...")
    }
  }

  updateAIQuestion(question) {
    if (this.hasAiQuestionTarget && this.hasAiQuestionContainerTarget) {
      this.aiQuestionTarget.textContent = question
      this.aiQuestionContainerTarget.classList.remove("hidden")
    }
  }

  hideAIQuestion() {
    if (this.hasAiQuestionContainerTarget) {
      this.aiQuestionContainerTarget.classList.add("hidden")
    }
  }

  async resetConversation() {
    try {
      await fetch("/api/voice_tasks/reset", {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        }
      })
    } catch (error) {
      console.error("Error resetting conversation:", error)
    }
  }

  updateStatus(message) {
    if (this.hasStatusTarget) this.statusTarget.textContent = message
  }
}
