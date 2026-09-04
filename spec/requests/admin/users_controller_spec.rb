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
    it "updates the user and logs the action, without allowing admin flag mass-assignment" do
      patch admin_user_path(target_user), params: { user: { admin: true, active_role: "tasker", first_name: "New" } }

      target_user.reload
      expect(target_user.admin?).to eq(false)
      expect(target_user.active_role).to eq("tasker")
      expect(target_user.first_name).to eq("New")

      log = AdminActivityLog.last
      expect(log.action).to eq("update_user")
      expect(log.target_id).to eq(target_user.id)
    end
  end

  describe "PATCH /admin/users/:id/roles" do
    it "grants a role and logs a distinct audit action" do
      patch roles_admin_user_path(target_user), params: { roles: ["super_admin"] }

      target_user.reload
      expect(target_user.has_role?(:super_admin)).to eq(true)

      log = AdminActivityLog.last
      expect(log.action).to eq("update_roles")
      expect(log.target_id).to eq(target_user.id)
      expect(JSON.parse(log.details)["to"]).to eq(["super_admin"])
    end

    it "revokes all admin-capable roles when none are submitted" do
      target_user.add_role(:accountant)

      patch roles_admin_user_path(target_user), params: { roles: [] }

      target_user.reload
      expect(target_user.has_role?(:accountant)).to eq(false)
      expect(target_user.has_role?(:super_admin)).to eq(false)
    end

    it "does not allow a super admin to change their own roles" do
      patch roles_admin_user_path(admin), params: { roles: [] }

      admin.reload
      expect(admin.has_role?(:super_admin)).to eq(true)
      expect(response).to redirect_to(admin_user_path(admin))
      expect(flash[:alert]).to eq("You cannot change your own roles.")
    end

    it "denies an accountant-only user attempting to change another user's roles" do
      accountant_user = create(:user, :accountant)
      sign_out admin
      sign_in accountant_user

      patch roles_admin_user_path(target_user), params: { roles: ["super_admin"] }

      target_user.reload
      expect(target_user.has_role?(:super_admin)).to eq(false)
      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to eq("Access denied. Super admin only.")
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
