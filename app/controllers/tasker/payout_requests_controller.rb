class Tasker::PayoutRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_tasker!

  def create
    @payout_request = current_user.payout_requests.build(payout_request_params)
    if @payout_request.save
      redirect_to tasker_wallet_path, notice: "Payout request submitted successfully and is pending approval."
    else
      @balance = current_user.balance
      @transactions = DoubleEntry::Line.where(account: 'tasker_balance', scope: current_user.id).order(created_at: :desc).limit(20)
      @pending_bids_total = current_user.bids.pending.sum(:amount)
      render "tasker/wallets/show", status: :unprocessable_entity
    end
  end

  private

  def ensure_tasker!
    redirect_to root_path, alert: "Only taskers can access this." unless current_user.tasker?
  end

  def payout_request_params
    params.require(:payout_request).permit(:amount, :payment_details)
  end
end
