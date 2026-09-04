require 'rails_helper'

RSpec.describe "Admin::Accounting::LedgerEntries", type: :request do
  self.use_transactional_tests = false

  let(:poster) { create(:user) }
  let(:tasker) { create(:user) }
  let(:category) { create(:category) }
  let(:task) { create(:task, user: poster, category: category, budget: Money.new(1000_00, "NPR")) }
  let!(:bid) { create(:bid, task: task, user: tasker, amount: Money.new(1000_00, "NPR"), status: :accepted) }

  let(:other_poster) { create(:user) }
  let(:other_tasker) { create(:user) }
  let(:other_category) { create(:category) }
  let(:other_task) { create(:task, user: other_poster, category: other_category, budget: Money.new(500_00, "NPR")) }
  let!(:other_bid) { create(:bid, task: other_task, user: other_tasker, amount: Money.new(500_00, "NPR"), status: :accepted) }

  before do
    task.reload
    other_task.reload
  end

  after(:each) do
    DoubleEntry::Line.delete_all
    DoubleEntry::AccountBalance.delete_all
    AdminActivityLog.delete_all
    Conversation.delete_all
    Bid.delete_all
    Task.delete_all
    Category.delete_all
    User.delete_all
  end

  describe "GET /admin/accounting/ledger" do
    context "when user is an accountant" do
      let(:accountant) { create(:user, :accountant) }

      before { sign_in accountant }

      it "returns http success and lists recent lines with no filters" do
        Payments::LedgerManager.deposit_to_escrow(task)
        Payments::LedgerManager.deposit_to_escrow(other_task)

        get admin_accounting_ledger_index_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Transaction Ledger")
      end

      it "filters by account" do
        Payments::LedgerManager.deposit_to_escrow(task)
        Payments::LedgerManager.release_from_escrow(task)

        get admin_accounting_ledger_index_path(account: "escrow")

        expect(response).to have_http_status(:success)
        lines = controller.instance_variable_get(:@lines)
        expect(lines).to be_present
        expect(lines.map { |l| l[:account] }.uniq).to eq(["escrow"])
      end

      it "filters by code" do
        Payments::LedgerManager.deposit_to_escrow(task)
        Payments::LedgerManager.release_from_escrow(task)

        get admin_accounting_ledger_index_path(code: "refund")

        expect(response).to have_http_status(:success)
        lines = controller.instance_variable_get(:@lines)
        expect(lines.map { |l| l[:code] }.uniq - ["refund"]).to be_empty
      end

      it "filters by date range" do
        Payments::LedgerManager.deposit_to_escrow(task)

        get admin_accounting_ledger_index_path(from: 1.day.ago.to_date.to_s, to: Date.current.to_s)

        expect(response).to have_http_status(:success)
        lines = controller.instance_variable_get(:@lines)
        expect(lines).to be_present
      end

      it "filters by user_id to only that poster's lines" do
        Payments::LedgerManager.deposit_to_escrow(task)
        Payments::LedgerManager.deposit_to_escrow(other_task)

        get admin_accounting_ledger_index_path(user_id: poster.id)

        expect(response).to have_http_status(:success)
        lines = controller.instance_variable_get(:@lines)
        expect(lines).to be_present
        expect(lines.map { |l| l[:scope] }.uniq).to eq([task.id.to_s])
      end

      it "redirects with an alert for invalid date format" do
        get admin_accounting_ledger_index_path(from: "not-a-date")

        expect(response).to redirect_to(admin_accounting_ledger_index_path)
        follow_redirect!
        expect(response.body).to include("Invalid date format.")
      end
    end

    context "when user is a plain user" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "redirects to root path" do
        get admin_accounting_ledger_index_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied. Admin only.")
      end
    end

    context "when user is unauthenticated" do
      it "redirects to login path" do
        get admin_accounting_ledger_index_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /admin/accounting/ledger/:id" do
    let(:accountant) { create(:user, :accountant) }

    before { sign_in accountant }

    it "shows the line, its paired line, and linked task context" do
      Payments::LedgerManager.deposit_to_escrow(task)
      line = DoubleEntry::Line.where(account: "escrow", scope: task.id.to_s).first

      get admin_accounting_ledger_path(line.id)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(task.title)
      expect(response.body).to include(task.status)
    end

    it "shows dispute resolution decision for a task with resolution history" do
      Payments::LedgerManager.deposit_to_escrow(task)
      task.update!(status: :dispute)
      Payments::LedgerManager.refund_poster(task)
      AdminActivityLog.record!(admin: accountant, action: "resolve_dispute", target: task, details: { decision: "refund" })

      line = DoubleEntry::Line.where(account: "escrow", scope: task.id.to_s, code: "refund").first

      get admin_accounting_ledger_path(line.id)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("refund")
    end

    it "shows the linked user for a tasker_balance line" do
      Payments::LedgerManager.deposit_to_escrow(task)
      Payments::LedgerManager.release_from_escrow(task)
      line = DoubleEntry::Line.where(account: "tasker_balance", scope: tasker.id.to_s).first

      get admin_accounting_ledger_path(line.id)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(tasker.first_name)
    end

    it "redirects to the index with an alert for a non-existent id" do
      get admin_accounting_ledger_path(999_999_999)

      expect(response).to redirect_to(admin_accounting_ledger_index_path)
      follow_redirect!
      expect(response.body).to include("Transaction not found.")
    end
  end
end
