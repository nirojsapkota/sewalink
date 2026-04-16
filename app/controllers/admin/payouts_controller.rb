class Admin::PayoutsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!

  def index
    @pending_payouts = PayoutRequest.pending.includes(:user).order(created_at: :asc)
    @processed_payouts = PayoutRequest.processed.includes(:user).order(created_at: :desc).limit(50)
  end

  def process_payout
    @payout = PayoutRequest.find(params[:id])
    if @payout.process!
      redirect_to admin_payouts_path, notice: "Payout for #{@payout.user.phone} marked as processed and ledger updated."
    else
      redirect_to admin_payouts_path, alert: "Could not process payout."
    end
  end

  def reject_payout
    @payout = PayoutRequest.find(params[:id])
    @payout.rejection_reason = params[:rejection_reason]
    if @payout.reject!
      redirect_to admin_payouts_path, notice: "Payout request rejected."
    else
      redirect_to admin_payouts_path, alert: "Could not reject payout."
    end
  end

  private

  def ensure_admin!
    redirect_to root_path, alert: "Access denied. Admin only." unless current_user.admin?
  end
end
