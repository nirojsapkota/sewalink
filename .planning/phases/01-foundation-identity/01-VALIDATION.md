# VALIDATION: sewaLink (Phase 01)

**Phase:** 01 - Foundation & Identity
**Date:** April 13, 2026
**Framework:** Minitest (Rails default)

## Validation Strategy

This phase validates the core identity and access layer. We focus on ensuring secure SMS OTP authentication, bilingual UI switching, and correct profile data persistence using Rails 8 patterns.

## Requirement Verification (Dimension 8)

| REQ-ID | Description | Verification Method | Automated Command |
|--------|-------------|---------------------|-------------------|
| **AUTH-01** | SMS OTP Signup/Login | Integration Test | `bin/rails test test/integration/auth_flow_test.rb` |
| **AUTH-02** | Email/Password Toggle | Integration Test | `bin/rails test test/integration/auth_strategies_test.rb` |
| **AUTH-04** | Bilingual UI Toggle | System Test | `bin/rails test test/system/language_toggle_test.rb` |
| **AUTH-05** | Profile Management | Integration Test | `bin/rails test test/models/user_profile_test.rb` |

## Success Criteria (Goal-Backward)

These must be TRUE for the phase to be considered complete:

1. [ ] **SMS OTP Flow**: A user can enter a 10-digit Nepali phone number, receive a simulated/real OTP, and successfully log in.
2. [ ] **Bilingual Toggle**: Toggling language immediately updates UI text and persists the preference in the `User` model.
3. [ ] **Onboarding Wizard**: New users are redirected to a 3-step wizard (Name, Language, Role) before entering the app.
4. [ ] **Role Persistence**: Switching between 'Poster' and 'Tasker' updates the `active_role` enum and is reflected in the UI.

## Security & Compliance (ASVS L1)

| Control | Description | Validation |
|---------|-------------|------------|
| **V2.1.1** | Verify all authentication paths | `bin/rails test test/integration/auth_flow_test.rb` |
| **V2.1.2** | Verify OTP expiry and lockout | `bin/rails test test/models/otp_verification_test.rb` |
| **V5.1.1** | Verify input validation (Phone/Email) | `bin/rails test test/models/user_validation_test.rb` |

## Performance & Infrastructure

- [ ] **Solid Queue**: Verify background job processing for SMS delivery (`bin/rails solid_queue:status`).
- [ ] **Solid Cache**: Verify OTP codes are stored and retrieved correctly from the cache.
- [ ] **Typography**: Manual check of `Mukta` font rendering on mobile views to ensure no matra clipping.

---
*Created: April 13, 2026*
