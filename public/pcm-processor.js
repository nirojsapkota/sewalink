class PCMProcessor extends AudioWorkletProcessor {
  constructor() {
    super();
    this.buffer = [];
    this.bufferSize = 1600; // ~100ms of audio at 16kHz
  }

  process(inputs, outputs, parameters) {
    const input = inputs[0];
    if (input && input.length > 0) {
      const channelData = input[0];
      
      for (let i = 0; i < channelData.length; i++) {
        const s = Math.max(-1, Math.min(1, channelData[i]));
        this.buffer.push(s < 0 ? s * 0x8000 : s * 0x7FFF);
      }

      if (this.buffer.length >= this.bufferSize) {
        const int16Data = new Int16Array(this.buffer);
        this.port.postMessage(int16Data.buffer, [int16Data.buffer]);
        this.buffer = [];
      }
    }
    return true;
  }
}

registerProcessor('pcm-processor', PCMProcessor);
