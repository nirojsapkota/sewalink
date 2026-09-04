require 'rails_helper'

RSpec.describe "Admin::Users", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:target_user) { create(:user) }

  before do
    sign_in admin
  end

  describe "PATCH /admin/users/:id/suspend" do
    it "suspends the user, logs the action, and redirects" do
      patch suspend_admin_user_path(target_user), params: { suspension_reason: "abuse" }

      target_user.reload
      expect(target_user.suspended_at).to be_present
      expect(target_user.suspension_reason).to eq("abuse")

      log = AdminActivityLog.last
      expect(log.action).to eq("suspend_user")
      expect(log.admin).to eq(admin)
      expect(log.target_id).to eq(target_user.id)

      expect(response).to redirect_to(admin_user_path(target_user))
    end

    it "does not allow an admin to suspend their own account" do
      patch suspend_admin_user_path(admin), params: { suspension_reason: "abuse" }

      admin.reload
      expect(admin.suspended_at).to be_nil
      expect(response).to redirect_to(admin_user_path(admin))
      follow_redirect!
      expect(response.body).to include("You cannot suspend your own account.")
    end
  end

  describe "PATCH /admin/users/:id/reactivate" do
    it "reactivates the user and logs the action" do
      target_user.suspend!("abuse")

      patch reactivate_admin_user_path(target_user)

      target_user.reload
      expect(target_user.suspended_at).to be_nil
      expect(target_user.suspension_reason).to be_nil

      log = AdminActivityLog.last
      expect(log.action).to eq("reactivate_user")
      expect(log.target_id).to eq(target_user.id)
    end
  end

  describe "PATCH /admin/users/:id" do
    it "updates the user and logs the action" do
      patch admin_user_path(target_user), params: { user: { admin: true, active_role: "tasker", first_name: "New" } }

      target_user.reload
      expect(target_user.admin?).to eq(true)
      expect(target_user.active_role).to eq("tasker")
      expect(target_user.first_name).to eq("New")

      log = AdminActivityLog.last
      expect(log.action).to eq("update_user")
      expect(log.target_id).to eq(target_user.id)
    end
  end

  describe "as a non-admin user" do
    let(:regular_user) { create(:user) }

    before do
      sign_out admin
      sign_in regular_user
    end

    it "redirects to root_path with an access denied alert" do
      patch admin_user_path(target_user), params: { user: { first_name: "New" } }
      expect(response).to redirect_to(root_path)
      follow_redirect!
      follow_redirect! while response.redirect?
      expect(response.body).to include("Access denied. Admin only.")
    end
  end
end
