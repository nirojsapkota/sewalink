# ROADMAP: sewaLink

## Phases

- [x] **Phase 1: Foundation & Identity** - SMS-based authentication and bilingual user profiles. (completed 2026-04-13)
- [x] **Phase 2: Task Marketplace Core** - Task creation, browsing, bidding, and assignment lifecycle. (completed 2026-04-14)
- [x] **Phase 3: Payments & Escrow** - eSewa integration, commission handling, and payouts. (completed 2026-04-14)
- [x] **Phase 4: AI Voice Assistant (Magic Box)** - Voice-to-task creation to lower tech barriers. (completed 2026-04-15)
- [x] **Phase 5: Trust, Safety & Support** - Geofencing, reviews, and secure messaging. (completed 2026-04-17)
- [x] **Phase 6: Task Status & Real-time Updates** - Add task statuses (draft/open) and Hotwire streams for real-time updates. (completed 2026-04-15)
- [x] **Phase 7: Admin Panel and Analytics** - Admin dashboard for platform oversight and growth analytics. (completed 2026-04-20)
- [x] **Phase 8: Real-time AI Chat (Gemini Live)** - Replace magic box with true streaming bidirectional AI chat for task creation. (completed 2026-04-20)
- [x] **Phase 9: Complete Admin Panel** - Full super-admin operations across users, tasks, bids, categories, disputes, and settings. (completed 2026-05-XX)
- [x] **Phase 10: Admin Role-Based Access Control** - Replace boolean admin flag with rolify-based super_admin/accountant roles. (completed 2026-09-04)
- [ ] **Phase 11: Cash Flow Accounting & Reconciliation** - Cash flow dashboard, ledger drill-down, period reports, and eSewa reconciliation.

## Phase Details

### Phase 1: Foundation & Identity
**Goal**: Establish the basic identity system and multi-lingual foundation.
**Requirements**: AUTH-01, AUTH-02, AUTH-04, AUTH-05
**Success Criteria**:
  1. User can register/login with phone + OTP.
  2. User can toggle between English and Nepali.
  3. Profile information persists.

### Phase 2: Task Marketplace Core
**Goal**: Enable the primary marketplace interaction.
**Requirements**: AUTH-03, TASK-01, TASK-03, TASK-04, TASK-05, TASK-06
**Success Criteria**:
  1. User can switch roles (Poster/Tasker).
  2. Poster can create tasks with images.
  3. Tasker can bid on tasks.
  4. Poster can assign a tasker.

### Phase 3: Payments & Escrow
**Goal**: Secure financial transactions and commission tracking.
**Requirements**: PAY-01, PAY-02, PAY-03, PAY-04
**Success Criteria**:
  1. eSewa integration handles deposits.
  2. Commission is automatically deducted from tasker balance.
  3. Tasker can request payouts.

### Phase 4: AI Voice Assistant (Magic Box)
**Goal**: Lower the barrier to entry with voice-to-task technology.
**Requirements**: TASK-02
**Success Criteria**:
  1. User can record voice to create a task.
  2. AI extracts title, description, and budget from voice.

### Phase 5: Trust, Safety & Support
**Goal**: Ensure job quality, verify completion, and provide a safety net for users.
**Depends on**: Phase 3
**Requirements**: SAFE-01, SAFE-02, SAFE-04, SAFE-05, SAFE-06
**Success Criteria** (what must be TRUE):
  1. Tasker can only mark a task as 'Done' when they are within the geofenced perimeter of the task location.
  2. Both parties can leave ratings and text reviews for each other after a task is completed.
  3. In-app messaging protects user privacy through content filtering and contact masking.

### Phase 6: Task Status & Real-time Updates
**Goal**: Improve transparency and responsiveness of the marketplace.
**Requirements**: TASK-07, TASK-08, TASK-09
**Success Criteria**:
  1. Granular task statuses (draft, open, in_progress, etc.) are tracked.
  2. UI updates in real-time when bids are placed or status changes.
  3. Poster has a dedicated dashboard for task management.

### Phase 7: Admin Panel and Analytics
**Goal**: Provide tools for platform oversight, financial auditing, and growth tracking.
**Requirements**: ADMIN-01, ADMIN-02, ADMIN-03, ADMIN-04
**Success Criteria**:
  1. Admin can view platform growth metrics (Users, Tasks, GMV) via interactive charts.
  2. Admin can manage all users and oversee all task lifecycles.
  3. Admin can resolve disputes by reviewing evidence and releasing/refunding escrow funds.
**Plans**: 4 plans
- [x] 07-01-PLAN.md — Bootstrap admin infrastructure, analytics dependencies, and base testing.
- [x] 07-02-PLAN.md — Implement growth analytics dashboard with Chartkick.
- [x] 07-03-PLAN.md — Implement User Management interface for administrators.
- [x] 07-04-PLAN.md — Implement task oversight and dispute resolution tools.

### Phase 8: Real-time AI Chat (Gemini Live)
**Goal**: Advanced conversational task creation.
**Requirements**: SAFE-03
**Success Criteria**:
  1. Bidirectional streaming AI chat for task setup.
**Plans**: 3 plans
- [x] 08-01-PLAN.md — Bootstrap real-time AI infrastructure (Gemini Live Proxy).
- [x] 08-02-PLAN.md — Implement tool execution and dynamic UI updates via Turbo Streams.
- [x] 08-03-PLAN.md — Final polish: Fix bubble styling, secure real-time unmasking, and v1.0 state documentation.

### Phase 9: Complete admin panel: full super admin operations beyond user listing (manage users, tasks, bids, categories, disputes, moderation, settings)

**Goal**: Extend the admin panel from read-only user listing to full super-admin operations across users, tasks, bids, categories, disputes, and platform settings — no Rails console required for routine platform administration.
**Requirements**: ADMIN-05, ADMIN-06, ADMIN-07, ADMIN-08, ADMIN-09, ADMIN-10, ADMIN-11
**Depends on:** Phase 8
**Success Criteria**:
  1. Admin can edit, suspend/reactivate, and change the role of any user account.
  2. Admin can override task details and force-cancel tasks outside their normal lifecycle, with safe escrow handling.
  3. Admin can view and manually accept/reject/cancel bids platform-wide.
  4. Admin has full CRUD (create/edit/delete/reorder) over task categories, protected against deleting in-use categories.
  5. Admin can resolve disputes via release, refund, split-by-percentage, or reopen — all four options.
  6. Admin can view escrow/revenue balances and edit the platform commission rate from the UI.
**Plans:** 7/7 plans complete

Plans:
- [x] 09-01-PLAN.md — Foundation: schema, Task state-machine additions, PlatformSetting/AdminActivityLog models, all new admin routes, nav links.
- [x] 09-02-PLAN.md — User management: edit/suspend/reactivate/role-change (moderation via suspension).
- [x] 09-03-PLAN.md — Task management override: admin edit + force-cancel with escrow refund.
- [x] 09-04-PLAN.md — Bid management: platform-wide bid oversight with accept/reject/cancel.
- [x] 09-05-PLAN.md — Category management: full CRUD + reordering with FK-safety.
- [x] 09-06-PLAN.md — Settings & financial oversight: commission rate config, escrow/revenue visibility.
- [x] 09-07-PLAN.md — Dispute resolution enhancements: split-payment and reopen-task options.

### Phase 10: Admin Role-Based Access Control
**Goal**: Replace the boolean `admin` flag with granular, assignable roles (`super_admin`, `accountant`) via `rolify`, so admin-panel access and future permission scoping are role-driven instead of a single boolean.
**Depends on**: Phase 9
**Requirements**: ADMIN-12, ADMIN-13
**Success Criteria** (what must be TRUE):
  1. Only users holding an admin-capable role (`super_admin` or `accountant`) can access `/admin`; users without one of these roles are denied access.
  2. All users previously flagged `admin: true` are migrated to hold the `super_admin` role with no loss of existing access.
  3. A super admin can view all admin-role users and assign or revoke the `super_admin` or `accountant` role for any user via the admin UI.
  4. A user with only the `accountant` role cannot assign or revoke roles for other users (role management is `super_admin`-only).
**Plans**: 2 plans
Plans:
- [x] 10-01-PLAN.md — Install rolify, migrate schema, data-migrate admin:true users to super_admin, gate /admin access on roles.
- [x] 10-02-PLAN.md — Super-admin-only role management UI: view admin-role users, assign/revoke super_admin/accountant, replace legacy change_role.

### Phase 11: Cash Flow Accounting & Reconciliation
**Goal**: Give admins (super admin and accountant) full visibility into platform cash flows using the existing double_entry ledger — dashboard summaries, transaction-level drill-down, period reports, and eSewa reconciliation.
**Depends on**: Phase 10
**Requirements**: ACCT-01, ACCT-02, ACCT-03, ACCT-04, ACCT-05, ACCT-06
**Success Criteria** (what must be TRUE):
  1. Admin can view a cash flow dashboard summarizing inflows/outflows by type (escrow deposits, releases, commission revenue, refunds, cash-on-completion) for a selected date range, and drill into any category to see its contributing transactions.
  2. Admin can search and filter the full DoubleEntry transaction ledger by date range, user, account type, and transaction type.
  3. Admin can open a single ledger transaction and see its linked task, dispute, and user context.
  4. Admin can view daily/monthly summary reports showing revenue, commission earned, refunds issued, and net platform revenue.
  5. Admin can import/view an eSewa settlement record and see discrepancies flagged against the internal escrow ledger balance for the same period.
**Plans**: 5 plans

Plans:
- [x] 11-01-PLAN.md — Foundation: routes, nav, subnav partial, shared CashFlowCategorizer/LedgerQuery services, AccountingHelper.
- [ ] 11-02-PLAN.md — Cash flow dashboard + category drill-down.
- [ ] 11-03-PLAN.md — Transaction ledger search/filter + single-transaction detail (task/user/dispute context).
- [ ] 11-04-PLAN.md — Daily/monthly period reports (commission, refunds, net revenue).
- [ ] 11-05-PLAN.md — eSewa settlement CSV import + reconciliation matching + final phase checkpoint.
