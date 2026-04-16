# Phase 01: Foundation & Identity - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** April 13, 2026
**Phase:** 1-Foundation & Identity
**Areas discussed:** Authentication Strategy, Bilingual Implementation, Profile Management, Onboarding Flow

---

## Authentication Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Phone-only signup | Users sign up only with phone; email/password is for existing users | |
| Hybrid signup | Users can choose phone or email/password at the start | |
| Profile-linked secondary auth | Users sign up with phone; add email/password later in profile | ✓ |

**User's choice:** [auto] Profile-linked secondary auth (Recommended default)
**Notes:** Ensures low friction for the primary Nepali audience while providing flexibility for power users.

---

## Bilingual Implementation

| Option | Description | Selected |
|--------|-------------|----------|
| Rails i18n | Standard YAML-based translation system | ✓ |
| Dynamic Database | Store all UI text in the database for runtime updates | |

**User's choice:** [auto] Rails i18n (Recommended default)
**Notes:** Most stable and performant approach for a Rails application.

---

## Profile Management

| Option | Description | Selected |
|--------|-------------|----------|
| Single User model | Role toggle on a single model | ✓ |
| Multi-table Roles | Separate tables for Posters and Taskers | |

**User's choice:** [auto] Single User model (Recommended default)
**Notes:** Simplifies the MVP while allowing for role switching.

---

## Onboarding Flow

| Option | Description | Selected |
|--------|-------------|----------|
| Post-signup Wizard | Step-by-step collection of profile data | ✓ |
| Just-in-time | Ask for data only when the user tries to perform an action | |

**User's choice:** [auto] Post-signup Wizard (Recommended default)
**Notes:** Ensures a complete profile before entering the marketplace.

---

## the agent's Discretion
- Choice of SMS gateway.
- Onboarding UI layout.
- Profile page component design.

## Deferred Ideas
- Tasker-specific skill fields (Phase 2).
- Government ID vetting (post-MVP).
