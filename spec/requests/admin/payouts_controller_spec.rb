require 'rails_helper'

RSpec.describe "Admin::Payouts", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:tasker) { create(:user, active_role: :tasker, onboarded: true) }

  before do
    # Fund the tasker's ledger balance so PayoutRequest's sufficient_balance
    # validation passes on create.
    DoubleEntry.transfer(
      Money.new(5000_00, "NPR"),
      from: DoubleEntry.account(:user_external),
      to: DoubleEntry.account(:tasker_balance, scope: tasker),
      code: :deposit
    )
    sign_in admin
  end

  let(:payout_request) { create(:payout_request, user: tasker, amount_cents: 1000_00) }

  describe "PATCH /admin/payouts/:id/process_payout" do
    it "marks the payout as processed and deducts from the ledger" do
      expect {
        patch process_payout_admin_payout_path(payout_request)
      }.to change { DoubleEntry.account(:tasker_balance, scope: tasker).balance.cents }.by(-1000_00)

      expect(payout_request.reload.status).to eq("processed")
      expect(response).to redirect_to(admin_payouts_path)
      expect(flash[:notice]).to match(/processed/i)
    end

    it "logs the admin action" do
      expect {
        patch process_payout_admin_payout_path(payout_request)
      }.to change(AdminActivityLog, :count).by(1)

      expect(AdminActivityLog.last.action).to eq("process_payout")
    end

    it "does not raise a 500 when processing an already-processed payout" do
      payout_request.process!

      expect {
        patch process_payout_admin_payout_path(payout_request)
      }.not_to raise_error

      expect(response).to redirect_to(admin_payouts_path)
      expect(flash[:alert]).to match(/already been processed/i)
    end
  end

  describe "PATCH /admin/payouts/:id/reject_payout" do
    it "marks the payout as rejected with a reason" do
      patch reject_payout_admin_payout_path(payout_request), params: { rejection_reason: "Invalid bank details" }

      expect(payout_request.reload.status).to eq("rejected")
      expect(payout_request.rejection_reason).to eq("Invalid bank details")
      expect(response).to redirect_to(admin_payouts_path)
    end

    it "does not raise a 500 when rejecting an already-rejected payout" do
      payout_request.reject!

      expect {
        patch reject_payout_admin_payout_path(payout_request)
      }.not_to raise_error

      expect(response).to redirect_to(admin_payouts_path)
      expect(flash[:alert]).to match(/already been processed/i)
    end
  end

  describe "authorization" do
    it "denies non-admin users" do
      sign_out admin
      sign_in tasker

      patch process_payout_admin_payout_path(payout_request)

      expect(response).to redirect_to(root_path)
    end
  end
end
