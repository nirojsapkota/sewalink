require 'rails_helper'

RSpec.describe "Admin::Accounting::Dashboards", type: :request do
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
    Conversation.delete_all
    Bid.delete_all
    Task.delete_all
    Category.delete_all
    User.delete_all
  end

  describe "GET /admin/accounting/dashboard" do
    context "when user is an accountant" do
      let(:accountant) { create(:user, :accountant) }

      before { sign_in accountant }

      it "returns http success and assigns category summary for the given date range" do
        Payments::LedgerManager.deposit_to_escrow(task)

        travel_to 2.days.ago do
          old_poster = create(:user)
          old_category = create(:category)
          old_task = create(:task, user: old_poster, category: old_category, budget: Money.new(300_00, "NPR"))
          old_tasker = create(:user)
          create(:bid, task: old_task, user: old_tasker, amount: Money.new(300_00, "NPR"), status: :accepted)
          old_task.reload
          Payments::LedgerManager.deposit_to_escrow(old_task)
        end

        get admin_accounting_dashboard_path(from: Date.current.to_s, to: Date.current.to_s)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Cash Flow Dashboard")

        summary = controller.instance_variable_get(:@summary)
        expect(summary[:escrow_deposits][:total_cents]).to eq(1000_00)
        expect(summary[:escrow_deposits][:count]).to eq(1)
      end

      it "defaults to the last 30 days when no params are given" do
        get admin_accounting_dashboard_path

        expect(response).to have_http_status(:success)
        expect(controller.instance_variable_get(:@from)).to eq(30.days.ago.to_date)
        expect(controller.instance_variable_get(:@to)).to eq(Date.current)
      end
    end

    context "when user is a super_admin" do
      let(:super_admin) { create(:user, :super_admin) }

      before { sign_in super_admin }

      it "returns http success" do
        get admin_accounting_dashboard_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is a plain user" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "redirects to root path" do
        get admin_accounting_dashboard_path
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Access denied. Admin only.")
      end
    end

    context "when user is unauthenticated" do
      it "redirects to login path" do
        get admin_accounting_dashboard_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /admin/accounting/dashboard/:category" do
    let(:accountant) { create(:user, :accountant) }

    before { sign_in accountant }

    it "lists contributing transactions for the category" do
      Payments::LedgerManager.deposit_to_escrow(task)

      get admin_accounting_dashboard_category_path(category: "escrow_deposits", from: Date.current.to_s, to: Date.current.to_s)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(humanized_money_with_symbol(task.budget))
    end

    it "redirects to the dashboard with an alert for an unknown category" do
      get admin_accounting_dashboard_category_path(category: "bogus", from: Date.current.to_s, to: Date.current.to_s)

      expect(response).to redirect_to(admin_accounting_dashboard_path)
      follow_redirect!
      expect(response.body).to include("Unknown category.")
    end
  end
end
