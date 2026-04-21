/**
 * audio-capture-processor.js
 * Captures raw audio and sends it to the main thread as Float32Array chunks.
 */
class AudioCaptureProcessor extends AudioWorkletProcessor {
  constructor() {
    super();
    this.bufferSize = 2048;
    this.buffer = new Float32Array(this.bufferSize);
    this.bufferIndex = 0;
  }

  process(inputs, outputs, parameters) {
    const input = inputs[0];
    if (!input || !input[0]) return true;

    const channelData = input[0];
    for (let i = 0; i < channelData.length; i++) {
      this.buffer[this.bufferIndex++] = channelData[i];

      if (this.bufferIndex >= this.bufferSize) {
        // Send a copy to the main thread
        this.port.postMessage({
          type: 'audio',
          data: new Float32Array(this.buffer)
        });
        this.bufferIndex = 0;
      }
    }
    return true;
  }
}

registerProcessor('audio-capture-processor', AudioCaptureProcessor);
