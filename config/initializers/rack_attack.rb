class Rack::Attack
  # Rate limit OTP requests to prevent SMS pumping
  # throttle('otp/ip', limit: 5, period: 1.minute) do |req|
  #   req.ip if req.path == '/users/sessions/otp' && req.post?
  # end

  # throttle('otp/phone', limit: 3, period: 10.minutes) do |req|
  #   req.params['phone'] if req.path == '/users/sessions/otp' && req.post?
  # end

  ### Throttle Spammy Clients ###

  # If any single IP makes more than 5 OTP requests per minute, block it.
  throttle('req/ip', limit: 5, period: 1.minute) do |req|
    req.ip if req.path == '/users/send_otp' && req.post?
  end

  # If any single phone number requests more than 3 OTPs in 10 minutes, block it.
  throttle('otp/phone', limit: 3, period: 10.minutes) do |req|
    req.params['phone'] if req.path == '/users/send_otp' && req.post?
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |request|
    [ 429,  # HTTP Status Code
      { 'Content-Type' => 'application/json' },
      [{ error: "Too many requests. Please try again later." }.to_json]
    ]
  end
end
