class Admin::BidsController < Admin::BaseController
  before_action :set_bid, only: [:accept, :reject]

  def index
    @bids = Bid.includes(:user, task: :user).order(created_at: :desc)
    @bids = @bids.where(status: params[:status]) if params[:status].present?
    @bids = @bids.page(params[:page]).per(20)
  end

  def accept
    task = @bid.task
    ActiveRecord::Base.transaction do
      @bid.update!(status: :accepted)
      task.update!(status: :assigned, payment_type: @bid.payment_method)
      task.bids.where.not(id: @bid.id).update_all(status: :rejected)
    end
    log_admin_action!("accept_bid", @bid, details: { task_id: task.id })
    redirect_to admin_bids_path, notice: "Bid ##{@bid.id} accepted; task ##{task.id} assigned."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_bids_path, alert: "Could not accept bid: #{e.message}"
  end

  def reject
    task = @bid.task
    reverted_task = false

    ActiveRecord::Base.transaction do
      if @bid.accepted? && task.assigned?
        task.unassign!
        reverted_task = true
      end
      @bid.update!(status: :rejected)
    end

    log_admin_action!("reject_bid", @bid, details: { task_id: task.id, task_reverted_to_open: reverted_task })
    redirect_to admin_bids_path, notice: "Bid ##{@bid.id} rejected#{reverted_task ? ' and task reverted to open' : ''}."
  rescue AASM::InvalidTransition, ActiveRecord::RecordInvalid => e
    redirect_to admin_bids_path, alert: "Could not reject bid: #{e.message}"
  end

  private

  def set_bid
    @bid = Bid.find(params[:id])
  end
end
