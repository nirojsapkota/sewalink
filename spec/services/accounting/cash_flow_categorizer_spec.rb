require 'rails_helper'

RSpec.describe Accounting::CashFlowCategorizer do
  self.use_transactional_tests = false

  let(:poster) { create(:user) }
  let(:tasker) { create(:user) }
  let(:category) { create(:category) }
  let(:task) { create(:task, user: poster, category: category, budget: Money.new(1000_00, "NPR")) }
  let!(:bid) { create(:bid, task: task, user: tasker, amount: Money.new(1000_00, "NPR"), status: :accepted) }

  let(:cash_poster) { create(:user) }
  let(:cash_tasker) { create(:user) }
  let(:cash_task) { create(:task, user: cash_poster, category: category, budget: Money.new(500_00, "NPR"), payment_type: :cash) }
  let!(:cash_bid) { create(:bid, task: cash_task, user: cash_tasker, amount: Money.new(500_00, "NPR"), status: :accepted) }

  before do
    task.reload
    cash_task.reload
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

  describe '.summary' do
    it 'categorizes deposits, releases, commission, refunds, and cash commission correctly' do
      Payments::LedgerManager.deposit_to_escrow(task)
      Payments::LedgerManager.release_from_escrow(task)
      Payments::LedgerManager.record_cash_commission(cash_task)

      commission_data = Payments::CommissionCalculator.call(task.budget)
      cash_commission_data = Payments::CommissionCalculator.call(cash_task.budget)

      summary = described_class.summary(from: 1.day.ago, to: 1.day.from_now)

      expect(summary[:escrow_deposits][:total_cents]).to eq(1000_00)
      expect(summary[:escrow_deposits][:count]).to eq(1)

      expect(summary[:escrow_releases][:total_cents]).to eq(commission_data[:tasker_share].cents)
      expect(summary[:escrow_releases][:count]).to eq(1)

      expect(summary[:commission_revenue][:total_cents]).to eq(commission_data[:commission].cents)
      expect(summary[:commission_revenue][:count]).to eq(1)

      expect(summary[:refunds][:total_cents]).to eq(0)
      expect(summary[:refunds][:count]).to eq(0)

      expect(summary[:cash_on_completion][:total_cents]).to eq(cash_commission_data[:commission].cents)
      expect(summary[:cash_on_completion][:count]).to eq(1)
    end

    it 'restricts by date range' do
      Payments::LedgerManager.deposit_to_escrow(task)

      summary = described_class.summary(from: 2.days.ago, to: 1.day.ago)
      expect(summary[:escrow_deposits][:total_cents]).to eq(0)
      expect(summary[:escrow_deposits][:count]).to eq(0)
    end
  end

  describe '.scope_for' do
    it 'excludes deposit lines from the refunds scope' do
      Payments::LedgerManager.deposit_to_escrow(task)

      expect(Accounting::CashFlowCategorizer.scope_for(:refunds)).to be_empty
      expect(Accounting::CashFlowCategorizer.scope_for(:escrow_deposits).count).to eq(1)
    end
  end

  describe '.label_for' do
    it 'returns the human-readable label for a category key' do
      expect(described_class.label_for(:escrow_deposits)).to eq("Escrow Deposits")
    end
  end
end
