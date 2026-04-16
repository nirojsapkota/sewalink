# PROJECT: sewaLink

## What This Is
A mobile-first marketplace platform tailored for the Nepali market that connects individuals needing small tasks done with local service providers (taskers). Built with **Ruby on Rails and Hotwire Native**, it aims to bridge the gap in Nepal's service economy by prioritizing trust, simplicity, and low-tech accessibility.

## Core Value
To provide a reliable, culturally-adapted, and AI-enhanced platform where Nepalis can easily outsource tasks and taskers can find secure work opportunities with guaranteed payments.

## Context
The platform is inspired by Airtasker but adapted for Nepal's unique infrastructure, including eSewa integration, bilingual support (Nepali/English), and AI voice assistance to lower the barrier to entry for users with varying levels of tech literacy.

## Requirements

### Validated
(None yet — ship to validate)

### Active
- [ ] **Bilingual Interface**: Support for both Nepali and English with a quick toggle.
- [ ] **AI Voice Assistant**: In-app "Magic Box" with a mic button for voice-to-task creation and support.
- [ ] **Payment System**: Integrated eSewa for digital escrow (primary) and support for Cash-on-Completion.
- [ ] **Commission Module**: System to charge taskers a fee for platform usage.
- [ ] **Geofencing**: Location-based validation ensuring taskers complete jobs within a set perimeter of the poster.
- [ ] **Tasker Vetting**: Simple phone-number-based verification for initial launch.
- [ ] **Support & Disputes**: AI-assisted chat + direct customer support with evidence submission capabilities.
- [ ] **Hotwire Native**: Optimized for mobile app generation from the Rails codebase.

### Out of Scope
- [ ] **International Payments**: Focus is strictly on the Nepali market (eSewa/Khalti/Cash).
- [ ] **Advanced Vetting**: Government ID (Nagarpalika/National ID) is deferred for post-MVP.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Ruby on Rails + Hotwire Native | Rapid development and seamless mobile app integration. | — Pending |
| eSewa Primary Payment | Most widely used digital wallet in Nepal. | — Pending |
| Tasker-only Commission | Encourages users to post tasks without friction. | — Pending |
| Geofencing for Completion | Prevents fraudulent "completed" marks when taskers aren't on-site. | — Pending |

## Evolution
This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: April 13, 2026 after initialization*
