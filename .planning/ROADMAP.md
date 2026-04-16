# ROADMAP: sewaLink

## Phases

- [x] **Phase 1: Foundation & Identity** - SMS-based authentication and bilingual user profiles. (completed 2026-04-13)
- [x] **Phase 2: Task Marketplace Core** - Task creation, browsing, bidding, and assignment lifecycle. (completed 2026-04-14)
- [x] **Phase 3: Payments & Escrow** - eSewa integration, commission handling, and payouts. (completed 2026-04-14)
- [x] **Phase 4: AI Voice Assistant (Magic Box)** - Voice-to-task creation to lower tech barriers. (completed 2026-04-15)
- [ ] **Phase 5: Trust, Safety & Support** - Geofencing, reviews, and secure messaging.
- [x] **Phase 6: Task Status & Real-time Updates** - Add task statuses (draft/open) and Hotwire streams for real-time updates. (completed 2026-04-15)
- [ ] **Phase 7: Admin Panel and Analytics** - Admin dashboard for platform oversight and growth analytics.
- [ ] **Phase 8: Real-time AI Chat (Gemini Live)** - Replace magic box with true streaming bidirectional AI chat for task creation.

## Phase Details

... (Phase 1-4) ...

### Phase 5: Trust, Safety & Support
**Goal**: Ensure job quality, verify completion, and provide a safety net for users.
**Depends on**: Phase 3
**Requirements**: SAFE-01, SAFE-02, SAFE-04, SAFE-05, SAFE-06
**Success Criteria** (what must be TRUE):
  1. Tasker can only mark a task as 'Done' when they are within the geofenced perimeter of the task location.
  2. Both parties can leave ratings and text reviews for each other after a task is completed.
  3. In-app messaging protects user privacy through content filtering and contact masking.
**Plans**: 7 plans
- [ ] 05-00-PLAN.md — Bootstrap Phase 5 testing infrastructure for Nyquist compliance.
- [ ] 05-01-PLAN.md — Implement geofencing model logic and mandatory completion photo.
- [ ] 05-01.1-PLAN.md — Implement geolocation Stimulus controller and UI status indicators.
- [ ] 05-02-PLAN.md — Implement a blind review system for biased-free feedback.
- [ ] 05-03-PLAN.md — Establish secure messaging infrastructure with PII filtering.
- [ ] 05-04-PLAN.md — Implement real-time messaging UI with Turbo Streams.
- [ ] 05-05-PLAN.md — Implement contact masking UI and dispute evidence submission.
**UI hint**: yes

... (Phase 6-8) ...
