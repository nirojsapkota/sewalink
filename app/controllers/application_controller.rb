class ApplicationController < ActionController::Base
  include Localizable
  include Pundit::Authorization

  before_action :ensure_onboarded
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:phone, :first_name, :last_name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name])
  end

  private

  def after_sign_in_path_for(resource)
    if resource.poster?
      poster_dashboard_path
    else
      tasker_dashboard_path
    end
  end

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
