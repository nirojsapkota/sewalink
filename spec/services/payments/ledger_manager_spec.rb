require 'rails_helper'

RSpec.describe Payments::LedgerManager do
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
    Bid.delete_all
    Task.delete_all
    Category.delete_all
    User.delete_all
  end

  describe '.deposit_to_escrow' do
    it 'moves budget from :user_external to :escrow' do
      expect {
        described_class.deposit_to_escrow(task)
      }.to change { DoubleEntry.account(:escrow, scope: task).balance.cents }.from(0).to(1000_00)
    end

    it 'is idempotent' do
      described_class.deposit_to_escrow(task)
      expect {
        described_class.deposit_to_escrow(task)
      }.not_to change { DoubleEntry.account(:escrow, scope: task).balance.cents }
    end
  end

  describe '.release_from_escrow' do
    before { described_class.deposit_to_escrow(task) }

    it 'moves funds from :escrow to :tasker_balance and :platform_revenue' do
      commission_data = Payments::CommissionCalculator.call(task.budget)
      
      expect {
        described_class.release_from_escrow(task)
      }.to change { DoubleEntry.account(:escrow, scope: task).balance.cents }.from(1000_00).to(0)
       .and change { DoubleEntry.account(:tasker_balance, scope: tasker).balance.cents }.by(commission_data[:tasker_share].cents)
       .and change { DoubleEntry.account(:platform_revenue).balance.cents }.by(commission_data[:commission].cents)
    end

    it 'is idempotent' do
      described_class.release_from_escrow(task)
      expect {
        described_class.release_from_escrow(task)
      }.not_to change { DoubleEntry.account(:tasker_balance, scope: tasker).balance.cents }
    end
  end
end
