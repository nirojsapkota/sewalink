class Admin::PayoutsController < Admin::BaseController
  def index
    @pending_payouts = PayoutRequest.pending.includes(:user).order(created_at: :asc)
    @processed_payouts = PayoutRequest.processed.includes(:user).order(created_at: :desc).limit(50)
  end

  def process_payout
    @payout = PayoutRequest.find(params[:id])
    if @payout.process!
      log_admin_action!("process_payout", @payout, details: { amount: @payout.amount.to_s })
      redirect_to admin_payouts_path, notice: "Payout for #{@payout.user.phone} marked as processed and ledger updated."
    else
      redirect_to admin_payouts_path, alert: "Could not process payout."
    end
  rescue AASM::InvalidTransition
    redirect_to admin_payouts_path, alert: "Payout has already been processed or rejected."
  end

  def reject_payout
    @payout = PayoutRequest.find(params[:id])
    @payout.rejection_reason = params[:rejection_reason]
    if @payout.reject!
      log_admin_action!("reject_payout", @payout, details: { reason: @payout.rejection_reason })
      redirect_to admin_payouts_path, notice: "Payout request rejected."
    else
      redirect_to admin_payouts_path, alert: "Could not reject payout."
    end
  rescue AASM::InvalidTransition
    redirect_to admin_payouts_path, alert: "Payout has already been processed or rejected."
  end
end
