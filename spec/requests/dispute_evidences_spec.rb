require 'rails_helper'

RSpec.describe "DisputeEvidences", type: :request do
  let(:poster) { create(:user, :poster) }
  let(:tasker) { create(:user, :tasker) }
  let(:category) { create(:category) }
  let(:task) { create(:task, user: poster, tasker: tasker, category: category, status: :completed) }

  describe "POST /tasks/:task_id/dispute_evidences" do
    context "when logged in as poster" do
      before { sign_in poster }

      it "creates a new dispute evidence" do
        expect {
          post task_dispute_evidences_path(task), params: {
            dispute_evidence: {
              description: "Work was not done according to specs",
              files: [fixture_file_upload('spec/fixtures/files/test_image.png', 'image/png')]
            }
          }
        }.to change(DisputeEvidence, :count).by(1)

        expect(response).to redirect_to(task_path(task))
        expect(flash[:notice]).to be_present
      end

      it "denies access for uncompleted tasks" do
        task.update(status: :assigned)
        post task_dispute_evidences_path(task), params: {
          dispute_evidence: { description: "Too early for dispute" }
        }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when logged in as unauthorized user" do
      let(:other_user) { create(:user) }
      before { sign_in other_user }

      it "denies access" do
        post task_dispute_evidences_path(task), params: {
          dispute_evidence: { description: "Not my business" }
        }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
