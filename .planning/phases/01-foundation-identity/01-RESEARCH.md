# Phase 01: Foundation & Identity - Research

**Researched:** 2024-05-24
**Domain:** Authentication, Bilingual Profiles, Mobile Onboarding
**Confidence:** HIGH

## Summary

This phase establishes the core identity layer for sewaLink. The research confirms that a Rails 8 "Solid Stack" (using Solid Queue and Solid Cache) is ideal for managing the high-concurrency needs of SMS OTP. We will leverage `devise` with `devise-two-factor` for robust session management while maintaining the flexibility to trigger local Nepali SMS gateways.

**Primary recommendation:** Use `devise` paired with `devise-two-factor` for authentication. Implement a flexible `SmsService` that supports both Sparrow SMS and Aakash SMS via simple HTTP adapters. For bilingual support, use the `Mukta` Unicode font to ensure consistent Devanagari rendering across iOS, Android, and Web.

## User Constraints (from CONTEXT.md)

<user_constraints>
### Locked Decisions
- **D-01:** SMS OTP is the primary entry point for all users.
- **D-02:** Email/password is an optional secondary authentication method.
- **D-03:** Use standard Devise-like session management adapted for OTP and Hotwire Native.
- **D-04:** Use standard Rails `i18n` with English (`en.yml`) and Nepali (`ne.yml`) locale files.
- **D-05:** A persistent language toggle in the navigation or profile settings.
- **D-06:** Store user's preferred locale in the database.
- **D-07:** Single `User` model with an `active_role` (enum: poster, tasker).
- **D-08:** Users can switch their active role via a toggle in the UI.
- **D-09:** A lightweight post-signup wizard to collect name, language, and initial role.
- **D-10:** Clear progress indicators during OTP and onboarding.

### the agent's Discretion
- Selection of specific SMS gateway (Sparrow SMS, Aakash SMS).
- UI layout for the onboarding wizard.
- Exact design of the profile page components.

### Deferred Ideas (OUT OF SCOPE)
- **AUTH-03 (Role-specific profiles)**: Extended fields specific to taskers (deferred to Phase 2).
- **Government ID Vetting**: Deferred to post-MVP.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AUTH-01 | SMS-based authentication (OTP) | `devise-two-factor` provides the hooks for a 2-step OTP flow. |
| AUTH-02 | Toggle to Email/Password login | Devise handles multi-strategy authentication out of the box. |
| AUTH-04 | Bilingual UI toggle (NE/EN) | Standard Rails `i18n` + `Mukta` font for Devanagari rendering. |
| AUTH-05 | Profile management (Name, Pic, Bio) | Single `User` model with `active_role` enum and standard fields. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `devise` | ~> 4.9 | Authentication | Industry standard for Rails; handles session lifecycle and security. |
| `devise-two-factor` | ~> 6.0 | OTP Logic | Minimalist OTP handling; supports Rails 8 Active Record Encryption. [VERIFIED: GitHub] |
| `rails-i18n` | Latest | Locale Defaults | Provides common translations (date, time) for 90+ locales including `ne`. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|--------------|
| `rotp` | ~> 6.3 | OTP Generation | Underlying logic for `devise-two-factor`. |
| `solid_queue` | Latest | SMS Delivery | Rails 8 default background job processor. |
| `solid_cache` | Latest | OTP Storage | Rails 8 default cache; ideal for short-lived OTP codes. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `devise` | Rails 8 Built-in Auth | Built-in is cleaner but lacks "Two-Factor" hooks and password reset magic out of the box. |
| `devise` | `Sorcery` | Sorcery is better for "DIY" but Devise is the project's locked decision. |

**Installation:**
```bash
bundle add devise devise-two-factor rails-i18n
bin/rails generate devise:install
bin/rails generate devise User
```

## Architecture Patterns

### SMS Service Pattern
Don't hard-code gateway logic. Use an adapter pattern to switch between Sparrow and Aakash easily.
```ruby
# app/services/sms_service.rb
class SmsService
  def self.send_otp(phone, code)
    adapter = ENV['SMS_GATEWAY'] == 'sparrow' ? SparrowAdapter.new : AakashAdapter.new
    adapter.send_message(phone, "Your sewaLink code is: #{code}")
  end
end
```

### Hotwire Native Bridge (Onboarding)
To hide the bottom navigation bar during the onboarding wizard in the mobile app:
```javascript
// app/javascript/controllers/bridge_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (window.TurboNative) {
      window.TurboNative.postMessage({ type: "toggle_nav", visible: false })
    }
  }

  disconnect() {
    if (window.TurboNative) {
      window.TurboNative.postMessage({ type: "toggle_nav", visible: true })
    }
  }
}
```

### Anti-Patterns to Avoid
- **Hard-coding "98" prefixes:** Nepal mobile numbers are 10 digits. Validate format `^9[678]\d{8}$`.
- **Preeti/Kantipur Fonts:** Never use non-Unicode fonts. They will break in modern browsers and native views.
- **Storing OTPs in the DB long-term:** Use `Rails.cache` (Solid Cache) with an expiry of 5-10 minutes.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| OTP Generation | Custom randomizer | `ROTP::TOTP` | Ensures cryptographically secure, time-based codes. |
| SMS Delivery | Custom HTTP wrapper | `SmsService` pattern | Simplifies switching providers (Sparrow vs Aakash). |
| Image Resizing | Custom processing | `Active Storage` + `Vips` | Rails 8 standard; handles variants for profile pictures. |

## Common Pitfalls

### Pitfall 1: SMS Pumping
**What goes wrong:** Bots hit the OTP endpoint to send thousands of messages, draining the SMS balance.
**How to avoid:** Implement strict rate-limiting per IP and per Phone Number using `Rack::Attack`.

### Pitfall 2: Devanagari Line Height
**What goes wrong:** Nepali characters (matras) get clipped in the UI.
**How to avoid:** Increase CSS `line-height` to at least `1.5` for any text using the `Mukta` font.

### Pitfall 3: Path Persistence in Native
**What goes wrong:** After login, the user is redirected to `/onboarding`, but the Native app "loses" its place or shows the login screen on reload.
**How to avoid:** Ensure the root route `/` automatically redirects based on user state (Logged in? Onboarded?).

## Code Examples

### 1. Simple Sparrow SMS Adapter
```ruby
# [CITED: sparrowsms.com/api/]
require 'net/http'

class SparrowAdapter
  ENDPOINT = "http://api.sparrowsms.com/v2/sms/"
  
  def send_message(to, text)
    uri = URI(ENDPOINT)
    res = Net::HTTP.post_form(uri, {
      token: Rails.application.credentials.sparrow_token,
      from: 'sewaLink',
      to: to,
      text: text
    })
    JSON.parse(res.body)["status"] == "success"
  end
end
```

### 2. Nepali i18n Sample (ne.yml)
```yaml
# [CITED: rails-i18n community patterns]
ne:
  hello: "नमस्ते"
  auth:
    otp_sent: "तपाईंको फोनमा ६ अंकको कोड पठाइएको छ।"
    resend: "कोड पुन: पठाउनुहोस्"
  profiles:
    roles:
      poster: "काम दिने (Poster)"
      tasker: "काम गर्ने (Tasker)"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `devise_otp` | `devise-two-factor` | 2023 | Better integration with Rails Encryption. |
| Redis Sidekiq | `Solid Queue` | Rails 8 | No Redis dependency for basic job processing. |
| Preeti Font | `Mukta / Noto Sans`| 2020+ | Perfect Unicode rendering on all devices. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `devise-two-factor` fully supports Rails 8 | Standard Stack | Minor migration issues if gem hasn't updated its internal version checks. |
| A2 | Sparrow/Aakash SMS support HTTPS | Code Examples | Some local gateways still use insecure HTTP endpoints; fallback to HTTP may be needed. |
| A3 | Mukta font is pre-installed on iOS | Architecture | If not pre-installed, must be bundled as a Custom Font in Xcode. [HIGH probability it needs bundling] |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Ruby | Backend | ✓ | 3.3.x | — |
| Rails | Framework | ✓ | 8.0.0.alpha | — |
| SQLite/Postgres | Database | ✓ | — | — |
| Sparrow SMS API | SMS Delivery | ✗ | — | Aakash SMS or Mock for dev |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Minitest (Rails default) |
| Config file | `test/test_helper.rb` |
| Quick run command | `bin/rails test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUTH-01 | User receives OTP after entering phone | Integration | `bin/rails test test/integration/auth_flow_test.rb` | ❌ Wave 0 |
| AUTH-04 | UI changes language on toggle | System | `bin/rails test test/system/language_toggle_test.rb` | ❌ Wave 0 |

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Yes | `devise` + `devise-two-factor` |
| V5 Input Validation | Yes | `zod` (if using React/JS) or standard Rails validations. |

### Known Threat Patterns for Rails 8

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SMS Pumping | Denial of Service | `Rack::Attack` rate-limiting |
| OTP Brute Force | Spoofing | `devise-two-factor` max attempts + lockout |

## Sources

### Primary (HIGH confidence)
- `devise-two-factor` GitHub Repository - implementation details.
- Sparrow SMS API Documentation - endpoint structure.
- Rails 8 "Solid Stack" Official Blog Post.

### Secondary (MEDIUM confidence)
- `rails-i18n` locale files for `ne`.
- Google Fonts `Mukta` documentation.

---
**Research date:** 2024-05-24
**Valid until:** 2024-06-24
