# Phase 01: Foundation & Identity - Context

**Gathered:** April 13, 2026
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase establishes the foundational identity and access layer for sewaLink. It focuses on localized authentication (SMS OTP primary, email/password secondary), bilingual profile management (Nepali/English), and the initial onboarding flow to prepare users for the marketplace.

</domain>

<decisions>
## Implementation Decisions

### Authentication Strategy
- **D-01:** SMS OTP is the primary entry point for all users.
- **D-02:** Email/password is an optional secondary authentication method that users can set up in their profile after their first phone-based login.
- **D-03:** Use standard Devise-like session management adapted for OTP and Hotwire Native.

### Bilingual Implementation
- **D-04:** Use standard Rails `i18n` with English (`en.yml`) and Nepali (`ne.yml`) locale files.
- **D-05:** A persistent language toggle in the navigation or profile settings.
- **D-06:** Store user's preferred locale in the database to maintain consistency across sessions.

### Profile Management
- **D-07:** Single `User` model with an `active_role` (enum: poster, tasker) and shared fields (name, bio, phone, email, avatar).
- **D-08:** Users can switch their active role via a toggle in the UI, which updates the available navigation and actions.

### Onboarding Flow
- **D-09:** A lightweight post-signup wizard to collect the user's name, preferred language, and initial role (Poster or Tasker).
- **D-10:** Clear progress indicators during the OTP verification and onboarding steps.

### the agent's Discretion
- Selection of specific SMS gateway (e.g., Sparrow SMS, Aakash SMS) for development vs production.
- UI layout for the onboarding wizard (within the provided Hotwire Native constraints).
- Exact design of the profile page components.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Core
- `.planning/PROJECT.md` — Project vision and core values.
- `.planning/REQUIREMENTS.md` — Acceptance criteria for AUTH-01, 02, 04, 05.
- `.planning/ROADMAP.md` — Phase 1 goals and success criteria.

### Technical Research
- `.planning/research/STACK.md` — Recommended Rails 8 + Hotwire Native stack.
- `.planning/research/SUMMARY.md` — Phase 1 implementation suggestions.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None (Greenfield project).

### Established Patterns
- **Rails 8 "Solid Stack"**: Use `Solid Queue` for SMS delivery and `Solid Cache` for OTP codes.

### Integration Points
- Root route will initially serve the onboarding/login experience.

</code_context>

<specifics>
## Specific Ideas
- "Neplish" (colloquial Nepali) should be used for the Nepali translations to feel more natural and accessible.

</specifics>

<deferred>
## Deferred Ideas
- **AUTH-03 (Role-specific profiles)**: Extended fields specific to taskers (e.g., skills, portfolio) are deferred to Phase 2.
- **Government ID Vetting**: Deferred to post-MVP.

</deferred>

---

*Phase: 01-foundation-identity*
*Context gathered: April 13, 2026*
