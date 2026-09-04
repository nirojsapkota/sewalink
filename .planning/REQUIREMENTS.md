# REQUIREMENTS: sewaLink (v1)

## Core Value
A mobile-first, trust-focused service marketplace for Nepal, lowering the tech barrier with AI voice assistance and secure localized payments.

## v1 Requirements

### Authentication & Profiles (AUTH)
- [x] **AUTH-01**: User can log in/sign up using Phone Number (SMS OTP). (Default)
- [x] **AUTH-02**: User can toggle to Email/Password login from the UI.
- [x] **AUTH-03**: Dual-profile system: Users can switch between 'Poster' and 'Tasker' roles.
- [x] **AUTH-04**: Bilingual UI toggle: Support for both Nepali and English languages.
- [x] **AUTH-05**: Profile management: Name, profile picture, and bio.

### Task Management (TASK)
- [x] **TASK-01**: Poster can create a task with title, description, budget, and location.
- [x] **TASK-02**: **AI Magic Box**: Poster can record a voice note to auto-generate a task.
- [x] **TASK-03**: Rich Listings: Support for adding photos to task descriptions.
- [x] **TASK-04**: Browsing & Filters: Taskers can browse tasks by category, budget, and location.
- [x] **TASK-05**: Bidding: Taskers can place bids with custom amounts and messages.
- [x] **TASK-06**: Assignment: Posters can review bids and assign a tasker.
- [x] **TASK-07**: **Lifecycle Statuses**: Granular task statuses (draft, open, in_progress, pending_payment, completed, dispute).
- [x] **TASK-08**: **Real-time Updates**: Instant UI synchronization via Hotwire Turbo Streams for bids and status changes.
- [x] **TASK-09**: **Poster Dashboard**: Centralized management of tasks with status-based filtering.

### Payments & Commission (PAY)
- [x] **PAY-01**: **eSewa Escrow**: Support for secure digital payment deposits.
- [x] **PAY-02**: **Cash Support**: Option for Posters to pay Taskers directly on-site.
- [x] **PAY-03**: **Commission Module**: Automatically calculate and track platform fees (charged to taskers).
- [x] **PAY-04**: Payouts: Taskers can request withdrawals of their earned balance.

### Trust & Safety (SAFE)
- [x] **SAFE-01**: **Geofencing**: Taskers must be within a set perimeter of the job to mark it as 'Done'.
- [x] **SAFE-02**: **Social Trust**: Mutual ratings and reviews after task completion.
- [x] **SAFE-03**: **AI Support Center**: Advanced conversational task creation and support via Gemini Live.
- [x] **SAFE-04**: Evidence Submission: Ability to upload photos/videos for dispute resolution.
- [x] **SAFE-05**: **In-App Messaging**: Private 1-to-1 chat between Poster and Bidders.
- [x] **SAFE-06**: **Contact Masking**: Hide phone numbers and emails until task assignment.

### Admin Panel (ADMIN)
- [x] **ADMIN-01**: Admin can view platform growth metrics (Users, Tasks, GMV) via interactive charts.
- [x] **ADMIN-02**: Admin can view all users and their activity stats.
- [x] **ADMIN-03**: Admin can oversee all task lifecycles.
- [x] **ADMIN-04**: Admin can resolve disputes by releasing/refunding escrow funds.
- [x] **ADMIN-05**: Admin can manage full user lifecycle: edit profile fields, suspend/reactivate accounts, and change role/admin status.
- [x] **ADMIN-06**: Admin can override task management: edit task details and force-cancel tasks outside normal lifecycle.
- [x] **ADMIN-07**: Admin can view all bids platform-wide and manually accept/reject/cancel bids for dispute resolution.
- [x] **ADMIN-08**: Admin has full CRUD over task categories including reordering and safe deletion.
- [x] **ADMIN-09**: Admin can moderate users via suspension tooling (basic moderation; no separate content-flagging system exists).
- [x] **ADMIN-10**: Admin can view escrow/revenue balances and configure the platform commission rate without console access.
- [x] **ADMIN-11**: Admin can resolve disputes with split-payment or reopen-task options in addition to release/refund.

---

## v1.1 Requirements (Milestone: Admin Accounting & Cash Flow Visibility)

### Access Control (ADMIN)
- [ ] **ADMIN-12**: Replace boolean `admin` flag with role-based access (via `rolify`) — roles: `super_admin`, `accountant`. Only users with an admin-capable role can access `/admin`.
- [ ] **ADMIN-13**: Super admin can assign/revoke roles for other admin users.

### Cash Flow Dashboard (ACCT)
- [ ] **ACCT-01**: Admin can view a cash flow dashboard summarizing inflows/outflows by type (escrow deposits, releases, commission revenue, refunds, cash-on-completion) for a selected period.
- [ ] **ACCT-02**: Admin can drill into a summary category to see the contributing transactions.

### Transaction Ledger (ACCT)
- [ ] **ACCT-03**: Admin can view a searchable/filterable ledger of all DoubleEntry transactions (by date range, user, account type, transaction type).
- [ ] **ACCT-04**: Admin can view details of a single ledger transaction, including linked task/dispute/user.

### Period Reports (ACCT)
- [ ] **ACCT-05**: Admin can view daily/monthly summary reports (revenue, commission earned, refunds issued, net platform revenue).

### Reconciliation (ACCT)
- [ ] **ACCT-06**: Admin can view/flag discrepancies between eSewa settlement records and internal escrow ledger balances.

---

## v2 Requirements (Deferred)
- [ ] **AUTH-06**: Social Vouching (Community verification).
- [ ] **AUTH-07**: Government ID (Nagarpalika/National ID) vetting.
- [ ] **PAY-05**: Multi-wallet support (Khalti, IME Pay).
- [ ] **PAY-06**: Subscription model for power taskers.

---

## Traceability

| REQ-ID | Phase | Status |
|--------|-------|--------|
| AUTH-01 | Phase 1 | Complete |
| AUTH-02 | Phase 1 | Complete |
| AUTH-03 | Phase 2 | Complete |
| AUTH-04 | Phase 1 | Complete |
| AUTH-05 | Phase 1 | Complete |
| TASK-01 | Phase 2 | Complete |
| TASK-02 | Phase 4 | Complete |
| TASK-03 | Phase 2 | Complete |
| TASK-04 | Phase 2 | Complete |
| TASK-05 | Phase 2 | Complete |
| TASK-06 | Phase 2 | Complete |
| TASK-07 | Phase 6 | Complete |
| TASK-08 | Phase 6 | Complete |
| TASK-09 | Phase 6 | Complete |
| PAY-01 | Phase 3 | Complete |
| PAY-02 | Phase 3 | Complete |
| PAY-03 | Phase 3 | Complete |
| PAY-04 | Phase 3 | Complete |
| SAFE-01 | Phase 5 | Complete |
| SAFE-02 | Phase 5 | Complete |
| SAFE-03 | Phase 8 | Complete |
| SAFE-04 | Phase 5 | Complete |
| SAFE-05 | Phase 5 | Complete |
| SAFE-06 | Phase 5 | Complete |
| ADMIN-01 | Phase 7 | Complete |
| ADMIN-02 | Phase 7 | Complete |
| ADMIN-03 | Phase 7 | Complete |
| ADMIN-04 | Phase 7 | Complete |
| ADMIN-05 | Phase 9 | Complete |
| ADMIN-06 | Phase 9 | Complete |
| ADMIN-07 | Phase 9 | Complete |
| ADMIN-08 | Phase 9 | Complete |
| ADMIN-09 | Phase 9 | Complete |
| ADMIN-10 | Phase 9 | Complete |
| ADMIN-11 | Phase 9 | Complete |
| ADMIN-12 | Phase 10 | Planned |
| ADMIN-13 | Phase 10 | Planned |
| ACCT-01 | Phase 10 | Planned |
| ACCT-02 | Phase 10 | Planned |
| ACCT-03 | Phase 10 | Planned |
| ACCT-04 | Phase 10 | Planned |
| ACCT-05 | Phase 10 | Planned |
| ACCT-06 | Phase 10 | Planned |
