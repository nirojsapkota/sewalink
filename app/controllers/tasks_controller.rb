class TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_task, only: [:show, :edit, :update, :destroy]

  def index
    if current_user.tasker?
      @tasks = policy_scope(Task).open.with_attached_photos.includes(:category).order(created_at: :desc)

      # Apply Filters
      if params[:category_id].present?
        @tasks = @tasks.where(category_id: params[:category_id])
      end

      if params[:min_budget].present?
        @tasks = @tasks.where("budget >= ?", params[:min_budget])
      end

      if params[:max_budget].present?
        @tasks = @tasks.where("budget <= ?", params[:max_budget])
      end

      if params[:location].present?
        distance = params[:distance].presence || 10
        @tasks = @tasks.near(params[:location], distance)
      end

      @tasks = @tasks.page(params[:page]).per(10)
    else
      @tasks = policy_scope(Task).where(user: current_user).order(created_at: :desc).page(params[:page]).per(10)
    end
    authorize @tasks
  end

  def show
    authorize @task
  end

  def new
    @task = Task.new(status: :open)
    authorize @task
  end

  def create
    @task = current_user.tasks.build(task_params)
    authorize @task

    if @task.save
      redirect_to @task, notice: t('.success', default: 'Task was successfully created.')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @task
  end

  def update
    authorize @task
    if @task.update(task_params)
      redirect_to @task, notice: t('.success', default: 'Task was successfully updated.')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @task
    @task.destroy
    redirect_to tasks_url, notice: t('.success', default: 'Task was successfully destroyed.')
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :budget, :location, :category_id, photos: [])
  end
end
