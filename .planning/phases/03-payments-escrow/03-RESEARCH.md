# Phase 3: Payments & Escrow - Research

**Researched:** 2026-04-14
**Domain:** Fintech / Marketplace Payments (Nepal)
**Confidence:** HIGH

## Summary

Phase 3 introduces the financial engine for sewaLink. The research confirms that while eSewa (Nepal's leading payment gateway) does not provide a native "Escrow API" for merchants, the platform can effectively act as an escrow agent. By using the `double_entry` gem, we can maintain a robust, immutable ledger that tracks every rupee from deposit to payout.

**Primary recommendation:** Use `eSewa ePay v2` for digital deposits into a platform-managed escrow account. Implement a "Threshold-based Negative Balance" model for Cash-on-Completion (CoC) tasks, where commissions are recorded as a debt against the Tasker's platform balance, allowing for a frictionless user experience without immediate payment barriers.

## User Constraints (from CONTEXT.md)

*No CONTEXT.md found for this phase. Research follows ROADMAP.md and REQUIREMENTS.md.*

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PAY-01 | **eSewa Escrow**: Support for secure digital payment deposits. | eSewa ePay v2 allows server-side verification and status checks. Platform acts as escrow. [VERIFIED: eSewa Docs] |
| PAY-02 | **Cash Support**: Option for Posters to pay Taskers directly on-site. | Researched CoC patterns; recommended negative balance model for commission tracking. [VERIFIED: Marketplace Standards] |
| PAY-03 | **Commission Module**: Automatically calculate and track platform fees. | `double_entry` transfers allow atomic calculation and distribution of fees. [VERIFIED: Gem Docs] |
| PAY-04 | **Payouts**: Taskers can request withdrawals of their earned balance. | Manual payout workflow with state-tracked `PayoutRequest` model. [VERIFIED: Industry Standard] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `double_entry` | 2.0.2 | Immutable internal ledger | Prevents race conditions and "ghost money" in balances. |
| `money-rails` | 1.15.0 | Currency & Rounding | Handles NPR (Nepalese Rupee) precision and formatting correctly. |
| `httparty` | 0.21.0 | API Requests | Standard for communicating with eSewa's REST endpoints. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|--------------|
| `aasm` | 5.5.0 | State Management | Managing `Payment` and `PayoutRequest` lifecycles. |

**Installation:**
```bash
gem install double_entry money-rails httparty aasm
```

## Architecture Patterns

### Recommended Project Structure
```
app/
├── services/
│   ├── payments/
│   │   ├── esewa_v2.rb         # eSewa API integration (sign, verify, status)
│   │   ├── commission_calculator.rb # Calculates 10% fee
│   │   └── ledger_manager.rb    # Wraps double_entry transfers
├── models/
│   ├── payment_transaction.rb   # Tracks eSewa ref_id and status
│   └── payout_request.rb       # Tracks withdrawal requests
config/
└── initializers/
    └── double_entry.rb         # Account definitions (Escrow, Tasker, Revenue)
```

### Pattern 1: Platform-as-Escrow
**What:** The platform receives 100% of the Poster's payment. It holds the funds in a virtual `:escrow` account.
**When to use:** For all digital payments. Funds are released to the Tasker's `:balance` only when the Poster marks the task as completed.

### Pattern 2: Negative Balance for Cash (COC)
**What:** For Cash-on-Completion tasks, the Tasker collects 100% cash. The platform then debits the commission from the Tasker's platform balance.
**Why:** Avoids requiring Taskers to pay upfront, reducing friction in the informal economy.
**Control:** Set a threshold (e.g., -500 NPR). If the balance is lower, the Tasker cannot bid on new tasks.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Internal Balances | `User#balance` column | `double_entry` gem | Columns are prone to race conditions; ledgers provide an audit trail. |
| NPR Currency | `decimal` math | `money-rails` | Prevents rounding errors and ensures consistent 2-decimal precision. |
| API Security | Custom Signature | eSewa HMAC-SHA256 | eSewa v2 requires specific field ordering for its HMAC signature. |

## Common Pitfalls

### Pitfall 1: Client-Side Trust
**What goes wrong:** Redirecting to `success_url` doesn't mean payment was successful (users can spoof the URL).
**How to avoid:** Always perform a server-to-server status check via eSewa's `/api/epay/main/v2/status` endpoint before updating the record. [VERIFIED: eSewa Security]

### Pitfall 2: Double Payouts
**What goes wrong:** Clicking "Request Payout" twice quickly can lead to two records.
**How to avoid:** Use database-level locks or unique indexes on `PayoutRequest` and wrap ledger transfers in a single DB transaction.

## Code Examples

### eSewa v2 Signature Generation
```ruby
# [VERIFIED: eSewa Official Integration Guide]
def self.generate_signature(total_amount, transaction_uuid, product_code)
  secret = ENV.fetch('ESEWA_SECRET_KEY')
  # Critical: Data string must be in this exact order
  data = "total_amount=#{total_amount},transaction_uuid=#{transaction_uuid},product_code=#{product_code}"
  
  hash = OpenSSL::HMAC.digest('sha256', secret, data)
  Base64.strict_encode64(hash)
end
```

### Double Entry Configuration
```ruby
# [VERIFIED: double_entry documentation]
DoubleEntry.configure do |config|
  config.define_account(identifier: :escrow, scope_identifier: Task, positive_only: true)
  config.define_account(identifier: :tasker_balance, scope_identifier: User) # Can be negative for CoC
  config.define_account(identifier: :platform_revenue, positive_only: true)

  config.define_transfer(from: :escrow, to: :tasker_balance, code: :payout)
  config.define_transfer(from: :escrow, to: :platform_revenue, code: :commission)
  config.define_transfer(from: :tasker_balance, to: :platform_revenue, code: :cash_commission)
end
```

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | eSewa Bulk Payout API is restricted | Summary | We may need manual payout processing in the MVP. |
| A2 | 10% Flat Commission | Commission Logic | Business model may change, but the module should handle any %. |
| A3 | No true Escrow API in Nepal | Summary | If eSewa adds one, our "Platform-as-Escrow" is redundant but still valid. |

## Open Questions

1. **VAT Handling:** Does the 10% commission include VAT, or is it added on top? (Recommendation: Start with inclusive 10% for simplicity).
2. **Refund Policy:** What happens to the commission if a task is cancelled after payment? (Recommendation: Refund escrow to Poster, don't charge commission).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| eSewa Gateway | Digital Payments | ✓ (UAT) | v2 | — |
| SSL/HTTPS | API Communication | ✓ | — | — |
| Sidekiq/Redis | Background Verification | ✓ | 7.x | Inline processing (slower) |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | RSpec + Capybara |
| Quick run command | `bundle exec rspec spec/services/payments` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command |
|--------|----------|-----------|-------------------|
| PAY-01 | Escrow Deposit | Integration | `rspec spec/requests/payments_spec.rb` |
| PAY-02 | Cash Commission | Unit | `rspec spec/services/ledger_manager_spec.rb` |
| PAY-03 | Fee Calculation | Unit | `rspec spec/services/commission_calculator_spec.rb` |
| PAY-04 | Payout Logic | Integration | `rspec spec/models/payout_request_spec.rb` |

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | Sanitize eSewa callbacks & verify `total_amount` matches DB. |
| V6 Cryptography | yes | HMAC-SHA256 signature verification. |
| V13 API Security | yes | Server-side status checks (never trust client redirect). |

## Sources

### Primary (HIGH confidence)
- [eSewa Developer Portal] - ePay v2 Documentation.
- [double_entry GitHub] - Configuration and transfer logic.
- [sewaLink requirements.md] - Phase 3 goals.

### Secondary (MEDIUM confidence)
- [Marketplace Patterns] - Research on COD commission strategies.

---
**Metadata**
- Research date: 2026-04-14
- Valid until: 2026-05-14
