---
phase: 11-cash-flow-accounting-reconciliation
plan: 03
subsystem: accounting
tags: [double-entry, admin-ledger, rspec, slim, kaminari]

requires:
  - phase: 11-cash-flow-accounting-reconciliation (plan 01)
    provides: "admin/accounting routes, subnav partial, Accounting::LedgerQuery, AccountingHelper"
provides:
  - "Admin::Accounting::LedgerEntriesController#index / #show"
  - "Filterable ledger view (date range, account, code, user_id)"
  - "Single-transaction detail view: paired line + linked Task/User + AdminActivityLog dispute-resolution history"
affects: [11-04-reports, 11-05-reconciliation]

tech-stack:
  added: []
  patterns:
    - "DoubleEntry::Line raw attribute access (line[:account]/line[:code]/line[:scope]/line[:amount]) used consistently in controller and views, since the method readers (.account/.amount) return wrapped Account::Instance/Money objects (established in 11-02, reapplied here)"
    - "AdminActivityLog target_type/target_id (non-polymorphic string+id columns) queried directly for dispute-resolution history, details column JSON.parse'd in the view"

key-files:
  created:
    - app/controllers/admin/accounting/ledger_entries_controller.rb
    - app/views/admin/accounting/ledger_entries/index.html.slim
    - app/views/admin/accounting/ledger_entries/show.html.slim
    - spec/requests/admin/accounting/ledger_entries_controller_spec.rb
  modified: []

key-decisions:
  - "resolve_linked_context branches on line[:account] ('escrow' -> @linked_task via line[:scope]==task.id, 'tasker_balance' -> @linked_user via line[:scope]==user.id); other account types (platform_revenue, user_external) intentionally leave both nil since they have no single natural owning task/user"
  - "Non-existent ledger id and invalid date-range params both rescued at the controller level (ActiveRecord::RecordNotFound / ArgumentError) and redirect with a flash alert rather than raising, consistent with the 11-02 dashboard controller's error-handling pattern"

patterns-established:
  - "Ledger detail page surfaces AdminActivityLog dispute-resolution history for any escrow-scoped transaction without needing a direct FK/association — matches on target_type/target_id string+id pair already used by Admin::DisputesController#resolve"

requirements-completed: [ACCT-03, ACCT-04]

duration: 20min
completed: 2026-09-04
---

# Phase 11 Plan 03: Ledger Search/Filter & Transaction Detail Summary

**Built `Admin::Accounting::LedgerEntriesController#index`/`#show` and two Slim views giving admins a fully filterable (date range, account, code, user) `DoubleEntry::Line` ledger, plus a single-transaction detail page showing the paired double-entry line and any linked Task/User/dispute-resolution history.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-09-04 (session start)
- **Completed:** 2026-09-04
- **Tasks:** 2/2 completed
- **Files modified:** 4 (all created)

## Accomplishments

- `Admin::Accounting::LedgerEntriesController#index` delegates all filtering to the existing `Accounting::LedgerQuery.call(from:, to:, account:, code:, user_id:)` service (built in 11-01), paginated 20/page via Kaminari. Malformed `from`/`to` date params are rescued (`ArgumentError`) and redirect with a flash alert instead of raising a 500.
- `index.html.slim` renders a filter form (date range inputs, account/code select dropdowns fed by `AccountingHelper#ledger_account_options`/`#ledger_code_options`, user_id text input) plus a paginated results table linking each row to the transaction detail page.
- `#show` resolves `DoubleEntry::Line.find(params[:id])`, its paired line via `line.partner`, and — depending on `line[:account]` — either `@linked_task` (escrow lines, scoped by `line[:scope]` == task id) with its `AdminActivityLog` dispute-resolution history (`target_type: "Task", target_id: ...`), or `@linked_user` (tasker_balance lines, scoped by `line[:scope]` == user id).
- `show.html.slim` renders the line detail, the paired line, the linked task (title/poster/tasker/status + dispute-resolution history list with parsed JSON decision), or the linked user, as applicable.
- Non-existent line id rescued (`ActiveRecord::RecordNotFound`) and redirects to the index with a flash alert.
- Request spec covers: unfiltered index listing, account filter, code filter, date-range filter, user_id filter (correctly scoped to only that poster's escrow lines via task ownership), invalid-date-format redirect, accountant/plain-user/unauthenticated access control for `#index`, and for `#show`: linked task context (title + status rendered), dispute-resolution decision text rendered from `AdminActivityLog`, linked user context (tasker's first name rendered) for a `tasker_balance` line, and the non-existent-id redirect — 12 examples total, all passing.

## Task Commits

Each task was committed atomically:

1. **Task 1: Ledger index action with filters** - `38fc632` (feat)
2. **Task 2: Single transaction detail (#show) with linked task/user/dispute context** - `956f787` (feat)

_Note: Both tasks touch the same controller file and the same spec file. To keep the per-task commit history accurate, Task 1 was committed with only the `#index` action/spec-block present, then Task 2's `#show`/`resolve_linked_context` code and the corresponding spec `describe` block were added back in and committed separately — each commit's tests were independently verified green before committing (8 examples for Task 1's commit state, 12 for the final Task 2 state)._

## Files Created/Modified

- `app/controllers/admin/accounting/ledger_entries_controller.rb` - `#index` (filtered/paginated ledger via `Accounting::LedgerQuery.call`), `#show` (line + partner + linked task/user + dispute logs), private `resolve_linked_context`
- `app/views/admin/accounting/ledger_entries/index.html.slim` - Filter form (date range, account, code, user_id) + paginated results table
- `app/views/admin/accounting/ledger_entries/show.html.slim` - Single transaction detail: line, paired line, linked task (with dispute-resolution history) or linked user
- `spec/requests/admin/accounting/ledger_entries_controller_spec.rb` - 12 examples across `#index` (6) and `#show` (4) plus access-control paths (2, shared with index)

## Decisions Made

- **Linked-context branching:** `resolve_linked_context` only populates `@linked_task` for `escrow`-account lines and `@linked_user` for `tasker_balance`-account lines — `platform_revenue` and `user_external` lines intentionally show no linked task/user since those accounts aren't scoped to a single task/user in the same way (matches the plan's interface spec exactly).
- **Error handling parity with 11-02:** Both invalid date params (`#index`) and non-existent line ids (`#show`) redirect with a flash alert rather than raising, mirroring the pattern established in the 11-02 `DashboardsController`.
- **Raw attribute access for `DoubleEntry::Line`:** Consistently used `line[:account]`/`line[:code]`/`line[:scope]`/`line[:amount]` (never the wrapped `.account`/`.amount` method readers) throughout the controller and both views, per the convention discovered and documented in 11-02.

## Deviations from Plan

None — plan executed exactly as written. The controller/view code matches the plan's `<action>` blocks verbatim (including the raw-attribute-access pattern already specified in the plan's own interface section), and both `<acceptance_criteria>` grep checks pass:
- `grep -c "Accounting::LedgerQuery.call" app/controllers/admin/accounting/ledger_entries_controller.rb` → `1`
- `grep -c "AdminActivityLog.where" app/controllers/admin/accounting/ledger_entries_controller.rb` → `1`
- `grep -c "line.partner" app/controllers/admin/accounting/ledger_entries_controller.rb` → `1`

## Issues Encountered

None. Both tasks passed on first implementation attempt with no auto-fixes needed.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- 11-04 (reports) and 11-05 (reconciliation) are unaffected by this plan's files (no shared file overlap).
- `admin_accounting_ledger_path` is now a fully working destination for the "View" links already present in 11-02's dashboard category drill-down view.
- Verified via `bundle exec rspec spec/requests/admin/accounting/ledger_entries_controller_spec.rb` (12/12 passing) and `bundle exec rspec spec/requests/admin spec/services/accounting` (71 examples, 1 pre-existing unrelated failure in `spec/requests/admin/dashboards_spec.rb` — not caused by this plan, same root cause documented in 11-02's summary).

No blockers.

## Self-Check: PASSED

All created files confirmed present on disk; both commit hashes (`38fc632`, `956f787`) confirmed present in `git log --oneline --all`.

Verified again post-write:
- FOUND: app/controllers/admin/accounting/ledger_entries_controller.rb
- FOUND: app/views/admin/accounting/ledger_entries/index.html.slim
- FOUND: app/views/admin/accounting/ledger_entries/show.html.slim
- FOUND: spec/requests/admin/accounting/ledger_entries_controller_spec.rb
- FOUND: 38fc632
- FOUND: 956f787
