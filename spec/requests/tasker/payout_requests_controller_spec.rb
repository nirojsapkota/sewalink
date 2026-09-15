require 'rails_helper'

RSpec.describe "Tasker::PayoutRequests", type: :request do
  let(:tasker) { create(:user, active_role: :tasker, onboarded: true) }

  before do
    DoubleEntry.transfer(
      Money.new(2000_00, "NPR"),
      from: DoubleEntry.account(:user_external),
      to: DoubleEntry.account(:tasker_balance, scope: tasker),
      code: :deposit
    )
    sign_in tasker
  end

  describe "POST /tasker/payout_requests" do
    it "creates a pending payout request for the current user" do
      expect {
        post tasker_payout_requests_path, params: { payout_request: { amount: 1000, payment_details: "eSewa: 9800000000" } }
      }.to change(PayoutRequest, :count).by(1)

      request = PayoutRequest.last
      expect(request.user).to eq(tasker)
      expect(request.status).to eq("pending")
      expect(response).to redirect_to(tasker_wallet_path)
    end

    it "rejects a request exceeding the current balance" do
      expect {
        post tasker_payout_requests_path, params: { payout_request: { amount: 5000, payment_details: "eSewa: 9800000000" } }
      }.not_to change(PayoutRequest, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "denies non-tasker users" do
      poster = create(:user, active_role: :poster, onboarded: true)
      sign_in poster

      post tasker_payout_requests_path, params: { payout_request: { amount: 1000, payment_details: "eSewa: 9800000000" } }

      expect(response).to redirect_to(root_path)
    end
  end
end
