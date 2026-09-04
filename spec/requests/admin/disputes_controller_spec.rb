require 'rails_helper'

RSpec.describe "Admin::Disputes", type: :request do
  describe "Payments::LedgerManager.split_escrow" do
    self.use_transactional_tests = false

    let(:poster) { create(:user) }
    let(:tasker) { create(:user) }
    let(:category) { create(:category) }
    let(:task) { create(:task, user: poster, category: category, budget: Money.new(1000_00, "NPR")) }
    let!(:bid) { create(:bid, task: task, user: tasker, amount: Money.new(1000_00, "NPR"), status: :accepted) }

    before do
      task.reload
      Payments::LedgerManager.deposit_to_escrow(task)
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

    it "splits the escrow 60/40 between tasker and poster and empties escrow" do
      expect {
        Payments::LedgerManager.split_escrow(task, 60)
      }.to change { DoubleEntry.account(:escrow, scope: task).balance.cents }.from(1000_00).to(0)
       .and change { DoubleEntry.account(:tasker_balance, scope: tasker).balance.cents }.by(600_00)
    end
  end

  describe "PATCH /admin/disputes/:id/resolve" do
    let(:admin) { create(:user, :admin) }
    let(:poster) { create(:user) }
    let(:tasker) { create(:user) }
    let(:task) { create(:task, :completed, user: poster, status: :dispute) }
    let!(:bid) { create(:bid, task: task, user: tasker, status: :accepted) }

    before { sign_in admin }

    context "with decision: split" do
      it "calls split_escrow, marks the task completed, and logs the resolution" do
        allow(Payments::LedgerManager).to receive(:split_escrow)

        expect {
          patch resolve_admin_dispute_path(task), params: { decision: "split", tasker_percentage: "60" }
        }.to change(AdminActivityLog, :count).by(1)

        expect(Payments::LedgerManager).to have_received(:split_escrow).with(task, 60.0)
        expect(task.reload.status).to eq("completed")

        log = AdminActivityLog.last
        expect(log.action).to eq("resolve_dispute")
        expect(JSON.parse(log.details)).to eq({ "decision" => "split", "tasker_percentage" => 60 })
      end

      it "rejects an out-of-range percentage without calling split_escrow" do
        allow(Payments::LedgerManager).to receive(:split_escrow)

        patch resolve_admin_dispute_path(task), params: { decision: "split", tasker_percentage: "150" }

        expect(Payments::LedgerManager).not_to have_received(:split_escrow)
        expect(flash[:alert]).to match(/valid.*percentage/i)
        expect(task.reload.status).to eq("dispute")
      end
    end

    context "with decision: reopen" do
      it "rejects the accepted bid, reopens the task, and logs the resolution" do
        expect {
          patch resolve_admin_dispute_path(task), params: { decision: "reopen" }
        }.to change(AdminActivityLog, :count).by(1)

        expect(task.reload.status).to eq("open")
        expect(bid.reload.status).to eq("rejected")

        log = AdminActivityLog.last
        expect(log.action).to eq("resolve_dispute")
        expect(JSON.parse(log.details)).to eq({ "decision" => "reopen" })
      end
    end
  end
end
