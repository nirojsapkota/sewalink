require 'rails_helper'

RSpec.describe "Task Status Transitions", type: :request do
  let(:category) { create(:category) }
  let(:poster) { create(:user, active_role: :poster) }
  let(:tasker) { create(:user, active_role: :tasker) }
  let(:task) { create(:task, user: poster, category: category, budget: Money.new(1000_00, "NPR"), payment_type: :esewa, status: :open) }
  let!(:bid) { create(:bid, task: task, user: tasker, amount: Money.new(1000_00, "NPR"), status: :accepted, message: "I can do this") }

  before do
    sign_in poster
  end

  describe "PATCH /tasks/:id/toggle_draft" do
    it "toggles task between draft and open" do
      patch toggle_draft_task_path(task)
      expect(task.reload.status).to eq("draft")
      expect(response).to redirect_to(task_path(task, locale: :en))

      patch toggle_draft_task_path(task)
      expect(task.reload.status).to eq("open")
    end

    it "prevents unauthorized users from toggling draft" do
      sign_in create(:user, active_role: :poster, onboarded: true)
      patch toggle_draft_task_path(task)
      expect(response).to redirect_to(root_path(locale: :en))
      expect(flash[:alert]).to be_present
    end
  end

  describe "POST /tasks/:id/request_payment" do
    before do
      # Set task to assigned
      task.update!(status: :assigned)
      # Create payment to allow transition to in_progress
      create(:payment_transaction, task: task, amount: task.budget, status: :completed)
      task.update!(status: :in_progress)
      sign_in tasker
    end

    it "transitions task to pending_payment" do
      post request_payment_task_path(task)
      expect(task.reload.status).to eq("pending_payment")
      expect(response).to redirect_to(task_path(task, locale: :en))
    end

    it "prevents poster from requesting payment" do
      sign_in poster
      post request_payment_task_path(task)
      expect(response).to redirect_to(root_path(locale: :en))
    end
  end

  describe "POST /tasks/:id/release_payment" do
    before do
      # Set task to pending_payment
      task.update!(status: :assigned)
      create(:payment_transaction, task: task, amount: task.budget, status: :completed)
      task.update!(status: :in_progress)
      task.update!(status: :pending_payment)
      sign_in poster
    end

    it "transitions task to completed and releases escrow" do
      # Mock LedgerManager to avoid DoubleEntry issues in request spec
      allow(Payments::LedgerManager).to receive(:release_from_escrow)
      
      post release_payment_task_path(task)
      expect(task.reload.status).to eq("completed")
      expect(response).to redirect_to(task_path(task, locale: :en))
      expect(Payments::LedgerManager).to have_received(:release_from_escrow).with(task)
    end

    it "prevents tasker from releasing payment" do
      sign_in tasker
      post release_payment_task_path(task)
      expect(response).to redirect_to(root_path(locale: :en))
    end
  end

  describe "POST /tasks/:id/raise_dispute" do
    it "transitions task to dispute for poster" do
      post raise_dispute_task_path(task)
      expect(task.reload.status).to eq("dispute")
    end

    it "transitions task to dispute for tasker" do
      task.update!(status: :assigned)
      sign_in tasker
      post raise_dispute_task_path(task)
      expect(task.reload.status).to eq("dispute")
    end
  end
end
