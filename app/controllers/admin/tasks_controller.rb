class Admin::TasksController < Admin::BaseController
  before_action :set_task, only: [:show, :edit, :update, :force_cancel]

  def index
    @tasks = Task.includes(:user, :category, :tasker).order(created_at: :desc)
    @tasks = @tasks.where(status: params[:status]) if params[:status].present?
    @tasks = @tasks.page(params[:page]).per(20)
  end

  def show
    @task = Task.includes(:user, :category, :tasker, :payment_transactions, :reviews, :dispute_evidences).find(params[:id])
  end

  def edit
  end

  def update
    if @task.update(task_params)
      log_admin_action!("update_task", @task, details: { changes: task_params.to_h })
      redirect_to admin_task_path(@task), notice: "Task updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def force_cancel
    previous_status = @task.status

    if @task.esewa? && @task.paid? && !@task.cancelled? && !@task.completed?
      Payments::LedgerManager.refund_poster(@task)
    end

    @task.cancel!
    log_admin_action!("force_cancel_task", @task, details: { previous_status: previous_status })
    redirect_to admin_task_path(@task), notice: "Task force-cancelled."
  rescue AASM::InvalidTransition
    redirect_to admin_task_path(@task), alert: "Task cannot be cancelled from its current status (#{@task.status})."
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :budget, :category_id, :location)
  end
end
