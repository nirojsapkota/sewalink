require 'rails_helper'

RSpec.describe "Admin User Management", type: :system do
  let!(:admin) { create(:user, :admin, phone: "9812345678") }
  let!(:regular_user) { create(:user, phone: "9800000000", name: "Regular User") }

  before do
    driven_by(:rack_test)
  end

  context "as an admin" do
    before do
      sign_in admin
      visit admin_users_path
    end

    it "lists users" do
      expect(page).to have_content("Users")
      expect(page).to have_content(admin.phone)
      expect(page).to have_content(regular_user.phone)
    end

    it "can search users by phone" do
      fill_in "Search by phone...", with: "980000"
      click_button "Search"

      expect(page).to have_content(regular_user.phone)
      expect(page).not_to have_content(admin.phone)
    end

    it "can view user details and stats" do
      # Create some activity
      create(:task, user: regular_user) # Posted
      create(:task, :completed, user: regular_user) # Completed as poster
      
      # Completed as tasker
      task = create(:task, :completed)
      create(:bid, task: task, user: regular_user, status: :accepted)

      visit admin_user_path(regular_user)

      expect(page).to have_content("User: #{regular_user.phone}")
      expect(page).to have_content("Regular User")
      
      # Using a more flexible selector for stats
      expect(page).to have_content("Total Tasks Posted 2")
      expect(page).to have_content("Tasks Completed (as Poster) 1")
      expect(page).to have_content("Tasks Completed (as Tasker) 1")
    end
  end

  context "as a regular user" do
    before do
      sign_in regular_user
    end

    it "is redirected to root" do
      visit admin_users_path
      expect(page).to have_current_path(root_path)
      expect(page).to have_content("Access denied. Admin only.")
    end
  end
end
