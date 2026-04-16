module Localizable
  extend ActiveSupport::Concern

  included do
    before_action :set_locale
  end

  private

  def set_locale
    I18n.locale = extract_locale || I18n.default_locale
    session[:locale] = I18n.locale
    current_user.update_column(:locale, I18n.locale) if user_signed_in? && current_user.locale != I18n.locale.to_s
  end

  def extract_locale
    # Order of priority:
    # 1. URL parameter (?locale=ne)
    # 2. Session value
    # 3. User preference
    parsed_locale = params[:locale] || session[:locale] || current_user&.locale
    
    # Mitigate tampering (T-01-01-01) by validating against available locales
    if I18n.available_locales.map(&:to_s).include?(parsed_locale.to_s)
      parsed_locale
    else
      nil
    end
  end
end
