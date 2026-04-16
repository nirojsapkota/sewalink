---
phase: 01-foundation-identity
reviewed: 2024-05-24T00:00:00Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - app/controllers/concerns/localizable.rb
  - config/locales/ne.yml
  - app/controllers/home_controller.rb
  - app/views/home/index.html.erb
  - config/application.rb
  - app/controllers/application_controller.rb
  - app/views/layouts/application.html.erb
  - config/routes.rb
  - config/locales/en.yml
  - app/models/user.rb
  - app/services/sms_service.rb
  - config/initializers/rack_attack.rb
  - app/controllers/users/sessions_controller.rb
  - app/views/users/sessions/new.html.erb
  - app/views/users/sessions/otp.html.erb
  - app/controllers/onboarding_controller.rb
  - app/views/onboarding/show.html.erb
  - app/controllers/profiles_controller.rb
  - app/views/profiles/edit.html.erb
  - app/views/profiles/show.html.erb
findings:
  critical: 2
  warning: 4
  info: 3
  total: 9
status: issues_found
---

# Phase 01-foundation-identity: Code Review Report

**Reviewed:** 2024-05-24
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

The foundation identity layer for sewaLink is well-structured and follows modern Rails conventions, including a clean locale management system and a multi-step onboarding flow. However, there are significant security and usability concerns regarding the OTP implementation and rate limiting. Additionally, several i18n inconsistencies will lead to broken translations in the UI.

While the project aims to focus on Rails 8 patterns, the current codebase is running on Rails 7.1 and uses Devise, missing out on native Rails 8 authentication and rate-limiting features.

## Critical Issues

### CR-01: Ineffective OTP Rate Limiting (Bypass)

**File:** `config/initializers/rack_attack.rb:14-23`
**Issue:** `Rack::Attack` is configured to throttle requests to `/users/send_otp`, but this path does not exist in the routes. The actual OTP generation and delivery happen during the `create` action of `Users::SessionsController`, which corresponds to `POST /users/sign_in`. This leaves the system completely unprotected against SMS pumping and brute-force attacks.
**Fix:**
```ruby
  # Update paths to match the actual login route
  throttle('req/ip', limit: 5, period: 1.minute) do |req|
    req.ip if req.path == '/users/sign_in' && req.post? && req.params['login_method'] == 'phone'
  end
```

### CR-02: Incorrect Parameter Parsing in Rate Limiter

**File:** `config/initializers/rack_attack.rb:20`
**Issue:** The throttle attempts to access `req.params['phone']`, but the login form nested the field under the user object: `user[phone]`. Consequently, `req.params['phone']` is always `nil`, rendering the phone-based throttle ineffective.
**Fix:**
```ruby
  throttle('otp/phone', limit: 3, period: 10.minutes) do |req|
    # Use dig to safely access nested parameters
    req.params.dig('user', 'phone') if req.path == '/users/sign_in' && req.post?
  end
```

## Warnings

### WR-01: Poor UX with TOTP as SMS OTP

**File:** `app/models/user.rb:21`, `app/controllers/users/sessions_controller.rb:36`
**Issue:** The system uses `ROTP::TOTP` to generate and validate SMS codes. By default, TOTP codes are valid for only 30 seconds. Since the controller calls `validate_and_consume_otp!` without a `drift` parameter, users must receive and enter the SMS within the same 30-second window. This is highly unreliable for SMS delivery, which often experiences delays.
**Fix:** Add a generous drift to account for SMS delivery latency (e.g., allow 10 windows of 30 seconds each = 5 minutes).
```ruby
# app/controllers/users/sessions_controller.rb
if @user && @user.validate_and_consume_otp!(params[:otp], drift: 300)
```

### WR-02: Mismatched and Missing i18n Keys

**File:** `config/locales/en.yml`, `config/locales/ne.yml`
**Issue:** Several translation keys used in controllers do not match the locale files or are missing in Nepali.
1. `OnboardingController#update` calls `t('.success')` (looking for `onboarding.update.success`), but the locale only has `onboarding.show.success`.
2. `ProfilesController#update` calls `t('.success')` (looking for `profiles.update.success`), but `ne.yml` has it under `profiles.edit.success`.
3. `ProfilesController#toggle_role` uses `profiles.toggle_role.failure`, which is missing in `ne.yml`.
**Fix:** Standardize keys in both locale files and ensure they match the controller actions.

### WR-03: Silent SMS Failure

**File:** `app/controllers/users/sessions_controller.rb:20`
**Issue:** The return value of `send_two_factor_authentication_code` is ignored. If the SMS service fails (e.g., invalid credentials or API error), the user is still redirected with a success message ("OTP sent"), leading to confusion.
**Fix:**
```ruby
if @user.send_two_factor_authentication_code(code)
  redirect_to users_otp_path, notice: t('auth.otp_sent')
else
  flash[:alert] = t('auth.sms_failed')
  render :new
end
```

### WR-04: User Creation Before Verification

**File:** `app/controllers/users/sessions_controller.rb:6`
**Issue:** `User.find_or_initialize_by(phone: phone)` followed by `@user.save` creates a database record before the phone number is verified via OTP. While this enables "lazy registration," it allows an attacker to fill the `users` table with unverified records.
**Fix:** Consider saving the user only *after* successful OTP verification, or implementing a cleanup job for unonboarded/unverified users.

## Info

### IN-01: Rails 8 Native Patterns

**Issue:** The project focus is "Rails 8 patterns," but the app uses Devise and Rails 7.1 defaults.
**Recommendation:** 
1. Upgrade to Rails 8.0.
2. Consider using the new built-in `rate_limit` in controllers instead of `Rack::Attack`.
3. Evaluate if the new Rails 8 `authentication` generator (which is simpler and more transparent) fits the project better than Devise.

### IN-02: Hardcoded Fallback Key

**File:** `app/models/user.rb:5`
**Issue:** The `otp_secret_encryption_key` fallback is hardcoded in the model.
**Fix:** Move all secrets to `config/credentials.yml.enc` and access them via `Rails.application.credentials`.

### IN-03: Stubbed SMS Adapters

**File:** `app/services/sms_service.rb:26-34`
**Issue:** Both `SparrowAdapter` and `AakashAdapter` are stubs.
**Fix:** Ensure these are implemented before Phase 2 or when moving to production in Nepal.

---

_Reviewed: 2024-05-24_
_Reviewer: gsd-code-reviewer_
_Depth: standard_
