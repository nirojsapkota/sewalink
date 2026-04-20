require 'rails_helper'

RSpec.describe "Admin::Dashboards", type: :request do
  describe "GET /admin" do
    context "when user is an admin" do
      let(:admin) { create(:user, :admin) }

      before do
        sign_in admin
      end

      it "returns http success and assigns analytics data" do
        create_list(:user, 3, created_at: 2.days.ago)
        category = create(:category)
        user = create(:user)
        create(:task, :completed, budget: 1000, completed_at: 1.day.ago, user: user, category: category)
        create(:task, :completed, budget: 500, completed_at: 1.day.ago, user: user, category: category)

        get admin_root_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Admin Dashboard")
        
        expect(controller.instance_variable_get(:@new_users_by_day)).to be_present
        expect(controller.instance_variable_get(:@tasks_completed_by_day)).to be_present
        expect(controller.instance_variable_get(:@daily_gmv)).to be_present
      end
    end

    context "when user is not an admin" do
      let(:user) { create(:user) }

      before do
        sign_in user
      end

      it "redirects to root path" do
        get admin_root_path
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Access denied. Admin only.")
      end
    end

    context "when user is unauthenticated" do
      it "redirects to login path" do
        get admin_root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
