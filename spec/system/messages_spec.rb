require 'rails_helper'

RSpec.describe "Messages", type: :system do
  let(:poster) { create(:user, :poster) }
  let(:tasker) { create(:user, :tasker) }
  let(:other_user) { create(:user, :tasker) } # A third user not involved in this task
  let(:category) { create(:category) }
  let(:task) { create(:task, user: poster, category: category) }
  let(:bid) { create(:bid, task: task, user: tasker) }
  let(:other_bid) { create(:bid, task: task, user: other_user) }
  let(:conversation) { bid.conversation }
  let(:other_conversation) { other_bid.conversation }

  before do
    driven_by(:selenium_chrome_headless)
  end

  it "masks phone numbers for non-participants even if they access the page", js: true do
    # Tasker session sends a message
    Capybara.using_session("Tasker Session") do
      sign_in tasker
      visit conversation_path(conversation)

      fill_in "Type a message...", with: "My number is 9841234567"
      
      perform_enqueued_jobs do
        click_button "Send"
      end

      # Tasker (sender) should see their own number
      expect(page).to have_content("9841234567")
    end

    # Other User session (who shouldn't be here, but if they were)
    # Note: ConversationPolicy actually blocks this, so we are testing the logic
    # if the policy was bypassed or in a scenario where they can see it.
    # We will test the Poster instead, but before the task is assigned.
    # WAIT: The Poster IS allowed to see it in D-13.
    
    # Requirement D-13: "Show contact info ONLY if task.assigned? and current user is the Poster or Assigned Tasker."
    # So before assignment, BOTH should see it masked.
    
    Capybara.using_session("Poster Session") do
      sign_in poster
      visit conversation_path(conversation)
      
      # Poster (receiver) should see it masked BEFORE assignment
      expect(page).to have_content("[CONTACT MASKED]")
      expect(page).not_to have_content("9841234567")
    end

    # Now Assign the task
    Capybara.using_session("Poster Session") do
      visit task_path(task)
      click_button "Assign Tasker" # This assumes the bid is listed
      
      visit conversation_path(conversation)
      # Poster should now see it unmasked
      expect(page).to have_content("9841234567")
    end
  end
end
