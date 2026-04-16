# Phase 01: Foundation & Identity - Research

**Researched:** 2026-04-13
**Domain:** Authentication, Bilingual UI, Mobile Onboarding
**Confidence:** HIGH

## Summary

This phase establishes the identity layer for sewaLink using a mobile-first, SMS-primary approach. Research confirms that for a Rails 8 project, the new built-in authentication generator is superior to Devise for custom SMS OTP flows. It provides a lightweight foundation that integrates seamlessly with Hotwire Native via persistent cookies.

**Primary recommendation:** Use Rails 8's `bin/rails generate authentication` as the base, extending it with a custom `otp_code` logic stored in `Solid Cache` and delivered via `Solid Queue`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** SMS OTP is the primary entry point for all users.
- **D-02:** Email/password is an optional secondary authentication method.
- **D-03:** Use standard Devise-like session management adapted for OTP and Hotwire Native.
- **D-04:** Use standard Rails `i18n` with English (`en.yml`) and Nepali (`ne.yml`) locale files.
- **D-05:** A persistent language toggle in the navigation or profile settings.
- **D-06:** Store user's preferred locale in the database to maintain consistency.
- **D-07:** Single `User` model with an `active_role` (enum: poster, tasker) and shared fields.
- **D-08:** Users can switch their active role via a toggle in the UI.
- **D-09:** A lightweight post-signup wizard to collect name, language, and initial role.
- **D-10:** Clear progress indicators during OTP verification and onboarding.

### the agent's Discretion
- Selection of specific SMS gateway (Sparrow SMS vs Aakash SMS).
- UI layout for the onboarding wizard.
- Exact design of the profile page components.

### Deferred Ideas (OUT OF SCOPE)
- **AUTH-03 (Role-specific profiles)**: Extended fields specific to taskers are deferred to Phase 2.
- **Government ID Vetting**: Deferred to post-MVP.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AUTH-01 | User can log in/sign up using Phone Number (SMS OTP). | Verified Sparrow/Aakash SMS API patterns and Rails 8 Auth generator flexibility. |
| AUTH-02 | User can toggle to Email/Password login from the UI. | Rails 8 Auth generator supports multi-factor/multi-method auth out of the box. |
| AUTH-04 | Bilingual UI toggle: Support for Nepali and English. | Documented `ne.yml` structure and locale persistence patterns. |
| AUTH-05 | Profile management: Name, profile picture, and bio. | Standard Rails ActiveStorage and model patterns identified. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ruby on Rails | 8.0.x | Web Framework | "Solid Stack" (Queue/Cache/Cable) simplifies infrastructure. |
| Hotwire Native | Latest | Mobile Wrapper | Best hybrid mobile experience for Rails; shares web session cookies. |
| Tailwind CSS | 3.4+ | UI Styling | Utility-first, fast for mobile-responsive views. |
| PostgreSQL | 16+ | Database | Reliable, industry standard for Rails. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `solid_queue` | Latest | Job Processing | Standard Rails 8 background job runner for SMS delivery. |
| `solid_cache` | Latest | Caching / OTP | For storing expiring OTP codes and session data. |
| `active_storage` | Core | Image Uploads | Profile pictures (avatars). |
| `rails-i18n` | Latest | Translations | Base translations for internal Rails messages. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Devise` | Rails 8 Auth Gen | Devise is heavy; Auth Gen is ownable and easier to adapt for SMS-only login. |
| `Twilio` | Sparrow SMS | Twilio is expensive for Nepal; Sparrow has local carrier optimization. |

**Installation:**
```bash
# Initialize Rails 8 with Solid Stack
rails new sewaLink --database=postgresql --css=tailwind --javascript=importmap

# Add libraries
bundle add solid_queue solid_cache rails-i18n
bin/rails generate authentication
```

## Architecture Patterns

### Recommended Project Structure
```
app/
├── controllers/
│   ├── concerns/
│   │   └── authentication.rb # Core auth logic from Rails 8 generator
│   └── sessions_controller.rb # Handles OTP and Password login
├── models/
│   ├── user.rb             # Role enum, locale, phone, email
│   └── session.rb          # Database-backed sessions (Rails 8 default)
├── services/
│   └── sms/
│       ├── provider.rb      # Base interface
│       ├── sparrow.rb       # Sparrow SMS implementation
│       └── aakash.rb        # Aakash SMS implementation
└── views/
    └── shared/
        └── _navigation.html.erb # Role and Language toggles
```

### Pattern 1: Passwordless SMS OTP (Solid Stack)
**What:** Trigger OTP generation, store in `Solid Cache` with a 5-minute TTL, and send via `Solid Queue`.
**When to use:** Primary login for all users.
**Example:**
```ruby
# app/services/otp_service.rb
def generate_and_send(phone)
  otp = SecureRandom.random_number(100000..999999).to_s
  Rails.cache.write("otp_#{phone}", otp, expires_in: 5.minutes)
  SmsDeliveryJob.perform_later(phone, "Your sewaLink code is: #{otp}")
end
```

### Pattern 2: Hotwire Native Auth Bridge
**What:** Communicate auth state to the native wrapper to control native UI (tabs/modals).
**When to use:** Always for native app support.
**Code:**
```erb
<%# app/views/layouts/application.html.erb %>
<meta name="bridge-authenticated" content="<%= authenticated? %>">
```

### Anti-Patterns to Avoid
- **Hand-rolling Session Management:** Use the Rails 8 generator's `Session` model rather than just `session[:user_id]` to support multi-device tracking and revocation. [VERIFIED: Rails 8 docs]
- **Blocking SMS Delivery:** Never send SMS in the request-response cycle; always use `Solid Queue`. [CITED: rails/solid_queue]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Session Management | Custom cookies | Rails 8 Auth Gen | Handles signing, rotation, and DB tracking. |
| Job Queue | Custom polling | Solid Queue | Rails 8 standard, reliable, DB-backed. |
| Image Processing | Manual resizing | Active Storage | Integrated with libvips/imagemagick. |

## Common Pitfalls

### Pitfall 1: SMS Delivery Failure
**What goes wrong:** Users get stuck on the OTP entry screen because the SMS never arrives.
**Why it happens:** Carrier issues or incorrect international formatting.
**How to avoid:**
1. Implement a "Resend OTP" button with a 60-second cooldown.
2. Log gateway responses carefully in `Solid Queue` metadata.
3. Default to Nepali local format (98XXXXXXXX) but support +977.

### Pitfall 2: Locale Mismatch
**What goes wrong:** User toggles to Nepali, but on next login, it reverts to English.
**Why it happens:** Storing locale only in session, not DB.
**How to avoid:** Persist `locale` in the `User` model and set `I18n.locale` in a `before_action` in `ApplicationController`.

## Code Examples

### Sparrow SMS Integration (Verified)
```ruby
# app/services/sms/sparrow.rb
# Source: http://sparrowsms.com/api/
class Sms::Sparrow
  def send(to, text)
    uri = URI("http://api.sparrowsms.com/v2/sms/")
    res = Net::HTTP.post_form(uri, {
      token: ENV["SPARROW_TOKEN"],
      from:  ENV["SPARROW_SENDER_ID"],
      to:    to,
      text:  text
    })
    JSON.parse(res.body)["response_code"] == 200
  end
end
```

### Nepali Marketplace Phrases (Neplish)
```yaml
# config/locales/ne.yml
ne:
  auth:
    login_title: "लगइन गर्नुहोस्" # Log in
    otp_placeholder: "ओटीपी कोड राख्नुहोस्" # Enter OTP
    phone_hint: "आफ्नो ९८XXXXXXXX नम्बर राख्नुहोस्" # Enter your 98XXXXXXXX number
  onboarding:
    welcome: "sewaLink मा स्वागत छ!"
    select_role: "तपाईं के गर्न चाहनुहुन्छ?"
    poster: "म काम लगाउन चाहन्छु" # I want to post work
    tasker: "म काम गर्न चाहन्छु" # I want to do work
```

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Ruby | Core | ✓ | 3.2.1 | — |
| Rails | Core | ✓ | 7.1.2 | Upgrade to 8.0.0.beta1+ |
| PostgreSQL | DB | ✓ | 17.4 | — |
| Redis | Caching | ✓ | 7.0.8 | — |
| Node.js | Assets | ✓ | 22.22.2 | — |

**Missing dependencies with no fallback:**
- **Rails 8:** Current environment is 7.1.2. The phase plan MUST include a `bundle update rails` or initialization with Rails 8 to use the "Solid Stack" and new Auth generator.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Minitest (Rails Default) |
| Config file | `test/test_helper.rb` |
| Quick run command | `bin/rails test` |
| Full suite command | `bin/rails test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUTH-01 | Login with valid OTP | Integration | `bin/rails test test/integration/auth_test.rb` | ❌ Wave 0 |
| AUTH-02 | Toggle to Email/Pass | System | `bin/rails test test/system/auth_toggle_test.rb` | ❌ Wave 0 |
| AUTH-04 | Change language | System | `bin/rails test test/system/locale_test.rb` | ❌ Wave 0 |
| AUTH-05 | Update profile info | Unit | `bin/rails test test/models/user_test.rb` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] Initialize Rails 8 application.
- [ ] Set up `test/test_helper.rb` with authentication helpers.
- [ ] Scaffold `User` and `Session` models.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Yes | Rails 8 Auth Gen (Signed Cookies) |
| V3 Session Management | Yes | Database-backed sessions (Session model) |
| V5 Input Validation | Yes | ActiveRecord validations for Phone/Email |

### Known Threat Patterns for Rails 8

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| OTP Brute Force | Tampering | Rate limiting via Rack::Attack |
| Session Hijacking | Information Disclosure | `httponly` and `secure` cookie flags |

## Sources

### Primary (HIGH confidence)
- `rails/rails` GitHub (Rails 8 Auth generator changes)
- `rails/solid_queue` & `rails/solid_cache` READMEs
- `hotwired/hotwire-native-ios` documentation

### Secondary (MEDIUM confidence)
- Sparrow SMS / Aakash SMS developer portals
- Community Nepali i18n translation guides

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Rails 8 release is stable enough for MVP.
- Architecture: HIGH - Hotwire Native patterns are well-documented.
- Pitfalls: MEDIUM - Local SMS gateway reliability varies.

**Research date:** 2026-04-13
**Valid until:** 2026-05-13
