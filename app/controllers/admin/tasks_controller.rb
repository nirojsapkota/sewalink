class Admin::TasksController < Admin::BaseController
  def index
    @tasks = Task.includes(:user, :category, :tasker).order(created_at: :desc)
    @tasks = @tasks.where(status: params[:status]) if params[:status].present?
    @tasks = @tasks.page(params[:page]).per(20)
  end

  def show
    @task = Task.includes(:user, :category, :tasker, :payment_transactions, :reviews, :dispute_evidences).find(params[:id])
  end
end
