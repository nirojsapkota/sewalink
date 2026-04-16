class Tasker::WalletsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_tasker!

  def show
    @balance = current_user.balance
    @transactions = DoubleEntry::Line.where(account: 'tasker_balance', scope: current_user.id).order(created_at: :desc).limit(20)
    @pending_bids_total = current_user.bids.pending.sum(:amount)
    @payout_request = PayoutRequest.new(user: current_user)
  end

  private

  def ensure_tasker!
    redirect_to root_path, alert: "Only taskers can access the wallet." unless current_user.tasker?
  end
end
