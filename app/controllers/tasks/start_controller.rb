module Tasks
  class StartController < ApplicationController
    before_action :authenticate_user!
    before_action :set_task

    def create
      authorize @task, :start?

      if @task.update(status: :in_progress)
        redirect_to @task, notice: "Task started! Keep up the good work."
      else
        redirect_to @task, alert: "Could not start task: #{@task.errors.full_messages.join(', ')}"
      end
    end

    private

    def set_task
      @task = Task.find(params[:task_id])
    end
  end
end
