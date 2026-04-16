---
phase: 02-task-marketplace
plan: 02
subsystem: Task Management
tags: [tasks, active-storage, geocoding]
requirements: [TASK-01, TASK-03]
tech-stack: [Rails, Active Storage, Geocoder, Stimulus, Pundit]
key-files: [app/models/task.rb, app/controllers/tasks_controller.rb, app/views/tasks/_form.html.erb]
duration: 15m
completed-date: 2026-04-13
---

# Phase 02 Plan 02: Task Creation & Poster Dashboard Summary

Implemented the core Task model and the posting flow for Posters, including photo attachments and automatic geocoding.

## Key Decisions

- **Active Storage**: Used for handling task photos with `has_many_attached :photos`.
- **Geocoding**: Integrated `Geocoder` to automatically fetch coordinates from the `location` address string.
- **Pundit**: Applied `TaskPolicy` to restrict creation to Posters and ensure only owners can edit/delete their tasks.
- **Stimulus**: Added `image-preview-controller` to provide real-time feedback when uploading task photos.

## Requirements Covered

- **TASK-01**: Task Creation - Posters can publish tasks with description, budget, and location.
- **TASK-03**: Photo Attachments - Posters can attach photos to provide visual context for tasks.

## Self-Check: PASSED

- [x] Task model with validations and geocoding.
- [x] Functional Task Posting form with image previews.
- [x] Poster-specific "My Tasks" dashboard.
- [x] Authorization rules enforced via Pundit.

## Deviations from Plan

None - plan executed exactly as written.
