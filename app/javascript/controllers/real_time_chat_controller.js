import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["status", "response"]

  connect() {
    this.consumer = createConsumer()
    this.channel = this.consumer.subscriptions.create("AI::ChatChannel", {
      received: this._onMessage.bind(this),
      connected: () => {
        console.log("Connected to AI Chat Channel")
        if (this.hasStatusTarget) this.statusTarget.textContent = "Connected"
      },
      disconnected: () => {
        console.log("Disconnected from AI Chat Channel")
        if (this.hasStatusTarget) this.statusTarget.textContent = "Disconnected"
      }
    })
    
    this.audioContext = null
    this.processor = null
    this.stream = null
  }

  disconnect() {
    this.stopRecording()
    if (this.channel) {
      this.channel.unsubscribe()
    }
  }

  async startRecording() {
    try {
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)({ sampleRate: 16000 })
      await this.audioContext.audioWorklet.addModule('/pcm-processor.js')
      
      this.stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      const source = this.audioContext.createMediaStreamSource(this.stream)
      this.processor = new AudioWorkletNode(this.audioContext, 'pcm-processor')
      
      this.processor.port.onmessage = (event) => {
        const buffer = event.data
        const base64 = this._arrayBufferToBase64(buffer)
        this.channel.perform('send_audio', { audio: base64 })
      }
      
      source.connect(this.processor)
      this.processor.connect(this.audioContext.destination)
      
      if (this.hasStatusTarget) this.statusTarget.textContent = "Listening..."
    } catch (err) {
      console.error("Error starting recording:", err)
      if (this.hasStatusTarget) this.statusTarget.textContent = "Error: " + err.message
    }
  }

  stopRecording() {
    if (this.stream) {
      this.stream.getTracks().forEach(track => track.stop())
      this.stream = null
    }
    if (this.audioContext) {
      this.audioContext.close()
      this.audioContext = null
    }
    if (this.hasStatusTarget) this.statusTarget.textContent = "Stopped"
  }

  _onMessage(data) {
    console.log("[Gemini] Message:", data)
    
    // Simple response handling for now
    if (data.server_content && data.server_content.model_turn) {
      const parts = data.server_content.model_turn.parts || []
      parts.forEach(part => {
        if (part.text && this.hasResponseTarget) {
          const div = document.createElement("div")
          div.textContent = "AI: " + part.text
          this.responseTarget.appendChild(div)
        }
      })
    }

    if (data.tool_call) {
      console.log("[Gemini] Tool Call:", data.tool_call)
      // Future: Handle tool calls (e.g., create_task_draft)
    }
  }

  _arrayBufferToBase64(buffer) {
    let binary = ''
    const bytes = new Uint8Array(buffer)
    const len = bytes.byteLength
    for (let i = 0; i < len; i++) {
      binary += String.fromCharCode(bytes[i])
    }
    return window.btoa(binary)
  }
}
