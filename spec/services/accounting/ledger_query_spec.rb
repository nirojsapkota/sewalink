require 'rails_helper'

RSpec.describe Accounting::LedgerQuery do
  self.use_transactional_tests = false

  let(:category) { create(:category) }

  let(:poster_a) { create(:user) }
  let(:tasker_a) { create(:user) }
  let(:task_a) { create(:task, user: poster_a, category: category, budget: Money.new(1000_00, "NPR")) }
  let!(:bid_a) { create(:bid, task: task_a, user: tasker_a, amount: Money.new(1000_00, "NPR"), status: :accepted) }

  let(:poster_b) { create(:user) }
  let(:tasker_b) { create(:user) }
  let(:task_b) { create(:task, user: poster_b, category: category, budget: Money.new(500_00, "NPR")) }
  let!(:bid_b) { create(:bid, task: task_b, user: tasker_b, amount: Money.new(500_00, "NPR"), status: :accepted) }

  before do
    task_a.reload
    task_b.reload
    Payments::LedgerManager.deposit_to_escrow(task_a)
    Payments::LedgerManager.release_from_escrow(task_a)
    Payments::LedgerManager.deposit_to_escrow(task_b)
    Payments::LedgerManager.release_from_escrow(task_b)
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

  describe '.call' do
    it 'restricts to escrow lines only when account filter given' do
      result = described_class.call(account: "escrow")
      expect(result).to be_present
      expect(result.pluck(:account).uniq).to eq(["escrow"])
    end

    it 'returns no lines when filtering by a code that was never created' do
      result = described_class.call(code: "refund")
      expect(result).to be_empty
    end

    it 'restricts to a given user\'s escrow lines only' do
      result = described_class.call(user_id: poster_a.id)
      expect(result).to be_present
      expect(result.pluck(:scope).uniq).to eq([task_a.id.to_s])
    end

    it 'combines account and code filters' do
      result = described_class.call(account: "escrow", code: "deposit")
      expect(result.count).to eq(2)
    end

    it 'restricts by date range' do
      result = described_class.call(from: 2.days.ago, to: 1.day.ago)
      expect(result).to be_empty
    end
  end
end
