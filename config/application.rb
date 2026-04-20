require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SewaLink
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    config.time_zone = "Kathmandu"
    # config.eager_load_paths << Rails.root.join("extras")
    config.i18n.available_locales = [:en, :ne]
    config.i18n.default_locale = :en

    config.active_storage.variant_processor = :mini_magick

    # ActiveRecord Encryption fallbacks for development
    config.active_record.encryption.primary_key = "test_primary_key_must_be_32_chars_!!!"
    config.active_record.encryption.deterministic_key = "test_deterministic_key_must_be_32"
    config.active_record.encryption.key_derivation_salt = "test_salt_must_be_32_chars_!!!"
  end
end
