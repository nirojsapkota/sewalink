---
created: 2026-04-15T21:15:00Z
title: Implement voice-interactive home screen for global task management
area: ui
files:
  - app/views/home/index.html.erb
  - app/javascript/controllers/voice_assistant_controller.js
---

## Problem

The goal for the next milestone is to provide users with a "Magic Home Screen" where they can perform most core tasks (search, post tasks, manage bids) primarily through voice interaction.

## Solution

1. Design and implement a voice assistant UI layer on the home screen.
2. Develop a `VoiceAssistantController` to route natural language commands (via LLM) to specific application actions (e.g., "Find me plumbers nearby" → redirects to filtered task search).
3. Ensure accessibility and localized language support (Nepali/English) for voice commands.
