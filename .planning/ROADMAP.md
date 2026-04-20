# ROADMAP: sewaLink

## Phases

- [x] **Phase 1: Foundation & Identity** - SMS-based authentication and bilingual user profiles. (completed 2026-04-13)
- [x] **Phase 2: Task Marketplace Core** - Task creation, browsing, bidding, and assignment lifecycle. (completed 2026-04-14)
- [x] **Phase 3: Payments & Escrow** - eSewa integration, commission handling, and payouts. (completed 2026-04-14)
- [x] **Phase 4: AI Voice Assistant (Magic Box)** - Voice-to-task creation to lower tech barriers. (completed 2026-04-15)
- [x] **Phase 5: Trust, Safety & Support** - Geofencing, reviews, and secure messaging. (completed 2026-04-17)
- [x] **Phase 6: Task Status & Real-time Updates** - Add task statuses (draft/open) and Hotwire streams for real-time updates. (completed 2026-04-15)
- [ ] **Phase 7: Admin Panel and Analytics** - Admin dashboard for platform oversight and growth analytics.
- [ ] **Phase 8: Real-time AI Chat (Gemini Live)** - Replace magic box with true streaming bidirectional AI chat for task creation.

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
- [ ] 07-04-PLAN.md — Implement task oversight and dispute resolution tools.

### Phase 8: Real-time AI Chat (Gemini Live)
**Goal**: Advanced conversational task creation.
**Requirements**: SAFE-03
**Success Criteria**:
  1. Bidirectional streaming AI chat for task setup.
