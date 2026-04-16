require 'rails_helper'

RSpec.describe "Task Status System", type: :system do
  let(:category) { create(:category) }
  let(:poster) { create(:user, active_role: :poster, onboarded: true) }
  let(:tasker) { create(:user, active_role: :tasker, onboarded: true) }
  let(:task) { create(:task, user: poster, category: category, budget: Money.new(1000_00, "NPR"), payment_type: :esewa, status: :open, location: "Kathmandu, Nepal") }
  let!(:bid) { create(:bid, task: task, user: tasker, amount: Money.new(1000_00, "NPR"), status: :accepted, message: "I can do this") }

  before do
    driven_by(:selenium_chrome_headless)
    sign_in poster
  end

  describe "Poster interactions" do
    it "can toggle draft status" do
      visit task_path(task)
      
      click_on "Move to Draft"
      expect(page).to have_content("Task is now draft")
      expect(task.reload.status).to eq("draft")
      
      click_on "Publish Task"
      expect(page).to have_content("Task is now open")
      expect(task.reload.status).to eq("open")
    end

    it "can release payment when pending" do
      # Set up state
      task.update!(status: :assigned)
      create(:payment_transaction, task: task, amount: task.budget, status: :completed)
      task.update!(status: :in_progress)
      task.update!(status: :pending_payment)
      
      allow(Payments::LedgerManager).to receive(:release_from_escrow)
      
      visit task_path(task)
      
      accept_confirm do
        click_on "Release Payment"
      end
      
      expect(page).to have_content("Payment released and task completed")
      expect(task.reload.status).to eq("completed")
    end

    it "can raise a dispute" do
      visit task_path(task)
      
      accept_confirm do
        click_on "I Have an Issue"
      end
      
      expect(page).to have_content("Dispute raised successfully")
      expect(task.reload.status).to eq("dispute")
    end
  end

  describe "Tasker interactions" do
    before do
      sign_in tasker
    end

    it "can request payment when in progress" do
      task.update!(status: :assigned)
      create(:payment_transaction, task: task, amount: task.budget, status: :completed)
      task.update!(status: :in_progress)
      
      visit task_path(task)
      
      accept_confirm do
        click_on "Request Payment"
      end
      
      expect(page).to have_content("Payment requested successfully")
      expect(task.reload.status).to eq("pending_payment")
    end
  end
end
