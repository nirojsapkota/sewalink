require 'rails_helper'

RSpec.describe "Admin Dispute Resolution", type: :system do
  let(:admin) { create(:user, :admin) }
  let(:poster) { create(:user, name: "John Poster") }
  let(:tasker) { create(:user, name: "Jane Tasker") }
  let(:task) { create(:task, :completed, user: poster, title: "Disputed Task") }
  let!(:bid) { create(:bid, task: task, user: tasker, status: :accepted) }

  before do
    Capybara.current_session.driver.browser.manage.window.resize_to(1280, 1024) if Capybara.current_session.driver.browser.respond_to?(:manage)
    task.update!(status: :dispute)
    login_as(admin)
  end

  it "allows admin to view dispute details and evidence" do
    create(:dispute_evidence, task: task, user: poster, description: "I never got the work done.")
    
    visit admin_disputes_path
    click_link "Resolve Dispute"

    expect(page).to have_content("Dispute Resolution: Disputed Task")
    expect(page).to have_content("I never got the work done.")
    expect(page).to have_content("John Poster")
  end

  it "allows admin to release funds to the tasker" do
    visit admin_dispute_path(task)
    
    # We should stub the ledger manager if it's complex, but here we can just check the status
    click_button "Release to Tasker"

    expect(page).to have_content("Dispute resolved: Funds released to tasker.")
    expect(task.reload.status).to eq('completed')
  end

  it "allows admin to refund funds to the poster" do
    # Ensure refund_poster works or is stubbed
    allow(Payments::LedgerManager).to receive(:refund_poster).with(task).and_return(true)

    visit admin_dispute_path(task)
    click_button "Refund to Poster"

    expect(page).to have_content("Dispute resolved: Funds refunded to poster.")
    expect(task.reload.status).to eq('cancelled')
  end
end
