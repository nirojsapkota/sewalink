---
phase: 11-cash-flow-accounting-reconciliation
plan: 01
subsystem: accounting
tags: [double-entry, rails-routes, admin-nav, service-object, rspec]

requires: []
provides:
  - "config/routes.rb admin/accounting/* namespace (dashboard, dashboard/:category, ledger index/show, reports, settlements CRUD-lite)"
  - "Admin nav 'Accounting' link + reusable app/views/admin/accounting/_subnav.html.slim partial"
  - "Accounting::CashFlowCategorizer service (CATEGORIES map, .scope_for, .summary, .label_for)"
  - "Accounting::LedgerQuery service (.call filterable DoubleEntry::Line relation by date/account/code/user)"
  - "AccountingHelper (money_from_cents, cash_flow_category_label, ledger_account_options, ledger_code_options)"
affects: [11-02-dashboard, 11-03-ledger, 11-04-reports, 11-05-reconciliation]

tech-stack:
  added: []
  patterns:
    - "Service objects under app/services/accounting/ namespace for shared DoubleEntry query/categorization logic"
    - "Shared admin subnav partial pattern (app/views/admin/{feature}/_subnav.html.slim) for multi-page admin sub-sections"

key-files:
  created:
    - app/services/accounting/cash_flow_categorizer.rb
    - app/services/accounting/ledger_query.rb
    - app/helpers/accounting_helper.rb
    - app/views/admin/accounting/_subnav.html.slim
    - spec/services/accounting/cash_flow_categorizer_spec.rb
    - spec/services/accounting/ledger_query_spec.rb
  modified:
    - config/routes.rb
    - app/views/layouts/admin.html.slim

key-decisions:
  - "Used plucked-id-array union instead of ActiveRecord#or for LedgerQuery user filter, since #or requires structurally identical relations and one side needed a joins(:accepted_bid) clause"
  - "Spec cleanup order fixed to delete Conversation records before Bid records (bids auto-create a conversation on create, FK blocks Bid.delete_all otherwise)"

patterns-established:
  - "Accounting::CashFlowCategorizer.CATEGORIES is the single source of truth for cash-flow category definitions (label/account/code/sign) reused by dashboard, ledger, and reports views"
  - "Accounting::LedgerQuery.call(...) is the single filtering entrypoint for all ledger-related admin views"

requirements-completed: [ACCT-01, ACCT-02, ACCT-03, ACCT-04, ACCT-05, ACCT-06]

duration: 35min
completed: 2026-09-04
---

# Phase 11 Plan 01: Cash Flow Accounting Foundation Summary

**Established routes, nav, subnav partial, and two shared service objects (`Accounting::CashFlowCategorizer`, `Accounting::LedgerQuery`) plus `AccountingHelper` so the four Wave-2 accounting plans (dashboard, ledger, reports, reconciliation) can build controllers without touching routes/nav/shared logic.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-09-04T16:12:00+10:00 (approx, session start)
- **Completed:** 2026-09-04
- **Tasks:** 3/3 completed
- **Files modified:** 8 (2 modified, 6 created)

## Accomplishments

- Added all `admin/accounting/*` routes (dashboard, dashboard/:category, ledger index/show, reports, settlements index/new/create/show) under the existing `admin` namespace — zero route work needed by downstream plans.
- Added "Accounting" admin nav link and a reusable `_subnav.html.slim` partial (Dashboard/Ledger/Reports/Reconciliation tabs) for all 4 downstream accounting views.
- Built `Accounting::CashFlowCategorizer` with a frozen `CATEGORIES` map covering all 5 required cash-flow categories (escrow deposits, escrow releases, commission revenue, refunds, cash-on-completion commission), fully unit-tested against real `Payments::LedgerManager`-created ledger lines.
- Built `Accounting::LedgerQuery.call(...)` supporting combinable date/account/code/user filters over `DoubleEntry::Line`, fully unit-tested.
- Built `AccountingHelper` for consistent money formatting (`money_from_cents`) and category labels reused across all downstream views.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add all admin/accounting routes, nav link, and shared subnav partial** - `7e8c760` (feat)
2. **Task 2: Build Accounting::CashFlowCategorizer service** - `9e5a141` (test, RED) + `dd19ace` (feat, GREEN)
3. **Task 3: Build Accounting::LedgerQuery service and AccountingHelper** - `9290051` (test, RED) + `32d1ff2` (feat, GREEN)

**Plan metadata:** (final commit, see below)

_Note: TDD tasks (2, 3) have separate RED (failing test) and GREEN (implementation) commits per plan convention._

## Files Created/Modified

- `config/routes.rb` - Added `namespace :accounting` block inside `namespace :admin` with dashboard/ledger/reports/settlements routes
- `app/views/layouts/admin.html.slim` - Added "Accounting" nav link after "Settings"
- `app/views/admin/accounting/_subnav.html.slim` - New shared subnav partial (Dashboard/Ledger/Reports/Reconciliation tabs)
- `app/services/accounting/cash_flow_categorizer.rb` - CATEGORIES map + `.scope_for`/`.summary`/`.label_for`
- `app/services/accounting/ledger_query.rb` - `.call` filterable `DoubleEntry::Line` relation by date/account/code/user
- `app/helpers/accounting_helper.rb` - `money_from_cents`, `cash_flow_category_label`, `ledger_account_options`, `ledger_code_options`
- `spec/services/accounting/cash_flow_categorizer_spec.rb` - 4 examples covering summary categorization, date-range restriction, scope exclusion, and label lookup
- `spec/services/accounting/ledger_query_spec.rb` - 5 examples covering account/code/user/date filtering and combinations

## Decisions Made

- Used a plucked-id-array union (`posted_task_ids + accepted_task_ids`) instead of `ActiveRecord::Relation#or` for the `LedgerQuery` user filter — `#or` raised `ArgumentError: Relation passed to #or must be structurally compatible` because one branch required a `joins(:accepted_bid)` clause not present on the other. This is functionally equivalent and avoids the AR structural-compatibility restriction.
- Fixed spec cleanup ordering (delete `Conversation` records before `Bid` records) in both new specs, since `Bid#after_create :create_conversation` means `Bid.delete_all` violates a FK constraint unless conversations are removed first. This mirrors what will be needed by any future spec creating bids with DoubleEntry-based cleanup.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `ActiveRecord::Relation#or` structural incompatibility in `LedgerQuery.apply_user_filter`**
- **Found during:** Task 3 (Build Accounting::LedgerQuery service)
- **Issue:** The plan's suggested implementation used `Task.where(user_id: user_id).or(Task.joins(:accepted_bid).where(bids: { user_id: user_id }))`, which Rails rejects because the two relations have different `joins` clauses (`#or` requires structurally identical relations aside from `where`/`having`).
- **Fix:** Replaced with two independent `.pluck(:id)` calls unioned via `+`/`.uniq` in Ruby, avoiding the AR-level `#or` restriction entirely while preserving identical semantics (posted tasks OR accepted-bid tasks for the given user).
- **Files modified:** `app/services/accounting/ledger_query.rb`
- **Verification:** `bundle exec rspec spec/services/accounting/ledger_query_spec.rb` — all 5 examples pass, including the user-filter test.
- **Committed in:** `32d1ff2` (part of Task 3 GREEN commit)

**2. [Rule 1 - Bug] Bid/Conversation FK violation in spec cleanup blocks**
- **Found during:** Task 2 (Build Accounting::CashFlowCategorizer service) and Task 3 (Build Accounting::LedgerQuery service)
- **Issue:** `Bid.delete_all` in the `after(:each)` cleanup block raised `PG::ForeignKeyViolation` because `Bid#after_create :create_conversation` auto-creates a `Conversation` row referencing the bid, and the plan's suggested cleanup pattern (copied from `ledger_manager_spec.rb`, which doesn't create bids with conversations attached in the same way) didn't account for this.
- **Fix:** Added `Conversation.delete_all` immediately before `Bid.delete_all` in both new spec files.
- **Files modified:** `spec/services/accounting/cash_flow_categorizer_spec.rb`, `spec/services/accounting/ledger_query_spec.rb`
- **Verification:** Both specs run cleanly across multiple examples without FK errors.
- **Committed in:** `dd19ace` (Task 2 GREEN), `32d1ff2` (Task 3 GREEN)

---

**Total deviations:** 2 auto-fixed (2x Rule 1 - Bug)
**Impact on plan:** Both fixes were necessary for correctness (tests would not pass otherwise) and required no architectural changes. No scope creep — services match the plan's specified interface exactly (`CATEGORIES`, `.scope_for`, `.summary`, `.label_for`, `Accounting::LedgerQuery.call`).

## Issues Encountered

None beyond the two auto-fixed items above, which were resolved inline during TDD GREEN steps.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

All Wave 2 plans (11-02 dashboard, 11-03 ledger, 11-04 reports, 11-05 reconciliation) can now:
- Add controllers under `Admin::Accounting::*` matching the routes already defined (`dashboards#show`/`#category`, `ledger_entries#index`/`#show`, `reports#show`, `settlements#index`/`#new`/`#create`/`#show`), inheriting `Admin::BaseController` for the standard `admin_access?` gate.
- Render `= render "admin/accounting/subnav"` at the top of their views for consistent navigation.
- Call `Accounting::CashFlowCategorizer.summary`/`.scope_for`/`.label_for` and `Accounting::LedgerQuery.call` directly without any further shared-code work.
- Use `AccountingHelper#money_from_cents` for consistent NPR money formatting.

No blockers. Verified via `bin/rails routes -g admin_accounting`, `bundle exec rspec spec/services/accounting/` (9/9 passing), and `bundle exec rspec spec/requests/admin` (43 examples, 1 pre-existing unrelated failure in `dashboards_spec.rb` — not caused by this plan).

## Self-Check: PASSED

All created files confirmed present on disk; all 5 task commit hashes confirmed present in `git log --oneline --all`.
