class TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_task, only: [:show, :edit, :update, :destroy, :request_payment, :release_payment, :raise_dispute, :toggle_draft, :check_geofence, :complete]

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
    if current_user.poster? && @task.user == current_user
      @bids = @task.bids.includes(:user).order(created_at: :desc)
    elsif current_user.tasker?
      @user_bid = @task.bids.find_by(user: current_user)
      @bid = @user_bid || @task.bids.build(user: current_user)
    end
    @review = @task.reviews.build
    @existing_review = @task.reviews.find_by(reviewer_id: current_user.id)
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

  def request_payment
    authorize @task
    if @task.request_payment!
      redirect_to @task, notice: t('.success', default: 'Payment requested successfully.')
    else
      redirect_to @task, alert: t('.failure', default: 'Could not request payment.')
    end
  end

  def release_payment
    authorize @task
    ActiveRecord::Base.transaction do
      if @task.release_payment!
        redirect_to @task, notice: t('.success', default: 'Payment released and task completed.')
      else
        redirect_to @task, alert: t('.failure', default: 'Could not release payment.')
        raise ActiveRecord::Rollback
      end
    end
  rescue AASM::InvalidTransition
    redirect_to @task, alert: t('.invalid_transition', default: 'Invalid status transition.')
  end

  def raise_dispute
    authorize @task
    if @task.raise_dispute!
      redirect_to @task, notice: t('.success', default: 'Dispute raised successfully.')
    else
      redirect_to @task, alert: t('.failure', default: 'Could not raise dispute.')
    end
  end

  def toggle_draft
    authorize @task
    if @task.toggle_draft!
      redirect_to @task, notice: t('.success', default: "Task is now #{@task.status}.")
    else
      redirect_to @task, alert: t('.failure', default: 'Could not toggle draft status.')
    end
  end

  def delete_photo
    @task = Task.find(params[:id])
    authorize @task, :update?
    photo = @task.photos.find(params[:photo_id])
    photo.purge
    
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("photo_#{params[:photo_id]}") }
      format.html { redirect_to edit_task_path(@task), notice: "Photo deleted." }
    end
  end

  def check_geofence
    authorize @task
    current_latitude = params[:current_latitude].to_f
    current_longitude = params[:current_longitude].to_f

    # Ensure task has location data
    if @task.latitude.present? && @task.longitude.present?
      distance = Geocoder::Calculations.distance_between(
        [current_latitude, current_longitude],
        [@task.latitude, @task.longitude],
        units: :km # Geocoder defaults to miles, but plan says 200m
      ) * 1000 # Convert km to meters

      within_geofence = distance <= 200 # D-04: 200m radius

      render json: {
        within_geofence: within_geofence,
        distance: distance,
        task_status: @task.status # Return current task status for UI update
      }
    else
      render json: { error: "Task location not defined." }, status: :unprocessable_entity
    end
  end

  def perform_check_in
    authorize @task, :check_in? # Assuming a policy for check_in
    current_latitude = params[:current_latitude].to_f
    current_longitude = params[:current_longitude].to_f

    if @task.latitude.present? && @task.longitude.present?
      distance = Geocoder::Calculations.distance_between(
        [current_latitude, current_longitude],
        [@task.latitude, @task.longitude],
        units: :km
      ) * 1000

      if distance <= 200 # D-04: 200m radius
        if @task.may_check_in?
          @task.check_in!
          render json: { success: true, message: "Checked in successfully.", task_status: @task.status }
        else
          render json: { success: false, message: "Task cannot be checked in at its current status.", task_status: @task.status }, status: :unprocessable_entity
        end
      else
        render json: { success: false, message: "You are outside the geofence.", task_status: @task.status }, status: :forbidden
      end
    else
      render json: { error: "Task location not defined." }, status: :unprocessable_entity
    end
  rescue AASM::InvalidTransition => e
    render json: { success: false, message: "Invalid transition for check-in: #{e.message}", task_status: @task.status }, status: :unprocessable_entity
  end

  def complete
    authorize @task
    if @task.complete!
      redirect_to @task, notice: t('.success', default: 'Task marked as complete.')
    else
      redirect_to @task, alert: t('.failure', default: 'Could not mark task as complete.')
    end
  rescue AASM::InvalidTransition => e
    redirect_to @task, alert: t('.invalid_transition', default: "Invalid status transition: #{e.message}.")
  end

  private

  def set_task
    @task = Task.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to tasks_path, alert: "Task not found."
  end

  def task_params
    params.require(:task).permit(:title, :description, :budget, :location, :category_id, :status, photos: [])
  end
end
