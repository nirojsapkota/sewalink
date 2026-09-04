---
phase: 11-cash-flow-accounting-reconciliation
plan: 05
subsystem: accounting
tags: [double-entry, csv-import, reconciliation, admin-accounting, rspec, slim]

requires:
  - phase: 11-cash-flow-accounting-reconciliation (plan 01)
    provides: "admin/accounting routes, subnav partial, AccountingHelper"
provides:
  - "EsewaSettlement model (unmatched/matched/mismatched status enum, monetize amount_cents)"
  - "Accounting::EsewaSettlementImporter.call(file:, imported_by:) — guarded CSV import (size/type/row-count/column validation)"
  - "Accounting::ReconciliationMatcher.call(settlement) / .call_all(settlements) — amount+date matching against escrow-deposit DoubleEntry::Line rows"
  - "Admin::Accounting::SettlementsController#index/#new/#create/#show + views"
affects: []

tech-stack:
  added: []
  patterns:
    - "CSV import guard order: file size -> content-type/extension allow-list -> parse -> row-count -> per-column presence -> per-row validation, all before any DB write"
    - "DoubleEntry::Line raw attribute hash access (line[:account]/[:code]/[:amount]) reused in settlements/show view, consistent with 11-02/11-03 convention"

key-files:
  created:
    - db/migrate/20260905000000_create_esewa_settlements.rb
    - app/models/esewa_settlement.rb
    - spec/factories/esewa_settlements.rb
    - app/services/accounting/esewa_settlement_importer.rb
    - app/services/accounting/reconciliation_matcher.rb
    - spec/services/accounting/esewa_settlement_importer_spec.rb
    - spec/services/accounting/reconciliation_matcher_spec.rb
    - app/controllers/admin/accounting/settlements_controller.rb
    - app/views/admin/accounting/settlements/index.html.slim
    - app/views/admin/accounting/settlements/new.html.slim
    - app/views/admin/accounting/settlements/show.html.slim
    - spec/requests/admin/accounting/settlements_controller_spec.rb
    - spec/fixtures/files/esewa_settlements_valid.csv
  modified:
    - db/schema.rb

key-decisions:
  - "ReconciliationMatcher treats zero OR multiple amount+date candidate escrow-deposit lines as 'mismatched' (only an exact single-candidate match is 'matched'), per the plan's explicit behavior spec — verified with a dedicated multi-candidate spec example."
  - "Settlements#create uses params.require(:file) directly (no strong-parameter model needed since it's a raw upload, not a persisted-attribute assignment) and always calls ReconciliationMatcher.call_all on all currently-unmatched settlements after every import, so previously-unmatched rows get a chance to match against newly-imported ledger activity too."

patterns-established: []

requirements-completed: [ACCT-06]

duration: 40min
completed: 2026-09-04
---

# Phase 11 Plan 05: eSewa Settlement CSV Import & Reconciliation Summary

**Built `EsewaSettlement` (model+migration), `Accounting::EsewaSettlementImporter` (guarded CSV upload parser), `Accounting::ReconciliationMatcher` (amount+date matcher against escrow-deposit ledger lines), and `Admin::Accounting::SettlementsController` (index/new/create/show) so admins can upload an eSewa settlement CSV and see per-row match status plus a period-level discrepancy total against the internal ledger.**

## Performance

- **Duration:** ~40 min
- **Completed:** 2026-09-04
- **Tasks:** 3/3 auto tasks completed; Task 4 (human-verify checkpoint) reported to user, pending approval
- **Files modified:** 13 created, 1 modified (db/schema.rb)

## Accomplishments

- `EsewaSettlement` model: `status` enum (`unmatched`/`matched`/`mismatched`, defaulting `unmatched`), `monetize :amount_cents`, presence/numericality validations, `belongs_to :imported_by`. Migration applied (`bin/rails db:migrate`), `db/schema.rb` updated and committed.
- `Accounting::EsewaSettlementImporter.call(file:, imported_by:)` validates file size (5MB max) and content-type/extension allow-list **before** calling `CSV.parse`, then enforces a 5000-row cap and required-column presence (with header aliasing for `ref`/`reference`/`transaction_id` etc.) before any DB writes; per-row blank-field or parse errors are collected in `Result#errors` without aborting the rest of the import.
- `Accounting::ReconciliationMatcher.call(settlement)` matches a settlement to `escrow`/`deposit` `DoubleEntry::Line` rows by exact `amount_cents` + calendar-day `settled_on`; exactly one candidate → `matched` (+ `matched_line_id`), zero or multiple candidates → `mismatched` (`matched_line_id` cleared). `.call_all(settlements)` batches this over a relation.
- `Admin::Accounting::SettlementsController#index` computes settlement total vs. internal escrow-deposit total vs. discrepancy for a date range; `#create` runs the importer then `ReconciliationMatcher.call_all` over all unmatched settlements and logs an `AdminActivityLog` audit entry; `#show` displays a settlement and its matched ledger line (or a "no match" message).
- Views: `index.html.slim` (filter form, 3 summary cards, results table), `new.html.slim` (upload form + column-format help text), `show.html.slim` (settlement + matched-line detail).

## Task Commits

1. **Task 1: EsewaSettlement schema + model + factory** - `fbecf80` (feat)
2. **Task 2 RED — failing specs for importer/matcher** - `f606436` (test)
3. **Task 2 GREEN — importer + matcher implementation** - `07e4f5c` (feat)
4. **Task 3: Settlements controller + views + request spec** - `079ee36` (feat)

## Files Created/Modified

- `db/migrate/20260905000000_create_esewa_settlements.rb` - `esewa_settlements` table (transaction_ref, amount_cents, settled_on, status, raw_row, imported_by_id FK, matched_line_id) + 3 indexes
- `db/schema.rb` - regenerated to version `2026_09_05_000000`
- `app/models/esewa_settlement.rb` - status enum, monetize, validations
- `spec/factories/esewa_settlements.rb` - valid-by-default factory
- `app/services/accounting/esewa_settlement_importer.rb` - guarded CSV importer (size/type/row-count/column checks, header aliasing, per-row error collection)
- `app/services/accounting/reconciliation_matcher.rb` - `.call`/`.call_all` amount+date matcher
- `spec/services/accounting/esewa_settlement_importer_spec.rb` - 6 examples (valid import, oversized file, wrong type, too many rows, missing column, blank-field row skip)
- `spec/services/accounting/reconciliation_matcher_spec.rb` - 4 examples (matched, mismatched-zero-candidates, mismatched-multiple-candidates, `.call_all`)
- `app/controllers/admin/accounting/settlements_controller.rb` - `#index`/`#new`/`#create`/`#show`
- `app/views/admin/accounting/settlements/{index,new,show}.html.slim`
- `spec/requests/admin/accounting/settlements_controller_spec.rb` - 5 examples (accountant success + discrepancy math, plain-user denial, unauthenticated redirect, valid CSV import via `Rack::Test::UploadedFile`, oversized/wrong-type rejection)
- `spec/fixtures/files/esewa_settlements_valid.csv` - 2-row fixture (`transaction_ref,amount,date` headers)

## Decisions Made

- **Mismatched-on-multiple-candidates:** Added an explicit spec example (not in the plan's literal `<action>` text, but required by the plan's own `<behavior>` spec) proving that 2+ same-amount/same-day escrow-deposit lines also yield `mismatched`, not just the zero-candidate case.
- **Audit logging:** `log_admin_action!("import_esewa_settlement", nil, details: { imported_count:, error_count: })` records every CSV import per the threat model's T-11-20 (Repudiation) mitigation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Slim syntax error in `settlements/index.html.slim` discrepancy card**
- **Found during:** Task 3, running `spec/requests/admin/accounting/settlements_controller_spec.rb`
- **Issue:** The plan's suggested view code used `span.block = @discrepancy_cents.zero? ? "text-green-800" : "text-red-800"` immediately followed by a nested `| Discrepancy` line. A Slim `=` output tag cannot host nested block content (only tags followed by literal `do...end` Ruby blocks can), causing `ActionView::SyntaxErrorInTemplate: unexpected 'do', expecting 'end' or dummy end`.
- **Fix:** Rewrote the line as `span.block class=(@discrepancy_cents.zero? ? "text-green-800" : "text-red-800") Discrepancy`, moving the ternary into a `class=` attribute and using "Discrepancy" as the tag's literal inline text instead of nested block content. Functionally identical output (same conditional CSS class, same "Discrepancy" label).
- **Files modified:** `app/views/admin/accounting/settlements/index.html.slim`
- **Verification:** `bundle exec rspec spec/requests/admin/accounting/settlements_controller_spec.rb` — all 5 examples pass.
- **Committed in:** `079ee36`

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug, template syntax only, no behavior change from what the plan intended).
**Impact on plan:** None — final view renders the exact same conditional styling and "Discrepancy" label the plan specified; only the Slim markup mechanics differ.

## Issues Encountered

None beyond the one auto-fixed Slim syntax issue above.

## User Setup Required

None — no external service configuration required.

## Checkpoint Status (Task 4)

**Task 4 (`checkpoint:human-verify`, gate: blocking) has NOT been executed by this agent** — per the checkpoint protocol, execution stopped after Task 3 and the checkpoint content was returned to the user for manual browser verification of the full Phase 11 accounting suite (dashboard, ledger, reports, settlements/reconciliation). This plan is **not yet complete**; `STATE.md`/`ROADMAP.md`/`REQUIREMENTS.md` updates and the final metadata commit are deferred until the user replies "approved" (or reports issues) for Task 4.

## Next Phase Readiness

- All 3 auto tasks' artifacts exist and are fully tested (15 new spec examples across importer/matcher/controller, all passing).
- `bundle exec rspec spec/services/accounting/ spec/requests/admin/accounting/` — 50/50 passing.
- `bundle exec rspec spec/requests/admin spec/services/accounting spec/models` — 143 examples, 9 failures, all 9 confirmed pre-existing (1 known `dashboards_spec.rb` failure + 8 pre-existing `message_spec.rb`/`task_escrow_lifecycle_spec.rb`/`task_spec.rb` failures verified present at commit `b10de7b`, i.e. before this plan's changes, via a throwaway `git worktree`) — none caused by this plan.
- `git status --short` clean after all 3 auto-task commits.
- Blocked on the Task 4 human-verify checkpoint before the plan/phase can be marked complete.

## Self-Check: PASSED

All created files confirmed present on disk; all 4 commit hashes (`fbecf80`, `f606436`, `07e4f5c`, `079ee36`) confirmed present in `git log --oneline --all`.
