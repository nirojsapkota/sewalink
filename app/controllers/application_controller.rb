class ApplicationController < ActionController::Base
  include Localizable
  include Pundit::Authorization

  before_action :ensure_onboarded

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:alert] = t("errors.messages.not_authorized")
    redirect_back(fallback_location: root_path)
  end

  def ensure_onboarded
    return unless user_signed_in?
    return if current_user.onboarded?
    return if devise_controller? || controller_name == 'onboarding'

    redirect_to onboarding_path
  end
end
