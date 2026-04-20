import { Controller } from "@hotwired/stimulus";
import { createConsumer } from "@rails/actioncable";

export default class extends Controller {
  static targets = ["status", "statusLabel", "response", "trigger"];

  connect() {
    console.log("RealTimeChatController: Natural Voice Chat enabled");
    this.isRecording = false;
    this.consumer = createConsumer();
    this.channel = this.consumer.subscriptions.create("AiChatChannel", {
      received: this._onMessage.bind(this),
      connected: () => { console.log("Connected to AI Channel") },
      disconnected: () => { this._updateStatus("Disconnected", false) }
    });
    
    this.audioContext = null;
    this.playbackContext = null;
    this.nextPlayTime = 0;
  }

  disconnect() {
    this.stopRecording();
    if (this.channel) this.channel.unsubscribe();
  }

  async toggleChat(event) {
    if (event) event.preventDefault();
    if (this.isRecording) {
      this.stopChat();
    } else {
      await this.startChat();
    }
  }

  async startChat() {
    console.log("Starting Two-Way Voice Chat...");
    this.isRecording = true;
    this.triggerTarget.textContent = "Stop Chat";
    this.triggerTarget.classList.remove("bg-[#7C3AED]");
    this.triggerTarget.classList.add("bg-red-500", "animate-pulse");

    try {
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)({ sampleRate: 16000 });
      await this.audioContext.resume();
      
      this.playbackContext = new (window.AudioContext || window.webkitAudioContext)({ sampleRate: 24000 });
      await this.playbackContext.resume();
      this.nextPlayTime = this.playbackContext.currentTime;

      await this.audioContext.audioWorklet.addModule(new URL('/pcm-processor.js', window.location.origin).href);
      
      this.stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const source = this.audioContext.createMediaStreamSource(this.stream);
      this.processor = new AudioWorkletNode(this.audioContext, 'pcm-processor');
      
      this.processor.port.onmessage = (event) => {
        if (this.channel) {
          const buffer = event.data;
          const base64 = this._arrayBufferToBase64(buffer);
          this.channel.perform('send_audio', { audio: base64 });
        }
      };

      source.connect(this.processor);
      this.processor.connect(this.audioContext.destination);
      this._updateStatus("Live Chat Active", true);
    } catch (err) {
      console.error("Mic Error:", err);
      this.stopChat();
      this._updateStatus("Error: " + err.message, false);
    }
  }

  stopChat() {
    console.log("Stopping Chat...");
    this.isRecording = false;
    
    if (this.stream) {
      this.stream.getTracks().forEach(track => track.stop());
      this.stream = null;
    }
    if (this.audioContext) {
      this.audioContext.close();
      this.audioContext = null;
    }
    if (this.playbackContext) {
      this.playbackContext.close();
      this.playbackContext = null;
    }

    this.triggerTarget.textContent = "Tap to Talk";
    this.triggerTarget.classList.remove("bg-red-500", "animate-pulse");
    this.triggerTarget.classList.add("bg-[#7C3AED]");
    this._updateStatus("Chat Stopped", false);
  }

  stopRecording() {
    this.stopChat();
  }

  _onMessage(data) {
    console.log("RECEIVED FROM RAILS:", data);
    if (data.serverContent && data.serverContent.modelTurn) {
      const parts = data.serverContent.modelTurn.parts || [];
      parts.forEach(part => {
        if (part.inlineData && part.inlineData.data) {
          this._playAudioChunk(part.inlineData.data);
        }
        if (part.text && this.hasResponseTarget) {
          this._appendResponse(part.text);
        }
      });
    }
  }

  _playAudioChunk(base64Data) {
    if (!this.playbackContext) return;
    try {
      const binaryString = window.atob(base64Data);
      const len = binaryString.length;
      const bytes = new Uint8Array(len);
      for (let i = 0; i < len; i++) bytes[i] = binaryString.charCodeAt(i);
      const float32 = new Float32Array(new Int16Array(bytes.buffer).length);
      const pcm16 = new Int16Array(bytes.buffer);
      for (let i = 0; i < pcm16.length; i++) float32[i] = pcm16[i] / 32768.0;

      const audioBuffer = this.playbackContext.createBuffer(1, float32.length, 24000);
      audioBuffer.getChannelData(0).set(float32);
      const source = this.playbackContext.createBufferSource();
      source.buffer = audioBuffer;
      source.connect(this.playbackContext.destination);
      const startTime = Math.max(this.nextPlayTime, this.playbackContext.currentTime);
      source.start(startTime);
      this.nextPlayTime = startTime + audioBuffer.duration;
    } catch (e) { console.error("Playback Error", e) }
  }

  _appendResponse(text) {
    const div = document.createElement("div");
    div.className = "p-3 bg-indigo-50 rounded-xl mb-2 text-indigo-900 border border-indigo-100";
    div.textContent = "AI: " + text;
    this.responseTarget.appendChild(div);
    this.responseTarget.scrollTop = this.responseTarget.scrollHeight;
  }

  _updateStatus(label, active) {
    if (this.hasStatusLabelTarget) this.statusLabelTarget.textContent = label;
    if (this.hasStatusTarget) {
      active ? this.statusTarget.classList.remove('hidden') : this.statusTarget.classList.add('hidden');
    }
  }

  _arrayBufferToBase64(buffer) {
    let binary = '';
    const bytes = new Uint8Array(buffer);
    for (let i = 0; i < bytes.byteLength; i++) binary += String.fromCharCode(bytes[i]);
    return window.btoa(binary);
  }
}
