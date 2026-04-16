require 'rails_helper'

RSpec.describe "Payments", type: :request do
  let(:user) { create(:user, onboarded: true) }
  let(:task) { create(:task, user: user, budget: 500) }
  let(:product_code) { 'EPAYTEST' }

  before do
    sign_in user
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('ESEWA_PRODUCT_CODE', any_args).and_return(product_code)
    allow(ENV).to receive(:fetch).with('ESEWA_SECRET_KEY').and_return('8g8M898P8Go8atD8')

    # Stub Geocoder to avoid network requests
    allow(Geocoder).to receive(:search).and_return([
      double('location', latitude: 27.7172, longitude: 85.3240, address: "Kathmandu, Nepal", coordinates: [27.7172, 85.3240])
    ])
  end

  describe "POST /payments" do
    it "creates a payment transaction and renders checkout" do
      expect {
        post payments_path, params: { task_id: task.id }
      }.to change(PaymentTransaction, :count).by(1)

      expect(response).to render_template(:checkout)
      expect(assigns(:esewa_data)[:total_amount]).to eq(500.0)
    end
  end

  describe "GET /payments/success" do
    let(:payment) { create(:payment_transaction, task: task, amount_cents: 50000, status: :pending) }
    let(:encoded_data) do
      data = {
        transaction_uuid: payment.transaction_uuid,
        status: 'COMPLETE',
        total_amount: '500.0'
      }.to_json
      Base64.strict_encode64(data)
    end

    it "verifies payment and completes transaction" do
      expect(Payments::EsewaV2).to receive(:verify_payment)
        .with(payment.transaction_uuid, 500.0)
        .and_return(true)

      get success_payments_path, params: { data: encoded_data }

      expect(payment.reload.status).to eq('completed')
      expect(response).to redirect_to(task_path(task, locale: :en))
      expect(flash[:notice]).to be_present
    end

    it "fails transaction if verification fails" do
      expect(Payments::EsewaV2).to receive(:verify_payment)
        .with(payment.transaction_uuid, 500.0)
        .and_return(false)

      get success_payments_path, params: { data: encoded_data }

      expect(payment.reload.status).to eq('failed')
      expect(response).to redirect_to(task_path(task, locale: :en))
      expect(flash[:alert]).to be_present
    end
  end
end
