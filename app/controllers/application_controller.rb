class ApplicationController < ActionController::Base
  include Localizable
  before_action :ensure_onboarded

  private

  def ensure_onboarded
    return unless user_signed_in?
    return if current_user.onboarded?
    return if devise_controller? || controller_name == 'onboarding'

    redirect_to onboarding_path
  end
end
