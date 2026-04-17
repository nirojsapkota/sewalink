# app/controllers/reviews_controller.rb
class ReviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_task

  def create
    @review = @task.reviews.new(review_params)
    @review.reviewer = current_user
    @review.reviewee = (@task.poster == current_user) ? @task.tasker : @task.poster

    if @review.save
      redirect_to @task, notice: 'Review was successfully submitted.'
    else
      redirect_to @task, alert: 'Error submitting review.'
    end
  end

  private

  def set_task
    @task = Task.find(params[:task_id])
  end

  def review_params
    params.require(:review).permit(:rating, :comment, :private_note, :is_public)
  end
end
