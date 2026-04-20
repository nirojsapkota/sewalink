require 'rails_helper'

RSpec.describe "Admin Task Monitoring", type: :system do
  let(:admin) { create(:user, :admin) }
  let!(:open_task) { create(:task, status: :open, title: "Open Task") }
  let!(:completed_task) { create(:task, status: :completed, title: "Completed Task") }
  let!(:disputed_task) { create(:task, status: :dispute, title: "Disputed Task") }

  before do
    Capybara.current_session.driver.browser.manage.window.resize_to(1280, 1024) if Capybara.current_session.driver.browser.respond_to?(:manage)
    login_as(admin)
  end

  it "allows admin to view all tasks with status filters" do
    visit admin_tasks_path

    expect(page).to have_selector("h1", text: "Task Management")
    expect(page).to have_content("Open Task")
    expect(page).to have_content("Completed Task")
    expect(page).to have_content("Disputed Task")

    click_link "Dispute"
    expect(page).to have_content("Disputed Task")
    expect(page).not_to have_content("Open Task")
  end

  it "allows admin to view task details" do
    visit admin_tasks_path
    # Find the row with "Open Task" and click the "Show" link in that row
    within "tr", text: "Open Task" do
      click_link "Show", match: :first
    end

    expect(page).to have_content("Open Task")
    expect(page).to have_content("Details")
  end
end
