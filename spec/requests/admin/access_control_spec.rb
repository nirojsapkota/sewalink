require 'rails_helper'

RSpec.describe "Admin::AccessControl", type: :request do
  describe "GET /admin (admin_root_path)" do
    it "allows a super_admin user" do
      user = create(:user, :super_admin)
      sign_in user

      get admin_root_path

      expect(response).to have_http_status(:ok)
    end

    it "allows an accountant user" do
      user = create(:user, :accountant)
      sign_in user

      get admin_root_path

      expect(response).to have_http_status(:ok)
    end

    it "denies a plain user with no role and admin: false" do
      user = create(:user)
      sign_in user

      get admin_root_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Access denied. Admin only.")
    end

    it "denies a user with admin: true but no rolify role (boolean fully decoupled)" do
      user = create(:user, admin: true)
      sign_in user

      get admin_root_path

      expect(response).to redirect_to(root_path)
    end

    it "allows a user created via the legacy :admin trait (backward compatible)" do
      user = create(:user, :admin)
      sign_in user

      get admin_root_path

      expect(response).to have_http_status(:ok)
    end
  end
end
