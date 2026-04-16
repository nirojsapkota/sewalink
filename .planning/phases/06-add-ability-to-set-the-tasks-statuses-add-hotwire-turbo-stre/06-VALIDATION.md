# Phase 06: Task Status & Real-time Updates - Validation

## Goal
Implement a granular task lifecycle and real-time UI synchronization to improve marketplace responsiveness.

## Observable Truths
- [ ] Poster can see tasks in various statuses: draft, open, in_progress, completed, etc.
- [ ] Poster can toggle tasks between 'draft' and 'open'.
- [ ] Tasker can 'request payment' once a task is in progress.
- [ ] Poster can 'release payment' once payment is requested, which completes the task.
- [ ] Poster dashboard shows a tabbed interface to filter tasks by status.
- [ ] New bids trigger a toast notification for the poster in real-time.
- [ ] Task status changes update the UI (badges/buttons) without a page refresh.
- [ ] Critical transitions (e.g., release payment, raise dispute) require user confirmation.

## Required Artifacts
- **Model Logic:** `app/models/task.rb` (updated statuses, transitions).
- **Controller Actions:** `app/controllers/tasks_controller.rb` (request/release payment, toggle draft).
- **Real-time Sync:** `app/models/bid.rb`, `app/models/task.rb` (Turbo Stream broadcasts).
- **Notification UI:** `app/views/notifications/_toast.html.erb`, `app/javascript/controllers/toast_controller.js`.
- **Poster Dashboard:** `app/controllers/posters/dashboards_controller.rb`, `app/views/posters/dashboards/_task_list.html.erb`.
- **System Testing:** `spec/system/task_status_updates_spec.rb`.

## Wiring & Connections
- [ ] `Task` model broadcasts `status` changes to the poster and tasker's notification streams.
- [ ] `Bid` model broadcasts `new_bid` toasts to the poster's notification stream.
- [ ] Poster dashboard links use `data-turbo-frame="tasks_list"` to update the list dynamically.
- [ ] Status transition buttons use `data-turbo-confirm` or a custom Stimulus controller for safety.

## Key Links (High Breakage Risk)
- **Bid -> Poster Notification:** If the stream name doesn't match the `turbo_stream_from` in the layout, notifications won't appear.
- **Status Update -> Dashboard UI:** If the DOM ID in `_task.html.erb` doesn't match the `target` in the broadcast, the badge won't update.
- **Escrow Release Integration:** `release_payment` must correctly trigger the `LedgerManager` to finalize the transaction.
