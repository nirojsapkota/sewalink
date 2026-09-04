require 'rails_helper'

RSpec.describe "Admin::Accounting::Reports", type: :request do
  self.use_transactional_tests = false

  let(:poster) { create(:user) }
  let(:tasker) { create(:user) }
  let(:category) { create(:category) }

  let(:digital_task) { create(:task, user: poster, category: category, budget: Money.new(1000_00, "NPR"), payment_type: :esewa) }
  let!(:digital_bid) { create(:bid, task: digital_task, user: tasker, amount: Money.new(1000_00, "NPR"), status: :accepted) }

  let(:cash_task) { create(:task, user: poster, category: category, budget: Money.new(500_00, "NPR"), payment_type: :cash) }
  let!(:cash_bid) { create(:bid, task: cash_task, user: tasker, amount: Money.new(500_00, "NPR"), status: :accepted) }

  let(:refund_task) { create(:task, user: poster, category: category, budget: Money.new(300_00, "NPR"), payment_type: :esewa) }
  let!(:refund_bid) { create(:bid, task: refund_task, user: tasker, amount: Money.new(300_00, "NPR"), status: :accepted) }

  before do
    digital_task.reload
    cash_task.reload
    refund_task.reload
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

  describe "GET /admin/accounting/reports" do
    context "when user is an accountant" do
      let(:accountant) { create(:user, :accountant) }

      before { sign_in accountant }

      it "returns http success and assigns commission/refund totals grouped by day" do
        Payments::LedgerManager.deposit_to_escrow(digital_task)
        Payments::LedgerManager.release_from_escrow(digital_task)
        Payments::LedgerManager.record_cash_commission(cash_task)

        Payments::LedgerManager.deposit_to_escrow(refund_task)
        Payments::LedgerManager.refund_poster(refund_task)

        expected_digital_commission = Payments::CommissionCalculator.call(digital_task.budget)[:commission]
        expected_cash_commission = Payments::CommissionCalculator.call(cash_task.budget)[:commission]
        expected_commission_total = (expected_digital_commission.cents + expected_cash_commission.cents) / 100.0
        expected_refund_total = refund_task.budget.cents / 100.0

        get admin_accounting_reports_path(period: "day")

        expect(response).to have_http_status(:success)
        expect(controller.instance_variable_get(:@period)).to eq("day")

        commission_by_period = controller.instance_variable_get(:@commission_by_period)
        refunds_by_period = controller.instance_variable_get(:@refunds_by_period)
        net_revenue_by_period = controller.instance_variable_get(:@net_revenue_by_period)

        today_key = commission_by_period.keys.last
        expect(commission_by_period[today_key]).to eq(expected_commission_total)
        expect(refunds_by_period[today_key]).to eq(expected_refund_total)
        expect(net_revenue_by_period[today_key]).to eq(expected_commission_total)
      end

      it "groups by month when period=month" do
        get admin_accounting_reports_path(period: "month")

        expect(response).to have_http_status(:success)
        expect(controller.instance_variable_get(:@period)).to eq("month")
      end

      it "falls back to day for an invalid period param" do
        get admin_accounting_reports_path(period: "bogus")

        expect(response).to have_http_status(:success)
        expect(controller.instance_variable_get(:@period)).to eq("day")
      end

      it "renders the period toggle, table, and chart" do
        Payments::LedgerManager.deposit_to_escrow(digital_task)
        Payments::LedgerManager.release_from_escrow(digital_task)

        get admin_accounting_reports_path(period: "day")

        expect(response.body).to include("Period Reports")
        expect(response.body).to include("Daily")
        expect(response.body).to include("Monthly")

        expected_digital_commission = Payments::CommissionCalculator.call(digital_task.budget)[:commission]
        expect(response.body).to include(ApplicationController.helpers.number_to_currency(expected_digital_commission.cents / 100.0, unit: "Rs. "))
      end
    end

    context "when user is a super_admin" do
      let(:super_admin) { create(:user, :super_admin) }

      before { sign_in super_admin }

      it "returns http success" do
        get admin_accounting_reports_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is a plain user" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "redirects to root path" do
        get admin_accounting_reports_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied. Admin only.")
      end
    end

    context "when user is unauthenticated" do
      it "redirects to login path" do
        get admin_accounting_reports_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
