# Project Research Summary

**Project:** sewaLink
**Domain:** Service Marketplace (Nepal Context)
**Researched:** 2024-05-24
**Confidence:** HIGH

## Executive Summary

sewaLink is a localized service marketplace for Nepal, designed to bridge the gap between skilled workers (taskers) and households/businesses. Experts build such platforms using a robust monolith with real-time communication and state-managed task lifecycles. For the Nepal market, a mobile-first approach is critical, requiring lightweight clients and deep integration with local payment providers like eSewa and SMS gateways for identity.

The recommended approach uses Ruby on Rails with Hotwire Native to minimize development overhead while providing a high-quality mobile experience. A key innovation is the AI "Magic Box," which uses voice-to-task processing (Whisper/GPT) to accommodate users with varying tech literacy. Trust is established through a digital escrow system and geofenced task completion verification.

The primary risks include platform leakage (users bypassing the platform), payment verification fraud, and SMS delivery inconsistencies across local carriers. Mitigation involves low-friction escrow incentives, server-to-server payment validation, and using reputable local SMS providers with fallback mechanisms.

## Key Findings

### Recommended Stack

The stack focuses on developer productivity and local performance. Using a Rails monolith allows for rapid iteration of complex business logic like payments and state management.

**Core technologies:**
- **Ruby on Rails 7.1+**: Backend & API — Industry standard for rapid development and state management.
- **Hotwire Native**: Mobile App Wrapper — Allows building iOS/Android apps using the same Rails views, reducing codebase fragmentation.
- **PostgreSQL + PostGIS**: Primary DB & Spatial — Essential for distance-based task matching and geofencing.
- **OpenAI Whisper/GPT**: AI Voice & NLP — Lowers onboarding friction for non-tech-literate users through voice-to-task conversion.
- **eSewa SDK/API**: Payment — The dominant digital wallet in Nepal for escrow and settlements.

### Expected Features

**Must have (table stakes):**
- **SMS OTP Login** — standard for Nepal's mobile-first user base.
- **Task Posting/Bidding** — core marketplace functionality.
- **Chat Messaging** — coordination between users.
- **eSewa Integration** — essential for digital payments.

**Should have (competitive):**
- **AI Magic Box (Voice-to-Task)** — addresses low tech literacy.
- **Digital Escrow** — guarantees payment and builds trust.
- **Geofencing** — prevents fraudulent task completion claims.

**Defer (v2+):**
- **Full KYC** — high friction for initial onboarding.
- **In-app Navigation** — deep link to Google Maps instead.
- **International Cards** — low penetration in Nepal market.

### Architecture Approach

The system follows a modular monolith architecture using Service Objects to isolate complex integrations (Payments, AI) and state machines to manage the task lifecycle reliably.

**Major components:**
1. **Task Engine** — Manages the lifecycle (Draft -> Posted -> Assigned -> Completed -> Paid).
2. **Escrow Service** — Orchestrates eSewa payments and split settlements (Tasker payout vs Commission).
3. **AI Assistant Service** — Processes voice uploads via S3/Whisper to auto-populate task drafts.
4. **Identity Service** — Handles phone-based auth and Sparrow SMS integration.

### Critical Pitfalls

1. **Platform Leakage** — Users going offline to avoid fees. Avoid by offering escrow protection and low initial commissions.
2. **eSewa Signature Spoofing** — Attackers faking payment success. Avoid by mandatory server-to-server status verification.
3. **SMS Delivery Reliability** — OTP failures on local carriers. Avoid by using high-quality local gateways (Sparrow SMS).
4. **Location Accuracy** — GPS noise in Nepal. Avoid by allowing a flexible geofence radius (200m).

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: MVP Core & Onboarding
**Rationale:** Establishes the primary value loop (Post -> Bid -> Complete) and user identity.
**Delivers:** SMS Login, Task Posting, Bidding, and basic Review system.
**Addresses:** SMS OTP, Task Posting, Bidding from FEATURES.md.
**Avoids:** SMS Reliability pitfalls.

### Phase 2: Payment & Secure Escrow
**Rationale:** Necessary for monetization and building trust via guaranteed payments.
**Delivers:** eSewa integration, platform fee collection, and basic escrow logic.
**Uses:** eSewa API, Service Objects for Payments from STACK.md.
**Implements:** Escrow Service component from ARCHITECTURE.md.

### Phase 3: AI Magic Box (Voice-to-Task)
**Rationale:** Major differentiator to capture the non-tech-literate segment.
**Delivers:** Voice recording, Whisper STT, and automated task draft creation.
**Uses:** OpenAI Whisper/GPT, Sidekiq, AWS S3.
**Avoids:** STT failing on local accents pitfall (by allowing manual correction).

### Phase 4: Trust & Verification (Geofencing)
**Rationale:** Enhances reliability for high-value tasks and prevents fraud.
**Delivers:** Geofence validation for task completion and advanced reviews.
**Uses:** PostGIS, RGeo, GPS tracking.
**Avoids:** Location Accuracy pitfalls.

### Phase Ordering Rationale

- **Core First:** Identity and task posting are the foundation for any marketplace data.
- **Payments Second:** Digital escrow is a complex legal and technical hurdle that needs early validation.
- **AI Later:** While a differentiator, it's an enhancement to the core form-based posting.
- **Geofencing Last:** High complexity for verification, can be handled manually in early beta.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2 (Payments):** Needs deep research into eSewa ePay v2 API, signature verification, and NRB compliance for escrow.
- **Phase 3 (AI):** Needs research on Whisper accuracy for Nepali language and NLP prompt engineering for task extraction.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Core):** Well-documented Rails marketplace patterns.
- **Phase 4 (Geofencing):** Established PostGIS/RGeo patterns for distance checks.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Standard Rails/Hotwire Native patterns are well-proven. |
| Features | HIGH | Well-mapped to Nepal market needs (Airtasker + local context). |
| Architecture | HIGH | Service-oriented monolith with state machines is the correct pattern. |
| Pitfalls | MEDIUM-HIGH | Local context pitfalls identified, but carrier reliability varies. |

**Overall confidence:** HIGH

### Gaps to Address

- **Legal Compliance:** Need to verify Nepal Rastra Bank (NRB) regulations for split-payment escrow during Phase 2 planning.
- **SMS Costs:** Balancing OTP costs with user acquisition (unit economics).

## Sources

### Primary (HIGH confidence)
- Rails Hotwire Documentation — Mobile app strategy.
- eSewa Developer Documentation — Payment integration.
- PostGIS Official Docs — Geospatial logic.

### Secondary (MEDIUM confidence)
- Nepal FinTech Ecosystem Analysis 2023 — Payment landscape.
- OpenAI Whisper API Docs — Voice processing capabilities.

### Tertiary (LOW confidence)
- Local Developer Community Discussions — SMS gateway reliability reports.

---
*Research completed: 2024-05-24*
*Ready for roadmap: yes*
