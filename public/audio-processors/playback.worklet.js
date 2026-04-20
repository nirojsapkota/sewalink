/**
 * playback.worklet.js
 * Ultra-fast chunk-based playback.
 */
class PlaybackProcessor extends AudioWorkletProcessor {
  constructor() {
    super();
    this.chunks = [];
    this.currentChunk = null;
    this.offset = 0;

    this.port.onmessage = (event) => {
      if (event.data === 'interrupt') {
        this.chunks = [];
        this.currentChunk = null;
        this.offset = 0;
      } else if (event.data instanceof Float32Array) {
        this.chunks.push(event.data);
      }
    };
  }

  process(inputs, outputs, parameters) {
    const output = outputs[0];
    const numChannels = output.length;
    const outputLength = output[0].length;

    for (let i = 0; i < outputLength; i++) {
      if (!this.currentChunk || this.offset >= this.currentChunk.length) {
        this.currentChunk = this.chunks.shift() || null;
        this.offset = 0;
      }

      const sample = this.currentChunk ? this.currentChunk[this.offset++] : 0;
      for (let channel = 0; channel < numChannels; channel++) {
        output[channel][i] = sample;
      }
    }
    return true;
  }
}

registerProcessor('playback-processor', PlaybackProcessor);
