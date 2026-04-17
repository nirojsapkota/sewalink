Geocoder.configure(
  # Geocoding options
  timeout: 5,                 # geocoding service timeout (secs)
  lookup: :google,            # name of geocoding service (symbol)
  api_key: Rails.application.credentials.google_geocoding_api_key, # API key for geocoding service
  use_https: true,            # use HTTPS for lookup requests
  language: :en,              # ISO-639 language code

  # Exceptions that should not be rescued by default
  # (if you want to implement custom error handling);
  # supports SocketError and Timeout::Error
  # always_raise: [],

  # Calculation options
  units: :km,                 # :km for kilometers or :mi for miles
  distances: :spherical       # :spherical or :linear

  # Cache configuration
  # cache_options: {
  #   expiration: 2.days,
  #   prefix: 'geocoder:'
  # }
)
