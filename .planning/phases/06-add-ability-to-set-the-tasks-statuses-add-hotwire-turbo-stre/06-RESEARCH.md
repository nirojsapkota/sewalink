# Phase 06: Task Status & Real-time Updates - Research

**Researched:** 2024-05-15
**Domain:** Rails Task Lifecycle & Hotwire Real-time Sync
**Confidence:** HIGH

## Summary

This research identifies the path to extending the `Task` lifecycle with granular statuses and implementing real-time updates. The project currently uses `broadcasts_refreshes` in models, which leverages Turbo 8's Page Refresh mechanism. We will supplement this with targeted `turbo_stream` broadcasts for granular UI updates (like toast notifications) and implement a tabbed dashboard for Posters using Turbo Frames.

**Primary recommendation:** Use `enum` in `Task` for lifecycle, `AASM` if transition logic becomes complex (already used in `PaymentTransaction`), and `Turbo::Streams` for real-time notifications.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01: Granular Statuses:** Extend the `Task` status enum to include `pending_payment`, `payment_completed`, and `dispute`.
- **D-02: Draft/Open Toggle:** Posters can move tasks from `open` back to `draft` and vice versa.
- **D-03: Automatic Transitions:** 
    - When a Tasker is assigned (or accepts), the task moves to `in_progress`.
    - When a Poster releases payment, the task moves to `payment_completed`.
- **D-04: Completion Control:** Only the Poster can mark a task as `completed`. Taskers have a "Request Payment" action instead.
- **D-05: Payment/Task Status Separation:** Use `task_status` for the lifecycle and rely on `PaymentTransaction` (from Phase 03) to track financial history.
- **D-06: Request Payment Action:** Tasker triggers a "Request Payment" action which notifies the Poster.
- **D-07: Poster Actions:** Upon payment request, the Poster sees "Release Payment" and "I have an issue" buttons.
- **D-08: Dispute Trigger:** Either party can raise a `dispute` if correspondence (via existing task chat) fails. 
- **D-09: Status Locking:** Once a task moves to `completed`, it transitions to `pending_payment` until funds are released.
- **D-10: Turbo Stream Events:** Broadcast updates for new bids, status changes, and task assignments.
- **D-11: Targeted Broadcasts:** 
    - Posters receive updates for tasks they own.
    - Taskers receive updates for tasks they have bid on.
- **D-12: UI Feedback:** Implement toast notifications for background updates and inline badge updates for status changes.
- **D-13: Poster Dashboard Filters:** Implement a top horizontal tab bar to filter tasks (e.g., All | Drafts | Active | Completed).
- **D-14: Confirmation Dialogs:** Require user confirmation for all status transitions except `open` ↔ `draft`.

### the agent's Discretion
- Implementation of the "Toast" component (Stimulus suggested).
- Selection of specific Turbo Stream broadcast methods (e.g., `broadcast_replace_to` vs `broadcast_prepend_to`).

### Deferred Ideas (OUT OF SCOPE)
- AI-assisted dispute resolution (moved to Phase 5).
- Geofencing for "Done" status (moved to Phase 5).
</user_constraints>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| turbo-rails | ~> 7.1 | WebSocket updates | Rails 7 default for real-time |
| stimulus-rails | ~> 1.2 | JS interactions | Rails 7 default for lightweight JS |
| double_entry | - | Accounting | Existing project standard for ledger |
| aasm | ~> 5.5 | State machine | Already in use for PaymentTransaction |

## Architecture Patterns

### Pattern 1: Targeted Turbo Stream Broadcasts
**What:** Instead of full page refreshes, use `broadcast_to` for specific users or resources.
**When to use:** For "New Bid" notifications or "Status Changed" toasts.
**Example:**
```ruby
# app/models/bid.rb
after_create_commit :broadcast_notification

def broadcast_notification
  broadcast_prepend_to [task.user, :notifications], 
    target: "notifications", 
    partial: "notifications/toast", 
    locals: { message: "New bid received for #{task.title}" }
end
```

### Pattern 2: Turbo Frame Dashboard Filtering
**What:** Wrap the task list in a `turbo_frame_tag` and target it from tab links.
**When to use:** Poster dashboard filtering.
**Example:**
```erb
<nav>
  <%= link_to "Active", tasks_path(filter: 'active'), data: { turbo_frame: "tasks_list" } %>
</nav>
<%= turbo_frame_tag "tasks_list" do %>
  <%= render @tasks %>
<% end %>
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| State Transitions | Custom logic in controllers | AASM or Enum validations | Prevents invalid states (e.g. Draft -> Completed) |
| Flash over WS | Custom JS | Turbo Stream partials | Native Rails integration |

## Common Pitfalls

### Pitfall 1: Race Conditions in Broadcasts
**What goes wrong:** Background job finishes before the user has subscribed to the channel.
**How to avoid:** Use `after_commit` hooks and ensure Turbo Stream channels are correctly scoped to user IDs.

### Pitfall 2: Over-broadcasting
**What goes wrong:** Broadcasting to all users when only one should see it.
**How to avoid:** Use specific stream names like `[user, :notifications]` instead of global names.

## Code Examples

### Notification Toast Partial
```erb
<%# app/views/notifications/_toast.html.erb %>
<div id="<%= dom_id(notification) %>" data-controller="toast" class="toast">
  <%= message %>
</div>
```

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Existing `broadcasts_refreshes` is sufficient for base UI | Summary | Might need manual stream for some parts |
| A2 | Redis is configured for ActionCable | Summary | Real-time won't work in production without it |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Redis | ActionCable / Hotwire | ✓ | - | - |
| Turbo | Real-time UI | ✓ | 7.x | - |

## Sources
- `app/models/task.rb`
- `app/models/payment_transaction.rb`
- `app/controllers/bids_controller.rb`
- `app/services/payments/ledger_manager.rb`
- Official Hotwire Documentation (hotwired.dev)
