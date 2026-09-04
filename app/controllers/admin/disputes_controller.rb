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
      resolve_release
    when 'refund'
      resolve_refund
    when 'split'
      resolve_split
    when 'reopen'
      resolve_reopen
    else
      flash[:alert] = "Invalid resolution decision."
    end

    redirect_to admin_disputes_path
  end

  private

  def resolve_release
    if @task.release_payment!
      log_admin_action!("resolve_dispute", @task, details: { decision: "release" })
      flash[:notice] = "Dispute resolved: Funds released to tasker."
    else
      flash[:alert] = "Failed to release funds."
    end
  end

  def resolve_refund
    if Payments::LedgerManager.refund_poster(@task)
      @task.cancel!
      log_admin_action!("resolve_dispute", @task, details: { decision: "refund" })
      flash[:notice] = "Dispute resolved: Funds refunded to poster."
    else
      flash[:alert] = "Failed to refund funds."
    end
  end

  def resolve_split
    percentage = params[:tasker_percentage].to_s

    unless valid_percentage?(percentage)
      flash[:alert] = "Please provide a valid tasker percentage between 0 and 100."
      return
    end

    Payments::LedgerManager.split_escrow(@task, percentage.to_f)
    @task.release_payment!
    log_admin_action!("resolve_dispute", @task, details: { decision: "split", tasker_percentage: percentage.to_i })
    flash[:notice] = "Dispute resolved: Funds split #{percentage}% tasker / #{100 - percentage.to_i}% poster."
  end

  def resolve_reopen
    @task.accepted_bid&.update!(status: :rejected)
    @task.reopen!
    log_admin_action!("resolve_dispute", @task, details: { decision: "reopen" })
    flash[:notice] = "Dispute resolved: Task reopened for new bids."
  rescue AASM::InvalidTransition
    flash[:alert] = "Task could not be reopened from its current status."
  end

  def valid_percentage?(percentage)
    value = Float(percentage)
    value >= 0 && value <= 100
  rescue ArgumentError, TypeError
    false
  end

  def set_task
    @task = Task.find(params[:id])
  end
end
