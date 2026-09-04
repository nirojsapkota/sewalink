require "rails_helper"

RSpec.describe Accounting::ReconciliationMatcher do
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
    Conversation.delete_all
    Bid.delete_all
    Task.delete_all
    Category.delete_all
    User.delete_all
  end

  describe ".call" do
    it "marks a settlement matched when exactly one matching escrow-deposit line exists" do
      Payments::LedgerManager.deposit_to_escrow(task)

      settlement = create(:esewa_settlement, amount_cents: 1000_00, settled_on: Date.current, imported_by: poster)

      described_class.call(settlement)
      settlement.reload

      expect(settlement.status).to eq("matched")
      expect(settlement.matched_line_id).to be_present

      matched_line = DoubleEntry::Line.find(settlement.matched_line_id)
      expect(matched_line[:account]).to eq("escrow")
      expect(matched_line[:code]).to eq("deposit")
    end

    it "marks a settlement mismatched when no matching escrow-deposit line exists" do
      Payments::LedgerManager.deposit_to_escrow(task)

      settlement = create(:esewa_settlement, amount_cents: 999_99, settled_on: Date.current, imported_by: poster)

      described_class.call(settlement)
      settlement.reload

      expect(settlement.status).to eq("mismatched")
      expect(settlement.matched_line_id).to be_nil
    end

    it "marks a settlement mismatched when multiple matching escrow-deposit lines exist" do
      other_task = create(:task, user: poster, category: category, budget: Money.new(1000_00, "NPR"))
      create(:bid, task: other_task, user: tasker, amount: Money.new(1000_00, "NPR"), status: :accepted)
      other_task.reload

      Payments::LedgerManager.deposit_to_escrow(task)
      Payments::LedgerManager.deposit_to_escrow(other_task)

      settlement = create(:esewa_settlement, amount_cents: 1000_00, settled_on: Date.current, imported_by: poster)

      described_class.call(settlement)
      settlement.reload

      expect(settlement.status).to eq("mismatched")
      expect(settlement.matched_line_id).to be_nil
    end
  end

  describe ".call_all" do
    it "matches every unmatched settlement in the given relation" do
      Payments::LedgerManager.deposit_to_escrow(task)
      settlement = create(:esewa_settlement, amount_cents: 1000_00, settled_on: Date.current, imported_by: poster, status: "unmatched")

      described_class.call_all(EsewaSettlement.where(status: "unmatched"))

      expect(settlement.reload.status).to eq("matched")
    end
  end
end
