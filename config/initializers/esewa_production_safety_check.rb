# Fail fast on boot if the production environment is accidentally left
# pointing at eSewa's UAT/sandbox endpoints. ESEWA_PAYMENT_URL and
# ESEWA_STATUS_URL both default to the UAT sandbox when unset (see
# Payments::EsewaV2 and PaymentsController), which is convenient for local
# development but would silently process real customer payments against a
# test gateway if left unset in production - money would appear to be taken
# from posters but never actually settle with eSewa.
if Rails.env.production?
  uat_host = "uat.esewa.com.np"
  payment_url = ENV.fetch("ESEWA_PAYMENT_URL", "https://#{uat_host}/api/epay/main/v2/form")
  status_url = ENV.fetch("ESEWA_STATUS_URL", "https://#{uat_host}/api/epay/main/v2/status")

  if payment_url.include?(uat_host) || status_url.include?(uat_host)
    raise "ESEWA_PAYMENT_URL and ESEWA_STATUS_URL must be set to the live eSewa " \
          "endpoints in production - they are currently pointing at (or defaulting " \
          "to) the UAT sandbox (#{uat_host})."
  end
end
