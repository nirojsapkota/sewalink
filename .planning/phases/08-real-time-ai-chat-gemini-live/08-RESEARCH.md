# Phase 08: Real-time AI Chat (Gemini Live) - Research

**Researched:** 2025-03-24
**Domain:** Real-time Multimodal AI / WebSockets / Web Audio API
**Confidence:** MEDIUM (Interrupted)

## Summary

This phase focuses on transitioning the "Magic Box" from a file-based voice-to-task system to a true real-time, bidirectional streaming AI chat using the **Gemini Multimodal Live API**. The system will allow users to speak naturally, hear the AI respond in real-time, and see their task creation form update dynamically as they provide details.

**Primary recommendation:** Use a **Server Proxy Architecture** with Rails ActionCable and a Ruby WebSocket client (e.g., `faye-websocket`) to connect to Gemini. This keeps API keys secure and allows the backend to execute tools against the database directly.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `gemini-2.0-flash-exp` | v2.0 | Multimodal Live Model | Supports Bidi streaming & Tool use. |
| `faye-websocket` | ~0.11 | WS Client for Ruby | Reliable WS handling for server-to-AI link. |
| `ActionCable` | 7.1+ | Real-time Browser Link | Native Rails WebSocket support. |
| `Web Audio API` | Browser Std | Audio Processing | Required for raw PCM capture/playback. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|--------------|
| `AudioWorklet` | Browser Std | Low-latency Audio | Capturing mic data at 16kHz without UI lag. |
| `Turbo Streams` | 7.3+ | UI Synchronization | Pushing form updates to the DOM. |

## Architecture Patterns

### Proxy Architecture (Recommended)
1. **Browser** $\leftrightarrow$ **Rails (ActionCable)**: Streams audio chunks (Base64) and UI events.
2. **Rails** $\leftrightarrow$ **Gemini API (WebSocket)**: Forwards audio to Gemini and receives model responses.
3. **Tool Execution**: When Gemini calls a tool (e.g., `set_task_title`), Rails executes the logic and sends the result back to Gemini + updates the UI via Turbo Streams.

### Pattern: Real-time Tool Use (Function Calling)
**What:** Define a schema for tools like `update_draft_task(title, description, budget)`.
**When to use:** Every time the AI extracts a new piece of information from the conversation.
**Example:**
```json
// Setup Message Tools
{
  "function_declarations": [{
    "name": "update_task_form",
    "description": "Updates the task creation form fields on the fly",
    "parameters": {
      "type": "OBJECT",
      "properties": {
        "title": { "type": "string" },
        "budget": { "type": "number" }
      }
    }
  }]
}
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Audio Downsampling | Custom JS Resampler | `AudioContext` with `sampleRate` | Browser handles native resampling optimally. |
| WS Protocol | Custom Framing | `faye-websocket` | Handles handshake, heartbeats, and closures. |
| PCM Playback | `<audio>` tag | `AudioWorklet` / `AudioBuffer` | Raw PCM has no headers; tags won't play it. |

## Common Pitfalls

### Pitfall 1: Barge-in Lag
**What goes wrong:** User starts speaking while AI is talking, but AI continues.
**Why it happens:** Buffering in ActionCable or Gemini API.
**How to avoid:** Detect `interrupted: true` from Gemini and immediately clear the browser's audio buffer.

### Pitfall 2: Base64 Overhead
**What goes wrong:** ActionCable performance degrades with high-frequency audio chunks.
**How to avoid:** Keep chunks around 50ms-100ms. Consider `AnyCable` if scaling beyond single-user testing.

## Code Examples

### Browser PCM Capture (16kHz Mono)
```javascript
const audioContext = new AudioContext({ sampleRate: 16000 });
await audioContext.audioWorklet.addModule('pcm-processor.js');
const source = audioContext.createMediaStreamSource(stream);
const pcmNode = new AudioWorkletNode(audioContext, 'pcm-processor');
pcmNode.port.onmessage = (e) => {
  // Send ArrayBuffer (Int16) to ActionCable
  channel.send({ audio: btoa(String.fromCharCode(...new Uint8Array(e.data))) });
};
```

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Redis | ActionCable | ✓ | 7.2.1 | — |
| Gemini API Key | AI Connection | ✗ | — | Request from developer |

## Security Domain (SAFE-03)

### Applicable ASVS Categories
- **V5 Input Validation**: Critical for tool use arguments (e.g., validating budget is a positive integer).
- **V6 Cryptography**: API keys must be stored in `credentials.yml.enc` or ENV, never in JS.

## Sources
- [Google AI Docs: Multimodal Live API](https://ai.google.dev/gemini-api/docs/multimodal-live) - Primary Protocol.
- [Vertex AI: BidiGenerateContent](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/multimodal-live) - Endpoint details.
- [MDN: Web Audio API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API) - Audio processing.

## Metadata
**Confidence breakdown:**
- Gemini API: HIGH
- Audio Capture/Playback: MEDIUM (Needs POC for sync)
- ActionCable Scaling: LOW (Potential bottleneck)

**Research date:** 2025-03-24
