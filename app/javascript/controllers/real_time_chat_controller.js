import { Controller } from "@hotwired/stimulus";

// Response type constants
const MultimodalLiveResponseType = {
  TEXT: "TEXT",
  AUDIO: "AUDIO",
  SETUP_COMPLETE: "SETUP COMPLETE",
  INTERRUPTED: "INTERRUPTED",
  TURN_COMPLETE: "TURN COMPLETE",
  TOOL_CALL: "TOOL_CALL",
  ERROR: "ERROR",
  INPUT_TRANSCRIPTION: "INPUT_TRANSCRIPTION",
  OUTPUT_TRANSCRIPTION: "OUTPUT_TRANSCRIPTION",
};

/**
 * Audio Streamer - Captures and streams microphone audio
 */
class AudioStreamer {
  constructor(geminiClient) {
    this.client = geminiClient;
    this.audioContext = null;
    this.audioWorklet = null;
    this.mediaStream = null;
    this.isStreaming = false;
    this.isMuted = false;
    this.sampleRate = 16000;
  }

  async start() {
    try {
      console.log("Starting AudioStreamer...");
      this.mediaStream = await navigator.mediaDevices.getUserMedia({
        audio: {
          sampleRate: this.sampleRate,
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
        },
      });

      this.audioContext = new (window.AudioContext || window.webkitAudioContext)({
        sampleRate: this.sampleRate,
      });
      console.log("Capture Context Rate:", this.audioContext.sampleRate);

      await this.audioContext.audioWorklet.addModule("/audio-processors/capture.worklet.js");

      this.audioWorklet = new AudioWorkletNode(this.audioContext, "audio-capture-processor");

      this.audioWorklet.port.onmessage = (event) => {
        if (!this.isStreaming || this.isMuted) return;
        if (event.data.type === "audio") {
          const pcmData = this.convertToPCM16(event.data.data);
          const base64Audio = this.arrayBufferToBase64(pcmData);
          if (this.client && this.client.connected) {
            this.client.sendAudioMessage(base64Audio);
          }
        }
      };

      const source = this.audioContext.createMediaStreamSource(this.mediaStream);
      source.connect(this.audioWorklet);
      this.isStreaming = true;
      return true;
    } catch (error) {
      console.error("Failed to start audio streaming:", error);
      throw error;
    }
  }

  mute(muted) {
    this.isMuted = muted;
    console.log(muted ? "🎤 Mic Soft-Muted" : "🎤 Mic Unmuted");
  }

  stop() {
    this.isStreaming = false;
    if (this.audioWorklet) { this.audioWorklet.disconnect(); this.audioWorklet = null; }
    if (this.audioContext) { this.audioContext.close(); this.audioContext = null; }
    if (this.mediaStream) { this.mediaStream.getTracks().forEach((t) => t.stop()); this.mediaStream = null; }
  }

  convertToPCM16(float32Array) {
    const int16Array = new Int16Array(float32Array.length);
    for (let i = 0; i < float32Array.length; i++) {
      const sample = Math.max(-1, Math.min(1, float32Array[i]));
      int16Array[i] = sample * 0x7fff;
    }
    return int16Array.buffer;
  }

  arrayBufferToBase64(buffer) {
    const bytes = new Uint8Array(buffer);
    let binary = "";
    for (let i = 0; i < bytes.byteLength; i++) binary += String.fromCharCode(bytes[i]);
    return window.btoa(binary);
  }
}

/**
 * Audio Player - Plays audio responses from Gemini
 */
class AudioPlayer {
  constructor() {
    this.audioContext = null;
    this.workletNode = null;
    this.isInitialized = false;
    this.sampleRate = 24000;
  }

  async init() {
    if (this.isInitialized) return;
    try {
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)({
        sampleRate: this.sampleRate,
      });
      console.log("Playback Context Rate:", this.audioContext.sampleRate);
      await this.audioContext.audioWorklet.addModule("/audio-processors/playback.worklet.js");
      this.workletNode = new AudioWorkletNode(this.audioContext, "playback-processor");
      this.workletNode.connect(this.audioContext.destination);
      this.isInitialized = true;
    } catch (error) {
      console.error("Failed to initialize audio player:", error);
      throw error;
    }
  }

  async play(audioData) {
    if (!audioData) return;
    if (!this.isInitialized) await this.init();
    if (this.audioContext.state === "suspended") await this.audioContext.resume();

    try {
      let buffer;
      if (audioData instanceof ArrayBuffer) {
        buffer = audioData;
      } else if (typeof audioData === 'string') {
        const binaryString = atob(audioData);
        const len = binaryString.length;
        const bytes = new Uint8Array(len);
        for (let i = 0; i < len; i++) {
          bytes[i] = binaryString.charCodeAt(i);
        }
        buffer = bytes.buffer;
      } else {
        console.error("Unknown audio data type:", typeof audioData);
        return;
      }

      if (buffer.byteLength % 2 !== 0) {
        buffer = buffer.slice(0, buffer.byteLength - 1);
      }

      // Explicitly read as Little Endian Int16
      const view = new DataView(buffer);
      const numSamples = buffer.byteLength / 2;
      const float32 = new Float32Array(numSamples);

      for (let i = 0; i < numSamples; i++) {
        // Read Int16, Little Endian (true), and normalize to -1.0 to 1.0
        // Apply a small 0.9 gain reduction to prevent clipping distortion
        float32[i] = (view.getInt16(i * 2, true) / 32768) * 0.9;
      }

      this.workletNode.port.postMessage(float32, [float32.buffer]);
    } catch (e) {
      console.error("Playback Error:", e);
    }
  }

  interrupt() {
    if (this.workletNode) this.workletNode.port.postMessage("interrupt");
  }

  destroy() {
    if (this.audioContext) { this.audioContext.close(); this.audioContext = null; }
    this.isInitialized = false;
  }
}

/**
 * GeminiLiveAPI - Protocol wrapper
 */
class GeminiLiveAPI {
  constructor(tokenData, systemInstructions = "") {
    this.token = tokenData.token;
    this.apiKey = tokenData.api_key;
    this.tools = tokenData.tools;
    this.systemInstructions = systemInstructions;
    this.ws = null;
    this.connected = false;
    this.onMessage = null;
    this.onClose = null;
    this.onOpen = null;
  }

  connect() {
    let url;
    if (this.token) {
      // Use constrained endpoint for ephemeral tokens (v1alpha)
      url = `wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContentConstrained?access_token=${this.token}`;
      console.log("Connecting via Ephemeral Token (v1alpha)");
    } else {
      // Use standard endpoint for API key (v1beta)
      url = `wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=${this.apiKey}`;
      console.log("Connecting via API Key (v1beta)");
    }

    console.log("WebSocket URL:", url.split('?')[0] + "?[REDACTED]");
    this.ws = new WebSocket(url);
    this.ws.binaryType = "arraybuffer";

    this.ws.onopen = () => {
      this.connected = true;
      console.log("WebSocket Connected to Gemini. Sending setup...");
      this.sendInitialSetup();
      if (this.onOpen) this.onOpen();
    };
    this.ws.onmessage = async (e) => {
      let textData = e.data;

      if (e.data instanceof ArrayBuffer) {
        textData = new TextDecoder().decode(e.data);
      } else if (e.data instanceof Blob) {
        textData = await e.data.text();
      }

      try {
        const data = JSON.parse(textData);
        this._handleRawMessage(data);
      } catch (err) {
        console.error("Failed to parse Gemini message:", err, textData);
      }
    };
    this.ws.onclose = (e) => {
      this.connected = false;
      console.log(`Gemini WebSocket Closed: Code=${e.code}, Reason=${e.reason}, Clean=${e.wasClean}`);
      if (this.onClose) this.onClose(e);
    };
  }

  sendInitialSetup() {
    const setup = {
      setup: {
        model: "models/gemini-3.1-flash-live-preview",
        generationConfig: {
          responseModalities: ["AUDIO"],
          speechConfig: {
            voiceConfig: {
              prebuiltVoiceConfig: {
                voiceName: "Aoede"
              }
            }
          }
        },
        systemInstruction: {
          parts: [{ text: this.systemInstructions }]
        },
        tools: [{ functionDeclarations: this.tools }]
      }
    };
    console.log("Gemini Setup Message:", JSON.stringify(setup, null, 2));
    this.ws.send(JSON.stringify(setup));
  }

  sendAudioMessage(base64PCM) {
    this.ws.send(JSON.stringify({
      realtimeInput: {
        audio: {
          mimeType: "audio/pcm;rate=16000",
          data: base64PCM
        }
      }
    }));
  }

  sendToolResponse(functionResponses) {
    this.ws.send(JSON.stringify({
      toolResponse: { functionResponses }
    }));
  }

  _handleRawMessage(data) {
    if (data.setupComplete || data.setup_complete) {
      if (this.onMessage) this.onMessage({ type: MultimodalLiveResponseType.SETUP_COMPLETE });
      return;
    }

    if (data.toolCall || data.tool_call) {
      if (this.onMessage) this.onMessage({ type: MultimodalLiveResponseType.TOOL_CALL, data: data.toolCall || data.tool_call });
      return;
    }

    const serverContent = data.serverContent || data.server_content;
    if (serverContent) {
      if (serverContent.interrupted) {
        if (this.onMessage) this.onMessage({ type: MultimodalLiveResponseType.INTERRUPTED });
      }

      const modelTurn = serverContent.modelTurn || serverContent.model_turn;
      if (modelTurn && modelTurn.parts) {
        modelTurn.parts.forEach(part => {
          if (part.inlineData || part.inline_data) {
            const audioData = part.inlineData || part.inline_data;
            if (audioData.data) {
              console.log("Received Audio Chunk, size:", audioData.data.length);
              if (this.onMessage) this.onMessage({ type: MultimodalLiveResponseType.AUDIO, data: audioData.data });
            }
          }
          if (part.text) {
            if (this.onMessage) this.onMessage({ type: MultimodalLiveResponseType.TEXT, data: part.text });
          }
        });
      }

      if (serverContent.turnComplete || serverContent.turn_complete) {
        if (this.onMessage) this.onMessage({ type: MultimodalLiveResponseType.TURN_COMPLETE });
      }
    }
  }

  disconnect() {
    if (this.ws) this.ws.close();
    this.connected = false;
  }
}

/**
 * Stimulus Controller - Gluing everything together
 */
export default class extends Controller {
  static targets = ["status", "statusLabel", "response", "trigger"];
  static values = {
    userName: String,
    locale: String,
    tapToTalkLabel: String,
    stopChatLabel: String,
    authenticatingLabel: String,
    readyLabel: String,
    speakingLabel: String,
    listeningLabel: String,
    thinkingLabel: String,
    connectionLostLabel: String
  };

  connect() {
    this.isRecording = false;
    this.client = null;
    this.streamer = null;
    this.player = new AudioPlayer();
  }

  disconnect() {
    this.stopChat();
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
    this._updateUI(true);

    try {
      this._updateStatus(this.authenticatingLabelValue, true);
      const response = await fetch("/gemini/tokens", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        }
      });
      const tokenData = await response.json();

      const userName = this.hasUserNameValue ? this.userNameValue : "there";
      const currentLocale = this.hasLocaleValue ? this.localeValue : "en";
      const instructions = `
      Start communicating in the '${currentLocale}' language.
      Greet the user with name ${userName}!
      Introduce yourself as SewaLink, a helpful assistant for managing service tasks on the SewaLink platform. Always be friendly and engaging in your responses.
      
      Capabilities:
      1. Help create tasks. Call 'create_task_draft' IMMEDIATELY every time the user provides or updates any information (title, description, budget, or location).
      2. Publish tasks. Call 'publish_task' ONLY when the user explicitly asks to 'publish', 'post', or 'finish' their task.
      3. Query status/history. Call 'query_tasks' when the user asks about their pending tasks, status of a job, or a summary of their activity.
      
      Always confirm to the user when you have performed an action or found the information they requested.`;

      this.client = new GeminiLiveAPI(tokenData, instructions);
      this.client.onMessage = this._handleMessage.bind(this);
      this.client.onOpen = () => console.log("Gemini API Connected");
      this.client.onClose = () => { 
        console.log("Gemini API Closed"); 
        if (this.isRecording) {
          this._updateStatus(this.connectionLostLabelValue, false);
          this.stopChat(); 
        }
      };

      this.client.connect();
      this.streamer = new AudioStreamer(this.client);
      await this.streamer.start();
      await this.player.init();

    } catch (err) {
      console.error("Failed to start chat:", err);
      this.stopChat();
    }
  }

  stopChat() {
    this.isRecording = false;
    if (this.streamer) {
      this.streamer.mute(false);
      this.streamer.stop();
    }
    if (this.client) this.client.disconnect();
    this._updateUI(false);
    this._updateStatus("Chat Inactive", false);
  }

  async _handleMessage(message) {
    switch (message.type) {
      case MultimodalLiveResponseType.SETUP_COMPLETE:
        this._updateStatus(this.readyLabelValue, true);
        break;
      case MultimodalLiveResponseType.AUDIO:
        this._updateStatus(this.speakingLabelValue, true);
        if (this.streamer) this.streamer.mute(true); // Prevent AI from hearing itself
        await this.player.play(message.data);
        break;
      case MultimodalLiveResponseType.INTERRUPTED:
        console.log("AI Interrupted");
        this.player.interrupt();
        if (this.streamer) this.streamer.mute(false);
        break;
      case MultimodalLiveResponseType.TURN_COMPLETE:
        this._updateStatus(this.listeningLabelValue, true);
        if (this.streamer) this.streamer.mute(false);
        break;
      case MultimodalLiveResponseType.TOOL_CALL:
        await this._handleToolCall(message.data);
        break;
      case MultimodalLiveResponseType.TEXT:
        console.log("AI Text:", message.data);
        break;
    }
  }

  async _handleToolCall(toolCall) {
    const calls = toolCall.functionCalls || toolCall.function_calls;
    if (!calls) return;

    const functionResponses = [];
    for (const call of calls) {
      console.log("Executing Tool:", call.name, call.args);
      const response = await fetch("/gemini/tools/execute", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ name: call.name, args: call.args, call_id: call.id })
      });
      const result = await response.json();
      functionResponses.push({
        id: call.id,
        name: call.name,
        response: result
      });
    }
    this.client.sendToolResponse(functionResponses);
  }

  _updateUI(active) {
    if (active) {
      this.triggerTarget.textContent = this.stopChatLabelValue;
      this.triggerTarget.className = "bg-red-500 hover:bg-red-600 text-white px-10 py-4 rounded-full font-bold text-xl transition-all shadow-xl shadow-red-500/30 active:scale-95 animate-pulse";
      this.statusTarget.classList.remove("hidden");
    } else {
      this.triggerTarget.textContent = this.tapToTalkLabelValue;
      this.triggerTarget.className = "bg-[#7C3AED] hover:bg-[#6D28D9] text-white px-10 py-4 rounded-full font-bold text-xl transition-all shadow-xl shadow-[#7C3AED]/30 active:scale-95";
      this.statusTarget.classList.add("hidden");
    }
  }

  _updateStatus(label, active) {
    if (this.hasStatusLabelTarget) this.statusLabelTarget.textContent = label;
  }
}
