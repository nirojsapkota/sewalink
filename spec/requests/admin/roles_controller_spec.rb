require 'rails_helper'

RSpec.describe "Admin::Roles", type: :request do
  let(:admin) { create(:user, :super_admin) }
  let(:accountant_user) { create(:user, :accountant) }

  describe "GET /admin/roles" do
    it "denies an accountant-only user" do
      sign_in accountant_user

      get admin_roles_path

      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to eq("Access denied. Super admin only.")
    end

    it "allows a super admin and lists admin-role users" do
      sign_in admin
      accountant_user # ensure created

      get admin_roles_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(accountant_user.phone)
    end
  end
end
