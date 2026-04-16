class TaskerDashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_tasker!

  def index
    @pending_bids = current_user.bids.pending.includes(:task).order(created_at: :desc)
    @active_jobs = current_user.bids.accepted.includes(:task).order(updated_at: :desc).map(&:task)
  end

  private

  def ensure_tasker!
    unless current_user.tasker?
      redirect_to root_path, alert: "Access denied. Only Taskers can access this dashboard."
    end
  end
end
