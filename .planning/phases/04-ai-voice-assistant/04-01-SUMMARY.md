---
phase: 04-ai-voice-assistant
plan: 01
subsystem: magic-box
tags: [openai, whisper, gpt-4o-mini, audio]
requires: []
provides: [task_draft_generator]
affects: [TaskDraftGeneratorService]
tech-stack:
  added: [ruby-openai gem]
  patterns: [Service Object, TDD]
key-files:
  created:
    - config/initializers/openai.rb
    - app/services/task_draft_generator_service.rb
    - spec/services/task_draft_generator_service_spec.rb
  modified:
    - Gemfile
    - Gemfile.lock
decisions:
  - "Used `gpt-4o-mini` with `json_object` format for structured parsing."
  - "Implemented strict file extension (`.mp3`, `.mp4`, `.wav`, etc.) and size (max 10MB) validation before sending to OpenAI."
metrics:
  duration: 10
  completed_at: "2026-04-14T12:24:58Z"
---

# Phase 04 Plan 01: Setup OpenAI Integration and Service Summary

Configured OpenAI client and implemented TaskDraftGeneratorService for extracting structured data from voice notes.

## Completed Tasks

1. **Task 1: Add ruby-openai gem and configure**
   - Added `ruby-openai` gem to Gemfile.
   - Initialized `OpenAI::Client` configuration with a safe fallback to `nil` when the token is missing.
2. **Task 2: Create TaskDraftGeneratorService**
   - Implemented `#call` on `TaskDraftGeneratorService` to transcribe an audio file using the whisper-1 model.
   - Extracted title, description, budget, and inferred category_id from the transcript using GPT-4o-mini.
   - Returned data structured as a success hash with parsed task details.

## Deviations from Plan

### Auto-added Missing Critical Functionality

**1. [Rule 2 - Security Mitigation] Added file size and type validation**
- **Found during:** Task 2
- **Issue:** Sending unvalidated file bytes directly to the OpenAI API introduces potential vulnerabilities such as DoS risks via overly large files or parsing errors on incompatible file formats, as identified in the threat model (T-04-01).
- **Fix:** Validated that the audio file size is strictly less than 10MB and the file extension belongs to a predefined allowed list (`.mp3`, `.mp4`, `.wav`, etc.) before making the API calls.
- **Files modified:** `app/services/task_draft_generator_service.rb`, `spec/services/task_draft_generator_service_spec.rb`
- **Commit:** 14a475b

## Self-Check: PASSED
- FOUND: config/initializers/openai.rb
- FOUND: app/services/task_draft_generator_service.rb
- FOUND: spec/services/task_draft_generator_service_spec.rb
- FOUND: 14a475b
- FOUND: 163e26a
- FOUND: b5d713d
- FOUND: 8fed979
