require 'rails_helper'

RSpec.describe Payments::LedgerManager do
  let(:category) { Category.create!(name_en: "Cleaning", name_ne: "सफाई") }
  let(:poster) { User.create!(phone: "9800000000", email: "poster@example.com", password: "password", active_role: :poster) }
  let(:tasker) { User.create!(phone: "9800000001", email: "tasker@example.com", password: "password", active_role: :tasker) }
  let(:task) { Task.create!(user: poster, category: category, title: "Cleaning Task", description: "Clean my room", budget_cents: 100000, location: "Kathmandu, Nepal", status: :assigned, payment_type: :cash) }
  let!(:bid) { Bid.create!(task: task, user: tasker, amount: 1000, status: :accepted, payment_method: :cash, message: "I can do this") }

  describe ".record_cash_commission" do
    it "deducts commission from tasker balance and adds to platform revenue" do
      initial_tasker_balance = DoubleEntry.account(:tasker_balance, scope: tasker).balance
      initial_platform_revenue = DoubleEntry.account(:platform_revenue).balance

      Payments::LedgerManager.record_cash_commission(task)

      commission_data = Payments::CommissionCalculator.call(task.budget)
      
      expect(DoubleEntry.account(:tasker_balance, scope: tasker).balance).to eq(initial_tasker_balance - commission_data[:commission])
      expect(DoubleEntry.account(:platform_revenue).balance).to eq(initial_platform_revenue + commission_data[:commission])
    end
  end
end
