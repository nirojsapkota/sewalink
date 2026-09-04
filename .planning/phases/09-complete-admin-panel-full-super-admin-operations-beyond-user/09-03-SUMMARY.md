---
phase: 09-complete-admin-panel-full-super-admin-operations-beyond-user
plan: 03
subsystem: admin
tags: [rails, aasm, double-entry, escrow, admin-panel, audit-log]

# Dependency graph
requires:
  - phase: 09-01
    provides: "Admin::BaseController#log_admin_action! and AdminActivityLog model"
provides:
  - "Admin::TasksController#edit/update/force_cancel actions"
  - "Admin task edit override form (title/description/budget/category/location)"
  - "Force-cancel control on task show page with escrow refund safety"
affects: [09-complete-admin-panel-full-super-admin-operations-beyond-user]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Admin overrides use dedicated strong params excluding status/user_id — status transitions only via dedicated action + AASM event, never raw mass-assignment"
    - "AASM::InvalidTransition rescued in controller to convert an invalid admin action into a friendly redirect alert instead of a 500"

key-files:
  created:
    - app/views/admin/tasks/edit.html.slim
    - spec/requests/admin/tasks_controller_spec.rb
  modified:
    - app/controllers/admin/tasks_controller.rb
    - app/views/admin/tasks/show.html.slim

key-decisions:
  - "Escrow refund (Payments::LedgerManager.refund_poster) is invoked only when task is esewa, paid, and not already cancelled/completed, immediately before the AASM cancel! event fires — preventing double-refunds on repeated/invalid force-cancel attempts."
  - "task_params strong params permit only title/description/budget/category_id/location — status and user_id are excluded so status changes must go through the dedicated force_cancel action, which is fully audit-logged."

patterns-established:
  - "AdminActivityLog entries on both update and force_cancel actions capture the acting admin, target task, and either the field changes or the previous status for full auditability."

requirements-completed: [ADMIN-06]

# Metrics
duration: 15min
completed: 2026-09-04
---

# Phase 09 Plan 03: Admin Task Override & Force-Cancel Summary

**Admins can now edit task fields directly and force-cancel tasks from any non-terminal status, with automatic escrow refunds for paid eSewa tasks and full audit logging via AdminActivityLog.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-09-04T03:06:00Z (approx)
- **Completed:** 2026-09-04T03:21:49Z
- **Tasks:** 2/2 completed
- **Files modified:** 4 (2 created, 2 modified)

## Accomplishments
- Added `edit`/`update`/`force_cancel` actions to `Admin::TasksController` with strong params that exclude `:status`/`:user_id`, ensuring status changes only happen through the dedicated, audit-logged `force_cancel` action.
- `force_cancel` refunds escrowed funds via `Payments::LedgerManager.refund_poster` before cancelling paid eSewa tasks, and gracefully handles invalid transitions (e.g. from `completed`) by rescuing `AASM::InvalidTransition` and redirecting with a friendly alert.
- Both `update` and `force_cancel` call `log_admin_action!`, recording an `AdminActivityLog` entry for every override.
- Added an admin task edit form (title/description/budget/category/location) and an Edit + Force Cancel control pair on the task show page, with Force Cancel hidden for tasks already `cancelled` or `completed`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Tasks controller — edit/update/force_cancel** - `6533210` (feat)
2. **Task 2: Edit form and force-cancel control** - `4795b8d` (feat)

_Note: Implementation and spec were written together per the plan's prescriptive action block; all 4 required behaviors were verified passing in a single spec run rather than a strict separate RED commit._

## Files Created/Modified
- `app/controllers/admin/tasks_controller.rb` - Added `edit`, `update`, `force_cancel` actions, `set_task` before_action, and `task_params` strong params.
- `app/views/admin/tasks/edit.html.slim` - New admin override form for title/description/budget/category/location.
- `app/views/admin/tasks/show.html.slim` - Added Edit link and Force Cancel button (conditionally hidden for cancelled/completed tasks).
- `spec/requests/admin/tasks_controller_spec.rb` - New request spec covering update, force_cancel (open task), force_cancel with escrow refund (paid assigned esewa task), and force_cancel failure on a completed task.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Money comparison in own test needed `Money.from_amount`**
- **Found during:** Task 1 spec authoring
- **Issue:** `expect(task.budget).to eq(1500)` raised `ArgumentError: Money#== supports only zero numerics` because `Task#budget` is monetized via the `money-rails` gem.
- **Fix:** Changed assertion to `expect(task.budget).to eq(Money.from_amount(1500))`.
- **Files modified:** `spec/requests/admin/tasks_controller_spec.rb`
- **Commit:** `6533210`

### Environment Note (not a code deviation)

`bundle exec rspec spec/system/admin/task_monitoring_spec.rb` fails in this sandbox with a ChromeDriver crash (`Selenium::WebDriver::Error::WebDriverError`, no functioning Chrome browser binary installed under `/Applications/Google Chrome.app`). This failure is pre-existing and reproduces identically on `HEAD` without any of this plan's changes — confirmed by running the spec both before and after these commits. Because Capybara/Selenium system tests cannot run in this sandboxed environment, I substituted a manual request-spec-based verification (temporary, not committed) confirming the show page renders `Edit` and `Force Cancel` controls correctly with the expected `href`/`action` targets and `data-confirm` text. The rendered HTML was inspected directly and matches the plan's acceptance criteria (`edit_admin_task_path` link and `force_cancel_admin_task_path` button present, hidden logic sound).


## Self-Check: PASSED
All created/modified files found on disk; both task commits (6533210, 4795b8d) found in git history.
