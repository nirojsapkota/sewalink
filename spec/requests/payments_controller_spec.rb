require 'rails_helper'

RSpec.describe "Payments", type: :request do
  self.use_transactional_tests = false

  let(:user) { create(:user, onboarded: true) }
  let(:task) { create(:task, user: user, budget: 500, payment_type: :esewa, status: :assigned) }
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

  after(:each) do
    PaymentTransaction.delete_all
    Task.delete_all
    Category.delete_all
    User.delete_all
  end

  describe "POST /payments" do
    it "creates a payment transaction and renders checkout" do
      expect {
        post payments_path, params: { task_id: task.id }
      }.to change(PaymentTransaction, :count).by(1)

      expect(response).to render_template(:checkout)
      expect(assigns(:esewa_data)[:total_amount]).to eq(500.0)
    end

    it "reuses an existing pending transaction instead of creating a duplicate" do
      post payments_path, params: { task_id: task.id }
      first_uuid = assigns(:payment).transaction_uuid

      expect {
        post payments_path, params: { task_id: task.id }
      }.not_to change(PaymentTransaction, :count)

      expect(assigns(:payment).transaction_uuid).to eq(first_uuid)
    end

    it "denies access when the current user is not the task's poster" do
      other_user = create(:user, onboarded: true, active_role: :poster)
      sign_in other_user

      expect {
        post payments_path, params: { task_id: task.id }
      }.not_to change(PaymentTransaction, :count)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end

    it "denies access for a cash task" do
      cash_task = create(:task, user: user, budget: 500, payment_type: :cash, status: :assigned)

      expect {
        post payments_path, params: { task_id: cash_task.id }
      }.not_to change(PaymentTransaction, :count)

      expect(response).to redirect_to(root_path)
    end

    it "denies access when the task is already paid" do
      create(:payment_transaction, task: task, amount_cents: 50000, status: :completed)

      expect {
        post payments_path, params: { task_id: task.id }
      }.not_to change(PaymentTransaction, :count)

      expect(response).to redirect_to(root_path)
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
      expect(response).to redirect_to(task_path(task))
      expect(flash[:notice]).to be_present
    end

    it "fails transaction if verification fails" do
      expect(Payments::EsewaV2).to receive(:verify_payment)
        .with(payment.transaction_uuid, 500.0)
        .and_return(false)

      get success_payments_path, params: { data: encoded_data }

      expect(payment.reload.status).to eq('failed')
      expect(response).to redirect_to(task_path(task))
      expect(flash[:alert]).to be_present
    end

    it "denies access when the signed-in user is not the task's poster" do
      other_user = create(:user, onboarded: true, active_role: :poster)
      sign_in other_user

      expect(Payments::EsewaV2).not_to receive(:verify_payment)

      get success_payments_path, params: { data: encoded_data }

      expect(payment.reload.status).to eq('pending')
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end
  end
end
