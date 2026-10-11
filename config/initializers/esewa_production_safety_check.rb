# Fail fast on boot if the production environment is accidentally left
# pointing at eSewa's UAT/sandbox endpoints. ESEWA_PAYMENT_URL and
# ESEWA_STATUS_URL both default to the UAT sandbox when unset (see
# Payments::EsewaV2 and PaymentsController), which is convenient for local
# development but would silently process real customer payments against a
# test gateway if left unset in production - money would appear to be taken
# from posters but never actually settle with eSewa.
# Skip during `assets:precompile` (e.g. in the Docker build stage): that step
# runs with RAILS_ENV=production but without the real runtime env vars
# (ESEWA_PAYMENT_URL/ESEWA_STATUS_URL are injected later, at container
# start), so this check would always raise and fail every production build.
# SECRET_KEY_BASE_DUMMY is set for exactly that same reason by ./bin/rails
# assets:precompile in the Dockerfile.
# TEMPORARY: production isn't wired up to the live eSewa gateway yet, so this
# check is allowed to pass against the UAT sandbox when explicitly
# acknowledged via ESEWA_ALLOW_UAT_IN_PRODUCTION=1. Remove this flag (and
# this comment) once real ESEWA_PAYMENT_URL/ESEWA_STATUS_URL are configured.
if Rails.env.production? && ENV["SECRET_KEY_BASE_DUMMY"].blank? && ENV["ESEWA_ALLOW_UAT_IN_PRODUCTION"].blank?
  uat_host = "uat.esewa.com.np"
  payment_url = ENV.fetch("ESEWA_PAYMENT_URL", "https://#{uat_host}/api/epay/main/v2/form")
  status_url = ENV.fetch("ESEWA_STATUS_URL", "https://#{uat_host}/api/epay/main/v2/status")

  if payment_url.include?(uat_host) || status_url.include?(uat_host)
    raise "ESEWA_PAYMENT_URL and ESEWA_STATUS_URL must be set to the live eSewa " \
          "endpoints in production - they are currently pointing at (or defaulting " \
          "to) the UAT sandbox (#{uat_host}). If this is intentional (not yet " \
          "live), set ESEWA_ALLOW_UAT_IN_PRODUCTION=1."
  end
end
