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

    it "sees a Pay Now button and can initiate eSewa checkout when the task is assigned and unpaid" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('ESEWA_PRODUCT_CODE', any_args).and_return('EPAYTEST')
      allow(ENV).to receive(:fetch).with('ESEWA_SECRET_KEY').and_return('8g8M898P8Go8atD8')

      task.update!(status: :assigned)

      visit task_path(task)

      expect(page).to have_content("Pay Now")

      click_on "Pay Now"

      # The checkout page auto-submits to the real eSewa domain via JS, which
      # isn't reachable in the test environment, so we can't assert on final
      # page content. Instead, wait for navigation away from the task page
      # (proving Turbo didn't silently swallow the request) before checking
      # that our own PaymentsController#create endpoint recorded a transaction.
      expect(page).to have_no_content("Pay Now (eSewa)")
      expect(PaymentTransaction.where(task: task).count).to eq(1)
    end

    it "does not see the Pay Now button once payment is completed" do
      task.update!(status: :assigned)
      create(:payment_transaction, task: task, amount: task.budget, status: :completed)

      visit task_path(task)

      expect(page).not_to have_content("Pay Now")
      expect(page).to have_content("Payment confirmed")
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
