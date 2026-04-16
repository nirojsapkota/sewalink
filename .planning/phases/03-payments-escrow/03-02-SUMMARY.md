---
phase: "03-payments-escrow"
plan: "02"
subsystem: "Payment Integration"
tags: ["esewa", "payment-gateway", "v2"]
tech-stack: ["esewa-v2", "httparty"]
key-files: ["app/services/payments/esewa_v2.rb", "app/models/payment_transaction.rb", "app/controllers/payments_controller.rb"]
requirements: ["PAY-01"]
metrics:
  duration: "45m"
  completed_at: "2026-04-14"
---

# Phase 3 Plan 02: eSewa Integration Summary

Successfully integrated eSewa ePay v2 as the primary payment gateway for sewaLink.

## Key Accomplishments
- **EsewaV2 Service**: Implemented signature generation and server-to-server verification logic using eSewa v2 specifications.
- **Payment Tracking**: Created `PaymentTransaction` model with AASM for state management (pending, completed, failed).
- **Checkout Flow**: Implemented `PaymentsController` to handle transaction initialization and secure callbacks.
- **Security**: Mandatory server-side verification ensures that payment status cannot be spoofed by client-side redirects.

## Decisions Made
- Use UUIDs for `transaction_uuid` to prevent transaction ID guessing.
- Skip client-side verification entirely in favor of server-to-server status check.

## Deviations from Plan
- **Rule 1 - Bug**: Fixed a `PG::NotNullViolation` on `tasks.budget` by removing the legacy `budget` column and relying solely on `budget_cents` via `money-rails`.

## Self-Check: PASSED
- `EsewaV2.generate_signature` matches eSewa test vectors.
- `PaymentTransaction` state transitions work as expected.
- `PaymentsController#success` verified against mock eSewa API hits.
