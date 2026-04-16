---
status: testing
phase: 04-ai-voice-assistant
source: [04-01-SUMMARY.md, 04-02-SUMMARY.md]
started: 2026-04-15T20:38:00Z
updated: 2026-04-15T20:38:00Z
---

## Current Test
<!-- OVERWRITE each test - shows where we are -->

number: 1
name: Cold Start Smoke Test
expected: |
  Kill any running server/service. Clear ephemeral state (temp DBs, caches, lock files). Start the application from scratch. Server boots without errors, any seed/migration completes, and a primary query (health check, homepage load, or basic API call) returns live data.
awaiting: user response

## Tests

### 1. Cold Start Smoke Test
expected: |
  Kill any running server/service. Clear ephemeral state (temp DBs, caches, lock files). Start the application from scratch. Server boots without errors, any seed/migration completes, and a primary query (health check, homepage load, or basic API call) returns live data.
result: [pending]

### 2. Magic Box Presence
expected: |
  Navigate to the "New Task" page (/tasks/new). You should see a "Magic Box" UI section above the form with a microphone button and instructions (e.g., "Describe your task with your voice").
result: [pending]

### 3. Voice Recording Lifecycle
expected: |
  Click the microphone button. The UI should indicate it is recording (e.g., status changes to "Recording...", button glows/changes color). Click the button again to stop. The status should change to "Processing...".
result: [pending]

### 4. Auto-fill Task Form from Voice
expected: |
  After stopping the recording (e.g., say "Fix my leaky faucet, budget 1000 rupees, plumbing category"), the Magic Box should process the audio and automatically fill the Title, Description, Budget, and Category fields in the task form below.
result: [pending]

### 5. Audio Size Validation
expected: |
  If you record for a very long time (exceeding 10MB) or simulate a large file upload to the API, the system should return a clear error message (e.g., "Audio file is too large") and not attempt to process it via OpenAI.
result: [pending]

### 6. Development OTP Display
expected: |
  In development or test environment, when you enter a phone number and click login, you should be redirected to the OTP verification page. This page should display the "Dev OTP" code in a yellow box, allowing you to easily test the login flow.
result: [pending]

## Summary

total: 6
passed: 0
issues: 0
pending: 6
skipped: 0
blocked: 0

## Gaps

[none yet]
