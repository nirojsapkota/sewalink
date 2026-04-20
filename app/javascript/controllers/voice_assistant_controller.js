import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

export default class extends Controller {
  static targets = ["trigger", "status", "modal"];

  connect() {
    console.log("VoiceAssistantController is connected");
    this.isRecording = false;
    this.mediaRecorder = null;
    this.audioChunks = [];
  }

  async toggleRecording(event) {
    event.preventDefault();
    
    // Check if user is logged in via a meta tag or data attribute
    const isLoggedIn = document.body.dataset.userSignedIn === "true";

    if (!isLoggedIn) {
      this.updateStatus("Please sign in first");
      setTimeout(() => {
        Turbo.visit("/users/sign_up");
      }, 1000);
      return;
    }

    // Authenticated users go to the new real-time Gemini Live chat
    this.updateStatus("Opening Voice Assistant...");
    setTimeout(() => {
      Turbo.visit("/live_chat");
    }, 500);
  }

  async startRecording() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      this.mediaRecorder = new MediaRecorder(stream);
      this.audioChunks = [];

      this.mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) this.audioChunks.push(event.data);
      };

      this.mediaRecorder.onstop = async () => {
        const audioBlob = new Blob(this.audioChunks, { type: 'audio/webm' });
        await this.processCommand(audioBlob);
        stream.getTracks().forEach(track => track.stop());
      };

      this.mediaRecorder.start();
      this.isRecording = true;
      this.updateStatus("Listening...");
      this.triggerTarget.classList.add("recording");
    } catch (err) {
      console.error("Microphone error:", err);
      alert("Please enable microphone access.");
    }
  }

  stopRecording() {
    if (this.mediaRecorder && this.isRecording) {
      this.mediaRecorder.stop();
      this.isRecording = false;
      this.updateStatus("Thinking...");
      this.triggerTarget.classList.remove("recording");
    }
  }

  async processCommand(blob) {
    const formData = new FormData();
    formData.append("audio", blob, "command.webm");
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

    try {
      const response = await fetch("/api/assistant", {
        method: "POST",
        headers: { "X-CSRF-Token": csrfToken },
        body: formData
      });

      if (!response.ok) throw new Error("Assistant error");

      const data = await response.json();

      if (data.action === "redirect" && data.url) {
        this.updateStatus(data.message);
        setTimeout(() => {
          Turbo.visit(data.url);
        }, 1000);
      } else {
        this.showToast(data.message);
        this.updateStatus("Tap to speak...");
      }
    } catch (error) {
      console.error("Error:", error);
      this.updateStatus("Try again...");
    }
  }

  updateStatus(message) {
    if (this.hasStatusTarget) this.statusTarget.textContent = message;
  }

  showToast(message) {
    alert(message);
  }

  openModal(event) {
    event.preventDefault();
    if (this.hasModalTarget) this.modalTarget.classList.remove("hidden");
  }

  closeModal(event) {
    if (event) event.preventDefault();
    if (this.hasModalTarget) this.modalTarget.classList.add("hidden");
  }
}
