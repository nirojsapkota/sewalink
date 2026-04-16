module Tasks
  class CompletionController < ApplicationController
    before_action :authenticate_user!
    before_action :set_task

    def create
      authorize @task, :update?

      if @task.update(status: :completed)
        notice = if @task.esewa?
                   "Task completed! Funds have been released from escrow to the Tasker."
                 else
                   "Task completed!"
                 end
        redirect_to @task, notice: notice
      else
        redirect_to @task, alert: "Could not complete task: #{@task.errors.full_messages.join(', ')}"
      end
    end

    private

    def set_task
      @task = Task.find(params[:task_id])
    end
  end
end
