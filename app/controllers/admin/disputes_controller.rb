class Admin::DisputesController < Admin::BaseController
  def index
    @disputes = Task.dispute.includes(:user, :tasker, :category).order(created_at: :desc).page(params[:page]).per(20)
  end

  def show
  end

  def resolve
  end
end
