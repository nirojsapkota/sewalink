---
phase: 01-foundation-identity
verified: 2026-04-14T01:30:00Z
status: gaps_found
score: 11/12 must-haves verified
overrides_applied: 0
gaps:
  - truth: "OTP requests are rate-limited"
    status: failed
    reason: "Rack::Attack configuration uses incorrect paths and parameter names, allowing complete bypass of rate limiting."
    artifacts:
      - path: "config/initializers/rack_attack.rb"
        issue: "Throttles '/users/send_otp' (non-existent) and looks for top-level 'phone' param instead of 'user[phone]'."
    missing:
      - "Correct paths and parameter parsing in Rack::Attack initializer."
  - truth: "OTP authentication is reliable and user-friendly"
    status: partial
    reason: "TOTP window is set to the default (30s) which is insufficient for SMS delivery latency."
    artifacts:
      - path: "app/controllers/users/sessions_controller.rb"
        issue: "validate_and_consume_otp! called without drift parameter."
    missing:
      - "Drift parameter (e.g., 5-10 minutes) to allow for SMS delivery delays."
human_verification:
  - test: "Real SMS Gateway Integration"
    expected: "OTP should be delivered via Sparrow/Aakash SMS when configured."
    why_human: "External service dependency and requires API credentials."
  - test: "Devanagari Font Rendering on Mobile"
    expected: "Mukta font should render without clipping matras on iOS/Android devices."
    why_human: "Visual check on hardware required to verify line-height and rendering."
---

# Phase 01: Foundation Identity Verification Report

**Phase Goal:** Users can securely register and manage their bilingual profiles.
**Verified:** 2026-04-14
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #   | Truth   | Status     | Evidence       |
| --- | ------- | ---------- | -------------- |
| 1   | Application initialized with PostgreSQL and Tailwind | ✓ VERIFIED | Gemfile and database.yml confirm stack. |
| 2   | UI text is translated to Nepali via ?locale=ne | ✓ VERIFIED | `Localizable` concern and `ne.yml` implemented. |
| 3   | User language preference persists in session/DB | ✓ VERIFIED | Logic in `Localizable` and persistent `locale` field in User. |
| 4   | Login/Sign-up via 10-digit phone number | ✓ VERIFIED | `SessionsController#create` handles phone registration. |
| 5   | OTP is generated and logged in development | ✓ VERIFIED | `SmsService::MockAdapter` logs OTP to Rails logger. |
| 6   | Successful authentication via 6-digit OTP | ✓ VERIFIED | `SessionsController#verify_otp` uses devise-two-factor. |
| 7   | Users can toggle to Email/Password login | ✓ VERIFIED | UI toggle in `new.html.erb` switching form visibility. |
| 8   | Mandatory onboarding for new users | ✓ VERIFIED | `ApplicationController#ensure_onboarded` redirects. |
| 9   | Profile management (Name, Bio, Avatar) | ✓ VERIFIED | `ProfilesController` and Active Storage implemented. |
| 10  | Role toggle between 'Poster' and 'Tasker' | ✓ VERIFIED | `ProfilesController#toggle_role` and enum in User. |
| 11  | OTP requests are rate-limited | ✗ FAILED | Bypassed due to incorrect configuration in `Rack::Attack`. |
| 12  | OTP window allows for SMS latency | ⚠️ PARTIAL | Default 30s window is too short for real SMS. |

**Score:** 11/12 truths verified

### Required Artifacts

| Artifact | Expected    | Status | Details |
| -------- | ----------- | ------ | ------- |
| `app/controllers/concerns/localizable.rb` | Locale setting logic | ✓ VERIFIED | Implements priority-based locale extraction. |
| `config/locales/ne.yml` | Nepali translations | ✓ VERIFIED | Substantive translations for auth and profile. |
| `app/models/user.rb` | User model with roles/OTP | ✓ VERIFIED | Includes Devise, roles enum, and OTP secret. |
| `app/services/sms_service.rb` | SMS delivery abstraction | ✓ VERIFIED | Adapter pattern with Mock, Sparrow, and Aakash. |
| `config/initializers/rack_attack.rb` | Rate limiting | ✗ STUB | Logically incorrect configuration (wrong path/params). |
| `app/controllers/users/sessions_controller.rb` | Auth flow | ✓ VERIFIED | Custom 2-step phone login flow. |
| `app/controllers/onboarding_controller.rb` | Onboarding wizard | ✓ VERIFIED | 3-step mandatory wizard. |
| `app/controllers/profiles_controller.rb` | Profile management | ✓ VERIFIED | Includes role toggle and Active Storage. |

### Key Link Verification

| From | To  | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| `ApplicationController` | `Localizable` | `include` | ✓ WIRED | Locale set on every request. |
| `ApplicationController` | `OnboardingController` | `before_action` | ✓ WIRED | Mandatory redirect for unonboarded users. |
| `User` | `SmsService` | `send_two_factor_authentication_code` | ✓ WIRED | Model triggers SMS delivery. |
| `SessionsController` | `SmsService` | controller call | ✓ WIRED | create action generates OTP and sends it. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| `ProfilesController#show` | `@user` | `current_user` | Yes | ✓ FLOWING |
| `SessionsController#create` | `code` | `@user.current_otp` | Yes (ROTP) | ✓ FLOWING |
| `SmsService` | `message` | `code` | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Routes check | `bin/rails routes` | OTP and Profile routes exist | ✓ PASS |
| Model validation | `User.new(phone: '123')` | Validation fails (format) | ✓ PASS |
| Translation check | `I18n.t('hello', locale: :ne)` | "नमस्ते" | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| AUTH-01 | 01-02 | SMS OTP login/signup | ✓ SATISFIED | Phone registration flow in SessionsController. |
| AUTH-02 | 01-02 | Email/Password toggle | ✓ SATISFIED | Form toggle implemented in UI. |
| AUTH-04 | 01-01 | Bilingual UI toggle | ✓ SATISFIED | ne.yml and Localizable concern. |
| AUTH-05 | 01-03 | Profile management | ✓ SATISFIED | ProfilesController with avatar support. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `config/initializers/rack_attack.rb` | 14-23 | Path/Param mismatch | 🛑 Blocker | Rate limiting is completely bypassed. |
| `app/controllers/users/sessions_controller.rb` | 36 | 30s OTP window | ⚠️ Warning | SMS login will be unreliable in real conditions. |

### Human Verification Required

### 1. Real SMS Gateway Integration
**Test:** Configure Sparrow/Aakash API credentials and attempt login.
**Expected:** OTP should be delivered to the physical device.
**Why human:** Requires external service access and private credentials.

### 2. Mobile UI/UX Audit
**Test:** Access the app via a mobile browser and complete onboarding in Nepali.
**Expected:** No layout shifts, matras are not clipped, and language toggle is accessible.
**Why human:** Visual quality and font rendering verification.

### Gaps Summary

The identity foundation is functionally complete but insecure. The **Rack::Attack** configuration for rate-limiting is ineffective because it targets a non-existent path and checks for the wrong parameter name, leaving the application vulnerable to SMS pumping. Additionally, the **30-second OTP window** is likely too short for real-world SMS delivery in Nepal, posing a significant usability risk.

---

_Verified: 2026-04-14_
_Verifier: the agent (gsd-verifier)_
