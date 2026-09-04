---
phase: 11-cash-flow-accounting-reconciliation
plan: 02
subsystem: accounting
tags: [double-entry, admin-dashboard, rspec, slim, kaminari]

requires:
  - phase: 11-cash-flow-accounting-reconciliation (plan 01)
    provides: "admin/accounting routes, subnav partial, Accounting::CashFlowCategorizer, AccountingHelper"
provides:
  - "Admin::Accounting::DashboardsController#show / #category"
  - "Cash flow dashboard view (5-category summary cards + date range filter)"
  - "Category drill-down view (paginated DoubleEntry::Line listing per category)"
affects: [11-03-ledger, 11-04-reports, 11-05-reconciliation]

tech-stack:
  added: []
  patterns:
    - "Admin::BaseController-inherited controllers use assign_date_range with Date.parse rescued to a safe default, never raising on malformed query params"
    - "KeyError from CashFlowCategorizer.label_for/scope_for caught at controller level and redirected with an alert, rather than raising a 500"

key-files:
  created:
    - app/controllers/admin/accounting/dashboards_controller.rb
    - app/views/admin/accounting/dashboards/show.html.slim
    - app/views/admin/accounting/dashboards/category.html.slim
    - spec/requests/admin/accounting/dashboards_controller_spec.rb
  modified: []

key-decisions:
  - "Used ApplicationController.helpers.humanized_money_with_symbol in the request spec (not available directly in request-spec context) instead of asserting on raw cents"
  - "Asserted flash[:alert] directly for the non-admin-denial spec instead of following the redirect body, since HomeController#index redirects signed-in non-admin users a second time (poster/tasker dashboard), leaving the followed response body empty — same root cause as the pre-existing known failure in spec/requests/admin/dashboards_spec.rb"
  - "category.html.slim reads line[:account]/line[:code]/line[:amount] (raw DB attributes) rather than line.account/line.amount, since DoubleEntry::Line overrides those readers to return DoubleEntry::Account::Instance and Money objects respectively"

patterns-established:
  - "Money display in accounting views always goes through AccountingHelper#money_from_cents fed by raw integer cent attributes, never through DoubleEntry's ActiveRecord-level Money-wrapped readers"

requirements-completed: [ACCT-01, ACCT-02]

duration: 25min
completed: 2026-09-04
---

# Phase 11 Plan 02: Cash Flow Dashboard & Category Drill-Down Summary

**Built `Admin::Accounting::DashboardsController#show`/`#category` and two Slim views giving admins/accountants an at-a-glance 5-category cash-flow summary for any date range, with click-through to the individual `DoubleEntry::Line` transactions behind each category total.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-09-04T16:15:36+10:00 (session start)
- **Completed:** 2026-09-04T06:18:58Z
- **Tasks:** 2/2 completed
- **Files modified:** 4 (all created)

## Accomplishments

- `Admin::Accounting::DashboardsController#show` computes `Accounting::CashFlowCategorizer.summary(from:, to:)` for a date range defaulting to the last 30 days, with malformed `from`/`to` params safely falling back to the default range instead of raising.
- `#category` renders a paginated (Kaminari, 20/page) list of the `DoubleEntry::Line` rows backing a single category, redirecting to the dashboard with an alert if an unknown category key is requested (`KeyError` caught, no 500).
- `show.html.slim` renders 5 clickable category cards (label, total via `money_from_cents`, transaction count) plus a date-range filter form; each card links to `admin_accounting_dashboard_category_path`.
- `category.html.slim` renders the contributing transactions table, each row linking onward to `admin_accounting_ledger_path` (owned by plan 11-03) for full transaction detail.
- Request spec covers: accountant access + correct in-range/out-of-range summary totals, default 30-day range, super_admin access, plain-user denial, unauthenticated redirect, category drill-down content, and unknown-category redirect — 7 examples, all passing.

## Task Commits

Each task was committed atomically (TDD RED then GREEN):

1. **RED — failing spec for both actions** - `4155139` (test)
2. **Task 1: Dashboard summary action + view (GREEN)** - `a8d838a` (feat)
3. **Task 2: Category drill-down view (GREEN)** - `ed3daa9` (feat)

_Note: Both tasks' behavior was implemented in a single controller file per the plan's own action content (Task 1's action block already specified both `#show` and `#category`); the two GREEN commits split the view-layer work per task boundary._

## Files Created/Modified

- `app/controllers/admin/accounting/dashboards_controller.rb` - `#show`/`#category` actions, `assign_date_range` private helper
- `app/views/admin/accounting/dashboards/show.html.slim` - 5-category summary cards + date range form
- `app/views/admin/accounting/dashboards/category.html.slim` - paginated transaction listing for one category
- `spec/requests/admin/accounting/dashboards_controller_spec.rb` - 7 examples across both actions and all access-control paths

## Decisions Made

- **Money helper in request spec:** `humanized_money_with_symbol` is a view helper (money-rails) not available directly inside a request-spec example group; used `ApplicationController.helpers.humanized_money_with_symbol(...)` to compute the expected formatted string.
- **Flash assertion instead of double-redirect follow:** `HomeController#index` redirects a signed-in plain user again (to `poster_dashboard_path`/`tasker_dashboard_path`), so `follow_redirect!` once from the admin-denial redirect lands on an already-redirected (body-empty) response. Asserted `flash[:alert]` directly instead of following the redirect body — this is the same underlying behavior that causes the pre-existing known failure in `spec/requests/admin/dashboards_spec.rb` (not touched, out of scope for this plan).
- **Raw DB attributes for DoubleEntry::Line in the view:** `line.account` and `line.amount` are overridden readers returning `DoubleEntry::Account::Instance` and `Money` objects respectively (not plain strings/integers). The category view intentionally uses `line[:account]`/`line[:code]`/`line[:amount]` (raw attribute access) to get the plain string/integer values needed for display and to feed `money_from_cents` correctly.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `line.amount`/`line.account` return wrapped objects, not raw values**
- **Found during:** Task 2 (Category drill-down view) — spec failure showed a wildly wrong money amount (`रू10` instead of the actual line amount) and an object-inspect string instead of the account name.
- **Issue:** The plan's suggested view code used `line[:account]`, `line[:code]`, `line[:amount]` already (bracket/raw attribute access) — verified this matches DoubleEntry's ActiveRecord attribute overrides where `.account`/`.amount` return `DoubleEntry::Account::Instance`/`Money` objects. No deviation from plan text was actually needed; this was a self-correction during implementation to match the plan's own specified code exactly.
- **Fix:** Used `line[:account]`, `line[:code]`, `line[:amount].abs` per the plan's action block.
- **Files modified:** `app/views/admin/accounting/dashboards/category.html.slim`
- **Verification:** `bundle exec rspec spec/requests/admin/accounting/dashboards_controller_spec.rb` — all 7 examples pass, including the category drill-down content assertion.
- **Committed in:** `ed3daa9`

**2. [Rule 1 - Bug] Spec-only fixes: `travel_to` helper, flash assertion, money helper access**
- **Found during:** Task 1 GREEN run — `NoMethodError: undefined method 'travel_to'`, empty-body flash assertion failure, and `NoMethodError: undefined method 'humanized_money_with_symbol'` in the request spec itself (not application code).
- **Issue:** `ActiveSupport::Testing::TimeHelpers` isn't globally included in `rails_helper.rb` for request specs; `humanized_money_with_symbol` is a view helper unavailable directly in request-spec scope; following a redirect to `root_path` for a signed-in non-admin user lands on a second redirect (empty body) rather than a rendered page.
- **Fix:** `include ActiveSupport::Testing::TimeHelpers` at the top of the spec; used `ApplicationController.helpers.humanized_money_with_symbol(...)`; asserted `flash[:alert]` directly instead of following the redirect body.
- **Files modified:** `spec/requests/admin/accounting/dashboards_controller_spec.rb`
- **Verification:** Full spec file green (7/7).
- **Committed in:** `a8d838a`

---

**Total deviations:** 2 auto-fixed (both Rule 1 - Bug, both self-contained fixes to get the plan's own specified behavior working correctly; no scope creep, no architectural changes).
**Impact on plan:** None — final implementation matches the plan's specified controller/view code and interfaces exactly.

## Issues Encountered

None beyond the two auto-fixed items above, resolved inline during TDD GREEN steps.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- 11-03 (ledger) can now rely on `admin_accounting_ledger_path` being linked-to from the category drill-down view; no coupling in the other direction.
- 11-04 (reports) and 11-05 (reconciliation) are unaffected by this plan's files.
- Verified via `bundle exec rspec spec/requests/admin/accounting/dashboards_controller_spec.rb` (7/7 passing) and `bundle exec rspec spec/requests/admin spec/services/accounting` (59 examples, 1 pre-existing unrelated failure in `spec/requests/admin/dashboards_spec.rb` — not caused by this plan, same root cause documented above).

No blockers.

## Self-Check: PASSED

All created files confirmed present on disk; all 3 commit hashes (`4155139`, `a8d838a`, `ed3daa9`) confirmed present in `git log --oneline --all`.
