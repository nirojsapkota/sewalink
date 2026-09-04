---
phase: 09-complete-admin-panel-full-super-admin-operations-beyond-user
plan: 06
subsystem: payments
tags: [rails, double-entry, money, platform-settings, admin]

# Dependency graph
requires:
  - phase: 09-01
    provides: "PlatformSetting model, AdminActivityLog, admin settings route"
provides:
  - "Database-driven commission rate (PlatformSetting.commission_rate) replacing hardcoded constant"
  - "Admin::SettingsController#show/update for financial oversight (commission rate, platform revenue, total escrow) without a Rails console"
  - "Audit-logged commission rate changes with 0-1 range validation"
affects: [payments, admin-panel]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Financial config resolved via PlatformSetting.commission_rate at calculation time, not a class constant"]

key-files:
  created:
    - app/controllers/admin/settings_controller.rb
    - app/views/admin/settings/show.html.slim
    - spec/requests/admin/settings_controller_spec.rb
  modified:
    - app/services/payments/commission_calculator.rb
    - spec/services/payments/commission_calculator_spec.rb

key-decisions:
  - "Removed COMMISSION_PERCENTAGE constant entirely; PlatformSetting.commission_rate (default 0.10) is now the single source of truth"
  - "Total escrow held computed via Task.where(payment_type: :esewa, status: [...]).sum(:budget_cents) rather than per-task DoubleEntry balance loop, mirroring LedgerManager deposit semantics"
  - "eSewa merchant credentials intentionally left ENV-managed/non-editable in the settings UI to avoid storing payment secrets in the database"

requirements-completed: [ADMIN-10]

# Metrics
duration: 25min
completed: 2026-09-04
---

# Phase 09 Plan 06: Platform Settings & Commission Rate Oversight Summary

**Commission rate is now database-driven via `PlatformSetting`, editable from a new admin settings page that also surfaces platform revenue balance and total escrow held.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-09-04T13:18Z (approx)
- **Completed:** 2026-09-04
- **Tasks:** 2 completed
- **Files modified:** 5 (2 created source, 1 created view, 2 modified specs/service)

## Accomplishments
- `Payments::CommissionCalculator` reads `PlatformSetting.commission_rate` instead of a hardcoded `COMMISSION_PERCENTAGE` constant, so admin-configured rates apply to all future commission calculations immediately.
- `Admin::SettingsController#show` surfaces commission rate, platform revenue balance (`DoubleEntry.account(:platform_revenue).balance`), and total escrow held — no Rails console needed.
- `Admin::SettingsController#update` validates the new rate is within `[0, 1]`, persists via `PlatformSetting.set_commission_rate`, and audit-logs the change via `log_admin_action!("update_commission_rate", ...)`.
- Settings view (`app/views/admin/settings/show.html.slim`) renders financial oversight cards plus an update form, and documents that eSewa merchant credentials remain ENV-managed (not DB-editable) for security reasons.

## Task Commits

Each task was committed atomically:

1. **Task 1: CommissionCalculator reads PlatformSetting; Settings controller** - `bfba6ee` (feat)
2. **Task 2: Settings view with financial oversight cards** - `5df4fc8` (feat)

_Note: Task 1 combined TDD-style spec additions (commission_calculator_spec.rb, settings_controller_spec.rb) with the implementation in a single commit since both files were part of one cohesive change._

## Files Created/Modified
- `app/services/payments/commission_calculator.rb` - Now resolves commission rate from `PlatformSetting.commission_rate` at call time; `COMMISSION_PERCENTAGE` constant removed.
- `app/controllers/admin/settings_controller.rb` - New controller with `show`/`update`, rate validation (`BigDecimal` range check), and audit logging.
- `app/views/admin/settings/show.html.slim` - New view with commission rate / revenue / escrow cards, update form, and eSewa ENV-management note.
- `spec/services/payments/commission_calculator_spec.rb` - Added examples for default rate (no `PlatformSetting` row) and changed rate via `PlatformSetting.set_commission_rate`.
- `spec/requests/admin/settings_controller_spec.rb` - New request spec covering `GET /admin/settings` (assigns financial overview) and `PATCH /admin/settings` (valid update + audit log, invalid rate rejected with alert).

## Decisions Made
- Removed `COMMISSION_PERCENTAGE` constant entirely rather than keeping it as a fallback — `PlatformSetting.commission_rate` already defaults to `0.10` (`DEFAULT_COMMISSION_RATE`), so there is a single source of truth with no duplicate defaults to drift out of sync.
- `@total_escrow_held` is computed as `Task.where(payment_type: :esewa, status: [:assigned, :in_progress, :pending_payment, :dispute]).sum(:budget_cents)` instead of iterating `DoubleEntry.account(:escrow, scope: task).balance` per task — cheaper and accurate given the existing `LedgerManager` deposit-at-creation / release-on-completion flow.
- eSewa merchant credentials are deliberately NOT exposed or made editable in the settings UI — kept ENV-only per the threat model's Information Disclosure mitigation (T-09-20).

## Deviations from Plan

None - plan executed exactly as written. The plan's `<action>` code blocks were implemented verbatim; only the spec content beyond the 5 documented behaviors follows straightforward RSpec conventions already used elsewhere in the codebase (e.g., `spec/requests/admin/dashboards_spec.rb`).

## Issues Encountered
- **Shared working-directory git contention:** This plan executed in a shared (non-isolated) git working directory alongside other parallel plan-executor agents committing to the same branch. An earlier `git stash`/`git stash pop` (used to temporarily test for pre-existing spec failures) collided with an old unrelated stash (`WIP on ai_chat`) and a concurrent commit from another agent, producing an unmerged-conflict state and reverting some working-tree edits. Resolved by: (1) removing two stale `.erb` conflict entries that didn't exist in HEAD or the working tree, (2) running `git reset` (mixed) to fully unstage, and (3) recreating the affected files (`commission_calculator.rb`, `commission_calculator_spec.rb`, `settings_controller.rb`, `settings_controller_spec.rb`) from source. Verified afterward that all 9 relevant spec examples pass and that only this plan's 5 files were staged/committed (via `git diff --cached --name-only`) — no other agents' work was touched in the final commits. **Lesson for future runs:** avoid `git stash`/`git reset` entirely in shared/non-worktree-isolated executions; use targeted `git add <path>` only.
- Confirmed two pre-existing failures are unrelated to this plan's changes and were present before any edits: `spec/services/gemini/live_service_spec.rb` (missing `Gemini::LiveService` constant) and `spec/services/payments/ledger_manager_spec.rb` / `ledger_manager_coc_spec.rb` (factory/FK issues unrelated to commission rate). Verified via `git stash` (before the collision above) that these failures exist on the pre-change codebase too — left untouched per scope boundary rules.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- ADMIN-10 fully satisfied: commission rate, platform revenue, and total escrow are all visible and the rate is editable from `/admin/settings` without a Rails console.
- No blockers for subsequent phase-09 plans. Note the pre-existing `ledger_manager` and `gemini` spec failures (unrelated to this plan) remain open issues in the codebase for a future cleanup pass.

---
*Phase: 09-complete-admin-panel-full-super-admin-operations-beyond-user*
*Completed: 2026-09-04*

## Self-Check: PASSED

All 5 created/modified files found on disk; both task commits (`bfba6ee`, `5df4fc8`) found in git history.
