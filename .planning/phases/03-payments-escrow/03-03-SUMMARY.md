---
phase: "03-payments-escrow"
plan: "03"
subsystem: "Escrow Lifecycle"
tags: ["ledger", "escrow", "automation"]
tech-stack: ["double_entry", "money-rails"]
key-files: ["app/services/payments/ledger_manager.rb", "app/models/task.rb", "app/models/payment_transaction.rb"]
requirements: ["PAY-01", "PAY-03"]
metrics:
  duration: "45m"
  completed_at: "2026-04-14"
---

# Phase 3 Plan 03: Escrow Lifecycle Summary

Implemented the core escrow lifecycle, automating the movement of funds from payment to escrow, and then to the tasker and platform revenue upon task completion.

## Key Accomplishments
- **LedgerManager**: Centralized service for all ledger transfers (`deposit_to_escrow`, `release_from_escrow`).
- **Automated Deposit**: eSewa payments automatically trigger a deposit into the task-scoped escrow account via `after_commit` hooks on `PaymentTransaction`.
- **Automated Release**: Completing a task automatically triggers the release of funds from escrow to the tasker's balance and platform revenue, incorporating commission calculations.
- **Safety Checks**: Digital tasks are blocked from moving to `in_progress` or `completed` without a verified payment in escrow.

## Decisions Made
- Use task-scoped escrow accounts to ensure funds are isolated per task.
- Rely on `DoubleEntry`'s internal transaction management for ledger transfers.
- Commissions are deducted at the point of escrow release.

## Deviations from Plan
- **Rule 1 - Bug**: Fixed `DoubleEntry::Locking::LockMustBeOutermostTransaction` by removing nested `ActiveRecord` transactions around ledger transfers.
- **Rule 3 - Blocking**: Updated `Bid` factory to include `payment_method` to fix failing `LedgerManager` specs.

## Self-Check: PASSED
- `LedgerManager.deposit_to_escrow` verified by tests.
- `LedgerManager.release_from_escrow` verified by tests.
- Task lifecycle transitions correctly handle escrow operations.
