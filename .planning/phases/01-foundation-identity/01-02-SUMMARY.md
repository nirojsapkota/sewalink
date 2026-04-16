---
phase: 01-foundation-identity
plan: 02
subsystem: Auth
tags: [devise, otp, sms, localization]
duration: 45m
completed_date: 2024-05-24
requires: [AUTH-01, AUTH-02]
provides: [SMS-OTP, Localized-Auth]
tech_stack: [devise, devise-two-factor, rack-attack, rotp]
key_files: [app/models/user.rb, app/services/sms_service.rb, config/initializers/rack_attack.rb, app/controllers/users/sessions_controller.rb, app/views/users/sessions/new.html.erb, app/views/users/sessions/otp.html.erb]
---

# Phase 01 Plan 02: SMS OTP and Identity Layer Summary

Implemented a robust identity and authentication layer for sewaLink, featuring primary SMS OTP login and optional email/password authentication. The system is fully localized in English and Nepali and includes rate-limiting to prevent abuse.

## Key Changes

### 1. SMS OTP Infrastructure
- Configured `devise-two-factor` on the `User` model to handle OTP generation and validation.
- Implemented `SmsService` with an adapter pattern, currently supporting a `MockAdapter` for development and providing stubs for `SparrowSMS` and `AakashSMS`.
- Overrode `send_two_factor_authentication_code` in `User` to automatically trigger SMS delivery.

### 2. Passwordless Flow & Custom Sessions
- Created a custom `Users::SessionsController` that implements a two-step login flow:
  - Step 1: User enters phone number; system sends OTP and redirects to verification page.
  - Step 2: User enters 6-digit OTP; system validates and signs the user in.
- For new users signing up via phone, a secure random password is automatically generated.
- Standard email/password login is still supported via a toggle in the UI.

### 3. Security & Rate Limiting
- Configured `Rack::Attack` to throttle OTP requests by both IP address and phone number to mitigate SMS pumping and brute-force attacks.
- Used `devise-two-factor`'s built-in session encryption for OTP secrets.

### 4. Localized UI
- Developed customized Devise views using Tailwind CSS.
- Implemented a UI toggle to switch between Phone and Email login methods.
- All auth strings are fully localized using `t()` keys in `en.yml` and `ne.yml`.

## Deviations from Plan

- **None - plan executed exactly as written.**

## Known Stubs

| File | Line | Reason |
|------|------|--------|
| `app/services/sms_service.rb` | 26 | `SparrowAdapter` needs API credentials to be fully implemented. |
| `app/services/sms_service.rb` | 34 | `AakashAdapter` needs API credentials to be fully implemented. |

## Threat Surface Scan

| Flag | File | Description |
|------|------|-------------|
| threat_flag: otp_endpoint | `app/controllers/users/sessions_controller.rb` | Custom OTP endpoint; mitigated by Rack::Attack. |
| threat_flag: auto_registration | `app/controllers/users/sessions_controller.rb` | Auto-registers users by phone number; ensures low barrier to entry. |

## Self-Check: PASSED
- [x] All tasks executed
- [x] Each task committed individually
- [x] All deviations documented
- [x] SUMMARY.md created
