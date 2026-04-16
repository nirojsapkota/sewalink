---
created: 2026-04-15T21:05:00Z
title: Fix Resend Code link on login screen
area: auth
files:
  - app/views/users/sessions/otp.html.erb:26
  - app/controllers/users/sessions_controller.rb
  - config/routes.rb
---

## Problem

The "Resend Code" link on the OTP verification screen (`app/views/users/sessions/otp.html.erb`) is currently a placeholder (`#`) and is not functional. Users who do not receive their OTP code have no way to request a new one from that screen.

## Solution

1. Define a new route in `config/routes.rb` for `resend_otp`.
2. Add a `resend_otp` action to `Users::SessionsController` that identifies the user via `session[:otp_phone]`, regenerates the current OTP, and sends it again via `SmsService.send_otp`.
3. Update the link in `app/views/users/sessions/otp.html.erb` to point to the new route.
