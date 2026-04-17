class DisputeEvidencesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_task

  def create
    @dispute_evidence = @task.dispute_evidences.build(dispute_evidence_params)
    @dispute_evidence.user = current_user
    authorize @dispute_evidence

    if @dispute_evidence.save
      # Optionally transition task state to dispute if it's not already
      @task.raise_dispute! if @task.may_raise_dispute?
      
      redirect_to @task, notice: 'Evidence was successfully uploaded and dispute raised.'
    else
      redirect_to @task, alert: 'Failed to upload evidence: ' + @dispute_evidence.errors.full_messages.join(', ')
    end
  end

  private

  def set_task
    @task = Task.find(params[:task_id])
  end

  def dispute_evidence_params
    params.require(:dispute_evidence).permit(:description, files: [])
  end
end
