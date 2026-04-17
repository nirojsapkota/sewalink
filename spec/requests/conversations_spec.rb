require 'rails_helper'

RSpec.describe "Conversations", type: :request do
  let(:poster) { create(:user, :poster) }
  let(:tasker) { create(:user, :tasker) }
  let(:other_user) { create(:user) }
  let(:category) { create(:category) }
  let(:task) { create(:task, user: poster, category: category) }
  let(:bid) { create(:bid, task: task, user: tasker) }
  let(:conversation) { bid.conversation }

  describe "GET /show" do
    context "when authorized" do
      it "allows poster to access the conversation" do
        sign_in poster
        get conversation_path(conversation)
        expect(response).to have_http_status(:success)
      end

      it "allows tasker to access the conversation" do
        sign_in tasker
        get conversation_path(conversation)
        expect(response).to have_http_status(:success)
      end
    end

    context "when unauthorized" do
      it "redirects unauthorized users" do
        sign_in other_user
        get conversation_path(conversation)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end

      it "redirects unauthenticated users" do
        get conversation_path(conversation)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
