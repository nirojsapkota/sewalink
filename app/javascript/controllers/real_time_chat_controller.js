import { Controller } from "@hotwired/stimulus";
import { createConsumer } from "@rails/actioncable";

export default class extends Controller {
  static targets = ["status", "statusLabel", "response", "trigger"];

  connect() {
    this.isRecording = false;
    this.consumer = createConsumer();
    this.channel = this.consumer.subscriptions.create("AiChatChannel", {
      received: this._onMessage.bind(this),
      connected: () => { console.log("Connected to AI Channel"); }
    });

    this.audioContext = null;
    this.playbackContext = null;
    this.nextPlayTime = 0;
    this.silenceTimer = null;
  }

  disconnect() {
    this.stopChat();
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
    this.isRecording = true;
    this.triggerTarget.textContent = "Stop Chat";
    this.triggerTarget.className = "bg-red-500 hover:bg-red-600 text-white px-10 py-4 rounded-full font-bold text-xl transition-all shadow-xl shadow-red-500/30 active:scale-95 animate-pulse";

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
        if (!this.isRecording || !this.channel) return;
        const buffer = event.data;
        const volume = this._calculateVolume(buffer);

        // Log volume for debugging

        // Ultra-low threshold to ensure we pick up everything
        if (volume > 0.002) {
          this._resetSilenceTimer();
          this._updateStatus("Listening...", true);
          const base64 = this._arrayBufferToBase64(buffer);
          this.channel.perform('send_audio', { audio: base64 });
        } else {
          console.log("Ignored Mic Volume:", volume.toFixed(5));
        }

      };

      source.connect(this.processor);
      this.processor.connect(this.audioContext.destination);
    } catch (err) {
      this.stopChat();
    }
  }

  _calculateVolume(buffer) {
    const int16 = new Int16Array(buffer);
    let sum = 0;
    for (let i = 0; i < int16.length; i++) sum += Math.abs(int16[i] / 32768.0);
    return sum / int16.length;
  }

  _resetSilenceTimer() {
    if (this.silenceTimer) clearTimeout(this.silenceTimer);
    this.silenceTimer = setTimeout(() => {
      if (this.isRecording) {
        this.channel.perform('send_turn_complete');
        this._updateStatus("Thinking...", true);
        this.triggerTarget.className = "bg-yellow-500 text-white px-10 py-4 rounded-full font-bold text-xl transition-all shadow-xl shadow-yellow-500/30";
      }
    }, 1500);
  }

  stopChat() {
    this.isRecording = false;
    if (this.stream) this.stream.getTracks().forEach(track => track.stop());
    if (this.audioContext) this.audioContext.close();
    if (this.playbackContext) this.playbackContext.close();

    this.triggerTarget.textContent = "Tap to Talk";
    this.triggerTarget.className = "bg-[#7C3AED] hover:bg-[#6D28D9] text-white px-10 py-4 rounded-full font-bold text-xl transition-all shadow-xl shadow-[#7C3AED]/30 active:scale-95";
    this._updateStatus("Chat Inactive", false);
  }

  _onMessage(data) {
    console.log("RECEIVED DATA:", data);

    const serverContent = data.server_content || data.serverContent;
    if (serverContent) {
      const modelTurn = serverContent.model_turn || serverContent.modelTurn;
      if (modelTurn) {
        this.triggerTarget.className = "bg-red-500 hover:bg-red-600 text-white px-10 py-4 rounded-full font-bold text-xl transition-all shadow-xl shadow-red-500/30 animate-pulse";

        const parts = modelTurn.parts || [];
        parts.forEach(part => {
          const audioData = part.inline_data || part.inlineData;
          if (audioData && audioData.data) {
            this._playAudioChunk(audioData.data);
          }
          if (part.text) {
            this._appendResponse(part.text);
          }
        });
      }
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
    } catch (e) { console.error("Playback Error", e); }
  }

  _appendResponse(text) {
    if (!this.hasResponseTarget) return;
    const div = document.createElement("div");
    div.className = "p-3 bg-indigo-50 rounded-xl mb-2 text-indigo-900 border border-indigo-100 shadow-sm";
    div.textContent = "AI: " + text;
    this.responseTarget.appendChild(div);
    this.responseTarget.scrollTop = this.responseTarget.scrollHeight;
  }

  _updateStatus(label, active) {
    if (this.hasStatusLabelTarget) this.statusLabelTarget.textContent = label;
  }

  _arrayBufferToBase64(buffer) {
    let binary = '';
    const bytes = new Uint8Array(buffer);
    for (let i = 0; i < bytes.byteLength; i++) binary += String.fromCharCode(bytes[i]);
    return window.btoa(binary);
  }
}
