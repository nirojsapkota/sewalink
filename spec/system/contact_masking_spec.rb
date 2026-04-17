require 'rails_helper'

RSpec.describe "ContactMasking", type: :system do
  let(:poster) { create(:user, phone: "9812345678", active_role: :poster) }
  let(:tasker) { create(:user, phone: "9887654321", active_role: :tasker) }
  let(:task) { create(:task, user: poster, status: :open) }
  let(:bid) { create(:bid, task: task, user: tasker, amount: 500) }

  before do
    driven_by(:rack_test)
  end

  context "when task is NOT assigned" do
    it "masks poster contact info for tasker" do
      sign_in tasker
      visit task_path(task)
      
      expect(page).to have_content("Posted By")
      expect(page).to have_content("[HIDDEN UNTIL ASSIGNED]")
      expect(page).not_to have_content("9812345678")
    end

    it "masks tasker contact info for poster in chat" do
      conversation = bid.conversation
      sign_in poster
      visit conversation_path(conversation)
      
      expect(page).to have_content("Chatting with [HIDDEN UNTIL ASSIGNED]")
      expect(page).not_to have_content("9887654321")
    end
  end

  context "when task IS assigned" do
    before do
      bid.update!(status: :accepted)
      task.update!(status: :assigned, tasker: tasker)
    end

    it "shows poster contact info for assigned tasker" do
      sign_in tasker
      visit task_path(task)
      
      expect(page).to have_content("Posted By")
      expect(page).to have_content("9812345678")
      expect(page).not_to have_content("[HIDDEN UNTIL ASSIGNED]")
    end

    it "shows tasker contact info for poster in chat" do
      conversation = bid.conversation
      sign_in poster
      visit conversation_path(conversation)
      
      expect(page).to have_content("Chatting with 9887654321")
      expect(page).not_to have_content("[HIDDEN UNTIL ASSIGNED]")
    end
  end

  context "own profile" do
    it "shows own contact info" do
      sign_in poster
      visit profile_path
      
      expect(page).to have_content("9812345678")
      expect(page).not_to have_content("[HIDDEN UNTIL ASSIGNED]")
    end
  end
end
