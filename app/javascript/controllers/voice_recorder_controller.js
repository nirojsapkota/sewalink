import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "title", "description", "budget", "categoryId", "trigger", "aiQuestion", "aiQuestionContainer"]

  connect() {
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
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      alert("Your browser does not support audio recording.")
      return
    }

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      this.mediaRecorder = new MediaRecorder(stream)
      this.audioChunks = []
      
      this.mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          this.audioChunks.push(event.data)
        }
      }

      this.mediaRecorder.onstop = () => {
        const audioBlob = new Blob(this.audioChunks, { type: 'audio/webm' })
        this.uploadAudio(audioBlob)
        
        // Stop all tracks
        stream.getTracks().forEach(track => track.stop())
      }

      this.mediaRecorder.start()
      this.isRecording = true
      this.updateStatus("Recording... Click again to stop.")
      this.triggerTarget.classList.add("recording")
    } catch (err) {
      console.error("Error accessing microphone:", err)
      alert("Could not access microphone. Please check permissions.")
    }
  }

  stopRecording() {
    if (this.mediaRecorder && this.isRecording) {
      this.mediaRecorder.stop()
      this.isRecording = false
      this.updateStatus("Processing... Please wait.")
      this.triggerTarget.classList.remove("recording")
    }
  }

  async uploadAudio(blob) {
    const formData = new FormData()
    formData.append("audio", blob, "recording.webm")

    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    try {
      const response = await fetch("/api/voice_tasks", {
        method: "POST",
        headers: {
          "X-CSRF-Token": csrfToken
        },
        body: formData
      })

      if (!response.ok) {
        throw new Error(`Server returned ${response.status}`)
      }

      const data = await response.json()
      
      this.fillForm(data)
      
      if (data.next_question) {
        this.displayAIQuestion(data.next_question)
        this.updateStatus("I need a few more details. Click to respond!")
      } else {
        this.hideAIQuestion()
        this.updateStatus("Task details successfully generated!")
      }
    } catch (error) {
      console.error("Error uploading audio:", error)
      this.updateStatus("Error processing audio. Please try again.")
    }
  }

  fillForm(data) {
    if (this.hasTitleTarget && data.title) {
      this.titleTarget.value = data.title
    }
    if (this.hasDescriptionTarget && data.description) {
      this.descriptionTarget.value = data.description
    }
    if (this.hasBudgetTarget && data.budget) {
      this.budgetTarget.value = data.budget
    }
    if (this.hasCategoryIdTarget && data.category_id) {
      this.categoryIdTarget.value = data.category_id
    }
  }

  displayAIQuestion(question) {
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

  async resetConversation(event) {
    if (event) event.preventDefault()
    
    this.hideAIQuestion()
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content
    
    try {
      await fetch("/api/voice_tasks/reset", {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": csrfToken
        }
      })
    } catch (error) {
      console.error("Error resetting conversation:", error)
    }
  }

  updateStatus(message) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
    }
  }
}
