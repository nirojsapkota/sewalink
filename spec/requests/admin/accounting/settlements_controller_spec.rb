require "rails_helper"

RSpec.describe "Admin::Accounting::Settlements", type: :request do
  self.use_transactional_tests = false

  let(:poster) { create(:user) }
  let(:tasker) { create(:user) }
  let(:category) { create(:category) }
  let(:task) { create(:task, user: poster, category: category, budget: Money.new(1000_00, "NPR")) }
  let!(:bid) { create(:bid, task: task, user: tasker, amount: Money.new(1000_00, "NPR"), status: :accepted) }

  before do
    task.reload
  end

  after(:each) do
    DoubleEntry::Line.delete_all
    DoubleEntry::AccountBalance.delete_all
    EsewaSettlement.delete_all
    AdminActivityLog.delete_all
    Conversation.delete_all
    Bid.delete_all
    Task.delete_all
    Category.delete_all
    User.delete_all
  end

  describe "GET /admin/accounting/settlements" do
    context "when user is an accountant" do
      let(:accountant) { create(:user, :accountant) }

      before { sign_in accountant }

      it "returns http success and computes the discrepancy" do
        Payments::LedgerManager.deposit_to_escrow(task)
        create(:esewa_settlement, amount_cents: 1000_00, settled_on: Date.current, imported_by: poster)

        get admin_accounting_settlements_path

        expect(response).to have_http_status(:success)
        expect(controller.instance_variable_get(:@discrepancy_cents)).to eq(0)
      end
    end

    context "when user is a plain user" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "redirects to root path" do
        get admin_accounting_settlements_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied. Admin only.")
      end
    end

    context "when user is unauthenticated" do
      it "redirects to login path" do
        get admin_accounting_settlements_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /admin/accounting/settlements" do
    let(:accountant) { create(:user, :accountant) }

    before { sign_in accountant }

    it "imports a valid CSV fixture and redirects with a success notice" do
      file = Rack::Test::UploadedFile.new(
        Rails.root.join("spec/fixtures/files/esewa_settlements_valid.csv"), "text/csv"
      )

      expect {
        post admin_accounting_settlements_path, params: { file: file }
      }.to change { EsewaSettlement.count }.by(2)

      expect(response).to redirect_to(admin_accounting_settlements_path)
      follow_redirect!
      expect(flash[:notice]).to match(/Imported 2 settlement rows/)
    end

    it "redirects to the new form with an alert for an oversized/wrong-type file" do
      bad_file = double(
        "UploadedFile",
        read: "transaction_ref,amount,date\nTXN1,10.00,2026-09-01\n",
        size: 10,
        original_filename: "settlements.exe",
        content_type: "application/octet-stream"
      )

      expect {
        post admin_accounting_settlements_path, params: { file: bad_file }
      }.not_to change { EsewaSettlement.count }

      expect(response).to redirect_to(new_admin_accounting_settlement_path)
      follow_redirect!
      expect(flash[:alert]).to match(/unsupported file type/i)
    end
  end
end
