---
phase: 09-complete-admin-panel-full-super-admin-operations-beyond-user
plan: 07
subsystem: payments
tags: [double-entry, ledger, disputes, admin, aasm]

# Dependency graph
requires:
  - phase: 09-01
    provides: "Task#reopen! AASM event and Admin::BaseController#log_admin_action!"
provides:
  - "Payments::LedgerManager.split_escrow(task, tasker_percentage) for partial dispute settlements"
  - "Admin::DisputesController#resolve handling of split and reopen decisions, alongside existing release/refund"
  - "Split Payment and Reopen Task resolution-control cards on the dispute show page"
affects: [payments, admin-disputes]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "DoubleEntry transfer definitions must be registered in config/initializers/double_entry.rb before any code path can use that transfer code — verified this at the config layer for :refund (escrow -> user_external), which was previously used by refund_poster but never registered."

key-files:
  created:
    - spec/requests/admin/disputes_controller_spec.rb
  modified:
    - app/services/payments/ledger_manager.rb
    - app/controllers/admin/disputes_controller.rb
    - config/initializers/double_entry.rb
    - app/views/admin/disputes/show.html.slim
    - spec/system/admin/dispute_resolution_spec.rb

key-decisions:
  - "Split resolution calls @task.release_payment! after moving funds (transitions dispute -> completed), matching the existing release/refund pattern of moving money first then transitioning task state."
  - "Reopen resolution explicitly rejects the accepted bid before calling task.reopen!, keeping task.tasker (derived from accepted bid) consistent with the new open status."

patterns-established:
  - "Admin::DisputesController#resolve dispatches to one private resolve_* method per decision, each independently audit-logging via log_admin_action! with a details hash describing the decision made."

requirements-completed: [ADMIN-11]

# Metrics
duration: 35min
completed: 2026-09-04
---

# Phase 09 Plan 07: Dispute Split & Reopen Resolutions Summary

**Added `Payments::LedgerManager.split_escrow` and an extended `Admin::DisputesController#resolve` so admins can settle disputes with a percentage-based split or reopen the task for new bids, both fully audit-logged alongside the existing release/refund options.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-09-04T13:19:00Z (approx)
- **Completed:** 2026-09-04T13:24:00Z (approx)
- **Tasks:** 2 completed
- **Files modified:** 5 (1 created, 4 modified)

## Accomplishments
- `Payments::LedgerManager.split_escrow(task, tasker_percentage)` moves the escrowed balance between the tasker's balance and the poster's external account by percentage, leaving escrow at 0.
- `Admin::DisputesController#resolve` now handles four decisions — `release`, `refund`, `split`, `reopen` — each validated (percentage range checked for split) and audit-logged via `log_admin_action!`.
- Dispute show page gained two new resolution-control cards: "Option 3: Split Payment" (percentage form) and "Option 4: Reopen Task" (single confirm button).
- Fixed a pre-existing gap in `config/initializers/double_entry.rb`: the `:refund` transfer code (escrow → user_external) was used by `refund_poster` but never registered as an allowed transfer, which would have raised `DoubleEntry::TransferNotAllowed` in any real (non-test) execution. Registered it so both `refund_poster` and the new `split_escrow` work correctly.

## Task Commits

Each task was committed atomically:

1. **Task 1: LedgerManager.split_escrow + resolve action for split/reopen** - `2a31e5d` (feat)
2. **Task 2: Split/Reopen resolution controls on dispute show page** - `50cf925` (feat)

_Note: Task 1 also fixed dispute-relevant tests and the double_entry transfer registration gap; see Deviations below._

## Files Created/Modified
- `app/services/payments/ledger_manager.rb` - Added `split_escrow(task, tasker_percentage)` class method.
- `app/controllers/admin/disputes_controller.rb` - Rewrote `#resolve` to dispatch to `resolve_release`/`resolve_refund`/`resolve_split`/`resolve_reopen`, each audit-logging via `log_admin_action!`.
- `config/initializers/double_entry.rb` - Registered the `:refund` transfer (escrow → user_external), previously missing.
- `spec/requests/admin/disputes_controller_spec.rb` - New: covers `split_escrow` ledger behavior directly, and request specs for `resolve` with `split` (valid + out-of-range percentage) and `reopen` decisions.
- `app/views/admin/disputes/show.html.slim` - Added "Option 3: Split Payment" form and "Option 4: Reopen Task" button to the Resolution Controls section.
- `spec/system/admin/dispute_resolution_spec.rb` - Fixed `create(:user, name: "...")` calls that no longer work since `User#name` became a derived read-only method (`first_name`/`last_name`); unrelated to this plan's core work but blocked verification.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Registered missing `:refund` DoubleEntry transfer**
- **Found during:** Task 1, while writing the `split_escrow` request spec (Test 1)
- **Issue:** `config/initializers/double_entry.rb` never registered an `escrow -> user_external` transfer with code `:refund`, even though `Payments::LedgerManager.refund_poster` (pre-existing, Phase 7) and the new `split_escrow` both use that exact transfer. Calling it raised `DoubleEntry::TransferNotAllowed`. Existing specs never caught this because `refund_poster` was always stubbed in system/request specs.
- **Fix:** Added `transfers.define(from: :escrow, to: :user_external, code: :refund)` to `config.define_transfers` in `config/initializers/double_entry.rb`.
- **Files modified:** `config/initializers/double_entry.rb`
- **Commit:** `2a31e5d`

**2. [Rule 3 - Blocking] Fixed `dispute_resolution_spec.rb` user factory calls**
- **Found during:** Task 2 verification (`bundle exec rspec spec/system/admin/dispute_resolution_spec.rb`)
- **Issue:** The spec called `create(:user, name: "John Poster")`, but `User#name` is now a derived read-only method (`[first_name, last_name].join(' ')`) added by a concurrent Phase 09 plan; `name=` no longer exists, raising `NoMethodError`.
- **Fix:** Changed the two affected `let` blocks to `create(:user, first_name: "John", last_name: "Poster")` / `create(:user, first_name: "Jane", last_name: "Tasker")`.
- **Files modified:** `spec/system/admin/dispute_resolution_spec.rb`
- **Commit:** `50cf925`

## Known Issues / Environment Limitations

- `spec/system/admin/dispute_resolution_spec.rb` could not be run to completion in this execution environment: the installed `chromedriver` (147.x) is incompatible with the installed Chrome browser (152.x), causing `Selenium::WebDriver::Error::SessionNotCreatedError` on every system spec in the suite (pre-existing environment issue, unrelated to this plan's code changes). Verified correctness by other means instead:
  - `bundle exec rspec spec/requests/admin/disputes_controller_spec.rb` — 4/4 passing, covering `split_escrow` ledger math and the `resolve` action's split/reopen decisions end-to-end (percentage validation, audit logging, state transitions, bid rejection).
  - Slim template parse check (`Slim::Template.new { File.read(...) }`) confirms `app/views/admin/disputes/show.html.slim` has valid syntax after the new Option 3/Option 4 blocks were added.
  - Recommend the orchestrator/CI environment (with a matched chromedriver/Chrome pair) re-run `spec/system/admin/dispute_resolution_spec.rb` to get full browser-level confirmation.

## Self-Check: PASSED

- FOUND: app/services/payments/ledger_manager.rb (split_escrow present)
- FOUND: app/controllers/admin/disputes_controller.rb (resolve_split/resolve_reopen present)
- FOUND: config/initializers/double_entry.rb (:refund transfer present)
- FOUND: spec/requests/admin/disputes_controller_spec.rb
- FOUND: app/views/admin/disputes/show.html.slim (Option 3/Option 4 present)
- FOUND: spec/system/admin/dispute_resolution_spec.rb (first_name/last_name fix present)
- FOUND commit 2a31e5d in git log
- FOUND commit 50cf925 in git log
