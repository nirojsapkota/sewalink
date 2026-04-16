# Phase 06: Task Status & Real-time Updates - Context

**Gathered:** 2026-04-15
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase focuses on refining the task lifecycle management by introducing more granular statuses (including draft/open toggles and payment-related states) and implementing real-time UI synchronization via Hotwire Turbo Streams.

</domain>

<decisions>
## Implementation Decisions

### Status Workflow & Transitions
- **D-01: Granular Statuses:** Extend the `Task` status enum to include `pending_payment`, `payment_completed`, and `dispute`.
- **D-02: Draft/Open Toggle:** Posters can move tasks from `open` back to `draft` and vice versa.
- **D-03: Automatic Transitions:** 
    - When a Tasker is assigned (or accepts), the task moves to `in_progress`.
    - When a Poster releases payment, the task moves to `payment_completed`.
- **D-04: Completion Control:** Only the Poster can mark a task as `completed`. Taskers have a "Request Payment" action instead.
- **D-05: Payment/Task Status Separation:** Use `task_status` for the lifecycle and rely on `PaymentTransaction` (from Phase 03) to track financial history.

### Payments & Disputes
- **D-06: Request Payment Action:** Tasker triggers a "Request Payment" action which notifies the Poster.
- **D-07: Poster Actions:** Upon payment request, the Poster sees "Release Payment" and "I have an issue" buttons.
- **D-08: Dispute Trigger:** Either party can raise a `dispute` if correspondence (via existing task chat) fails. 
- **D-09: Status Locking:** Once a task moves to `completed`, it transitions to `pending_payment` until funds are released.

### Real-time Synchronization (Hotwire)
- **D-10: Turbo Stream Events:** Broadcast updates for new bids, status changes, and task assignments.
- **D-11: Targeted Broadcasts:** 
    - Posters receive updates for tasks they own.
    - Taskers receive updates for tasks they have bid on.
- **D-12: UI Feedback:** Implement toast notifications for background updates and inline badge updates for status changes.

### UI/UX & Safety
- **D-13: Poster Dashboard Filters:** Implement a top horizontal tab bar to filter tasks (e.g., All | Drafts | Active | Completed).
- **D-14: Confirmation Dialogs:** Require user confirmation for all status transitions except `open` ↔ `draft`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Core Models
- `app/models/task.rb` — Current task status and lifecycle logic.
- `app/models/payment_transaction.rb` — Payment state machine and history.
- `app/models/bid.rb` — Bid assignment logic.

### Controllers & Services
- `app/controllers/tasks_controller.rb` — Task lifecycle management.
- `app/controllers/bids_controller.rb` — Tasker assignment logic.
- `app/services/payments/ledger_manager.rb` — Escrow and payment release logic.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `broadcasts_refreshes` in `Task` and `Bid` models already provides basic Hotwire sync.
- `AASM` in `PaymentTransaction` provides a template for state transitions if needed for tasks.

### Integration Points
- `TasksController#update` and `BidsController#accept` are the primary locations for status transition logic.
- `app/views/tasks/_task.html.erb` for status badge updates.

</code_context>

<specifics>
## Specific Ideas
- Use a "Toast" component (potentially a Stimulus controller) to show "New Bid Received" or "Status Updated to In Progress".
- The "My Tasks" screen for Posters should show all tasks in one list, but filtered by the active tab.

</specifics>

<deferred>
## Deferred Ideas
- AI-assisted dispute resolution (moved to Phase 5).
- Geofencing for "Done" status (moved to Phase 5).

</deferred>

---

*Phase: 06-add-ability-to-set-the-tasks-statuses-add-hotwire-turbo-stre*
*Context gathered: 2026-04-15*
