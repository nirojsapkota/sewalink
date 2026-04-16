---
created: 2026-04-15T21:10:00Z
title: Implement two-way AI communication for task posting
area: ai
files:
  - app/services/task_draft_generator_service.rb
  - app/javascript/controllers/voice_recorder_controller.js
  - app/controllers/api/voice_tasks_controller.rb
---

## Problem

The current "Magic Box" voice-to-task functionality is a one-shot process: record voice → transcribe/extract → auto-fill form. The user wants a conversational, two-way interaction (similar to ChatGPT) where they can refine task details through voice feedback before final extraction.

## Solution

1. Evolve `TaskDraftGeneratorService` or create a new service that supports multi-turn conversations with the LLM.
2. Update the frontend `voice_recorder_controller.js` to handle ongoing voice sessions, displaying AI questions or responses and capturing subsequent user input.
3. Potentially use WebSockets (ActionCable) or streaming responses for a more fluid interaction.
