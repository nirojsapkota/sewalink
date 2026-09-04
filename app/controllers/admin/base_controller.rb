class Admin::BaseController < ApplicationController
  layout 'admin'
  before_action :authenticate_user!
  before_action :ensure_admin!

  private

  def ensure_admin!
    redirect_to root_path, alert: "Access denied. Admin only." unless current_user&.admin_access?
  end

  def require_super_admin!
    redirect_to admin_root_path, alert: "Access denied. Super admin only." unless current_user&.super_admin?
  end

  def log_admin_action!(action, target = nil, details: {})
    AdminActivityLog.record!(admin: current_user, action: action, target: target, details: details)
  end
end
