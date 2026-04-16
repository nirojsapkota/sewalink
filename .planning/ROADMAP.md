# ROADMAP: sewaLink

## Phases

- [ ] **Phase 1: Foundation & Identity** - SMS-based authentication and bilingual user profiles.
- [ ] **Phase 2: Task Marketplace Core** - Task creation, browsing, bidding, and assignment lifecycle.
- [ ] **Phase 3: Payments & Escrow** - eSewa integration, commission handling, and payouts.
- [ ] **Phase 4: AI Voice Assistant (Magic Box)** - Voice-to-task creation to lower tech barriers.
- [ ] **Phase 5: Trust, Safety & Support** - Geofencing, reviews, and AI-assisted dispute resolution.

## Phase Details

### Phase 1: Foundation & Identity
**Goal**: Users can securely register and manage their bilingual profiles.
**Depends on**: Nothing
**Requirements**: AUTH-01, AUTH-02, AUTH-04, AUTH-05
**Success Criteria** (what must be TRUE):
  1. User can sign up and log in using a phone number and SMS OTP.
  2. User can toggle the entire interface between Nepali and English languages.
  3. User can update their profile information (name, bio, picture).
  4. User can optionally log in with email/password after initial setup.
**Plans**: 3 plans
- [ ] 01-01-PLAN.md — Initialize Rails app and establish bilingual foundation.
- [ ] 01-02-PLAN.md — Implement core SMS OTP and secondary email authentication.
- [ ] 01-03-PLAN.md — Implement user profiles and onboarding wizard.
**UI hint**: yes

### Phase 2: Task Marketplace Core
**Goal**: Users can post, browse, and assign tasks to build the core marketplace loop.
**Depends on**: Phase 1
**Requirements**: AUTH-03, TASK-01, TASK-03, TASK-04, TASK-05, TASK-06
**Success Criteria** (what must be TRUE):
  1. User can switch between 'Poster' and 'Tasker' roles.
  2. Poster can create a rich task listing with title, description, budget, location, and photos.
  3. Tasker can browse and filter tasks by category, budget, and proximity.
  4. Tasker can place a bid on a task, and Poster can assign the task to a chosen bidder.
**Plans**: TBD
**UI hint**: yes

### Phase 3: Payments & Escrow
**Goal**: Secure digital payments and automated platform monetization.
**Depends on**: Phase 2
**Requirements**: PAY-01, PAY-02, PAY-03, PAY-04
**Success Criteria** (what must be TRUE):
  1. Poster can securely deposit funds into escrow using eSewa.
  2. Platform automatically calculates and tracks commission fees for every digital transaction.
  3. Tasker can view their earned balance and request payouts.
  4. Poster and Tasker can agree on and record Cash-on-Completion payments.
**Plans**: TBD
**UI hint**: yes

### Phase 4: AI Voice Assistant (Magic Box)
**Goal**: Lower the barrier to entry for non-tech-literate users through voice-to-task automation.
**Depends on**: Phase 2
**Requirements**: TASK-02
**Success Criteria** (what must be TRUE):
  1. User can record a voice note in the app to describe a task.
  2. System automatically extracts task details (title, description, budget) and creates a draft.
  3. User can review the AI-generated draft and publish the task.
**Plans**: TBD
**UI hint**: yes

### Phase 5: Trust, Safety & Support
**Goal**: Ensure job quality, verify completion, and provide a safety net for users.
**Depends on**: Phase 3
**Requirements**: SAFE-01, SAFE-02, SAFE-03, SAFE-04
**Success Criteria** (what must be TRUE):
  1. Tasker can only mark a task as 'Done' when they are within the geofenced perimeter of the task location.
  2. Both parties can leave ratings and text reviews for each other after a task is completed.
  3. User can access an AI-assisted support chat for immediate help.
  4. User can upload photos or videos as evidence during a dispute resolution process.
**Plans**: TBD
**UI hint**: yes

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & Identity | 0/3 | Not started | - |
| 2. Task Marketplace Core | 0/0 | Not started | - |
| 3. Payments & Escrow | 0/0 | Not started | - |
| 4. AI Voice Assistant (Magic Box) | 0/0 | Not started | - |
| 5. Trust, Safety & Support | 0/0 | Not started | - |
