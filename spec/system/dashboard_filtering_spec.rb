require 'rails_helper'

RSpec.describe "Dashboard Filtering", type: :system do
  let(:poster) { create(:user, active_role: :poster, onboarded: true) }
  let(:category) { create(:category) }
  
  before do
    driven_by(:selenium_chrome_headless)
    
    # Create tasks with different statuses
    create(:task, user: poster, category: category, status: :draft, title: "Draft Task")
    create(:task, user: poster, category: category, status: :open, title: "Open Task")
    create(:task, user: poster, category: category, status: :completed, title: "Completed Task")
    create(:task, user: poster, category: category, status: :dispute, title: "Dispute Task")
    
    sign_in poster
  end

  it "filters tasks by status using tabs" do
    visit poster_dashboard_path
    
    expect(page).to have_content("Draft Task")
    expect(page).to have_content("Open Task")
    expect(page).to have_content("Completed Task")
    expect(page).to have_content("Dispute Task")
    
    click_on "Drafts"
    expect(page).to have_content("Draft Task")
    expect(page).not_to have_content("Open Task")
    
    click_on "Active"
    expect(page).to have_content("Open Task")
    expect(page).not_to have_content("Draft Task")
    
    click_on "Completed"
    expect(page).to have_content("Completed Task")
    expect(page).not_to have_content("Open Task")
    
    click_on "Dispute"
    expect(page).to have_content("Dispute Task")
    expect(page).not_to have_content("Completed Task")
    
    click_on "All"
    expect(page).to have_content("Draft Task")
    expect(page).to have_content("Completed Task")
  end

  it "shows a confirmation dialog for critical actions" do
    task = create(:task, user: poster, category: category, status: :pending_payment, title: "Confirmable Task")
    visit task_path(task)
    
    # Click but cancel
    dismiss_confirm do
      click_on "Release Payment"
    end
    expect(task.reload.status).to eq("pending_payment")
    
    # Click and accept
    # Mock LedgerManager since it's called on completion
    allow(Payments::LedgerManager).to receive(:release_from_escrow)
    
    accept_confirm do
      click_on "Release Payment"
    end
    expect(page).to have_content("Payment released and task completed")
    expect(task.reload.status).to eq("completed")
  end
end
