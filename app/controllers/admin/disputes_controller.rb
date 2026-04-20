class Admin::DisputesController < Admin::BaseController
  before_action :set_task, only: [:show, :resolve]

  def index
    @disputes = Task.dispute.includes(:user, :tasker, :category).order(created_at: :desc).page(params[:page]).per(20)
  end

  def show
    @dispute_evidences = @task.dispute_evidences.includes(:user, files_attachments: :blob)
    @conversations = @task.conversations.includes(messages: :sender)
  end

  def resolve
    case params[:decision]
    when 'release'
      if @task.release_payment!
        flash[:notice] = "Dispute resolved: Funds released to tasker."
      else
        flash[:alert] = "Failed to release funds."
      end
    when 'refund'
      if Payments::LedgerManager.refund_poster(@task)
        @task.cancel!
        flash[:notice] = "Dispute resolved: Funds refunded to poster."
      else
        flash[:alert] = "Failed to refund funds."
      end
    else
      flash[:alert] = "Invalid resolution decision."
    end

    redirect_to admin_disputes_path
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end
end
