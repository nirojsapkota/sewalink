import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { currentUserId: Number }
  static targets = ["message"]

  connect() {
    this.scrollToBottom()
    this.processMessages()
    
    // Watch for new messages added via Turbo Streams
    this.observer = new MutationObserver(() => {
      this.processMessages()
      this.scrollToBottom()
    })
    
    this.observer.observe(this.element, { childList: true })
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }

  processMessages() {
    this.messageTargets.forEach((message) => {
      this.styleMessage(message)
    })
  }

  styleMessage(message) {
    const senderId = parseInt(message.dataset.messageSenderId)
    const container = message.querySelector(".message-bubble-content")
    if (!container) return

    if (senderId === this.currentUserIdValue) {
      message.classList.add("justify-end")
      message.classList.remove("justify-start")
      
      container.classList.add("bg-blue-600", "text-white", "rounded-br-none")
      container.classList.remove("bg-gray-200", "text-gray-900", "rounded-bl-none")
    } else {
      message.classList.add("justify-start")
      message.classList.remove("justify-end")
      
      container.classList.add("bg-gray-200", "text-gray-900", "rounded-bl-none")
      container.classList.remove("bg-blue-600", "text-white", "rounded-br-none")
    }
  }
}
