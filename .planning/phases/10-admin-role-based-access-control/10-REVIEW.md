---
phase: 10-admin-role-based-access-control
reviewed: 2026-09-04T15:01:17Z
depth: standard
files_reviewed: 18
files_reviewed_list:
  - app/controllers/admin/base_controller.rb
  - app/controllers/admin/roles_controller.rb
  - app/controllers/admin/users_controller.rb
  - app/models/role.rb
  - app/models/user.rb
  - app/views/admin/roles/index.html.slim
  - app/views/admin/users/edit.html.slim
  - app/views/layouts/admin.html.slim
  - config/initializers/rolify.rb
  - config/routes.rb
  - db/migrate/20260904045108_rolify_create_roles.rb
  - db/migrate/20260904045142_migrate_admin_flag_to_super_admin_role.rb
  - db/schema.rb
  - spec/factories/roles.rb
  - spec/factories/users.rb
  - spec/models/role_spec.rb
  - spec/requests/admin/access_control_spec.rb
  - spec/requests/admin/roles_controller_spec.rb
  - spec/requests/admin/users_controller_spec.rb
findings:
  critical: 0
  warning: 1
  info: 4
  total: 5
status: issues_found
---

# Phase 10: Code Review Report

**Reviewed:** 2026-09-04T15:01:17Z
**Depth:** standard
**Files Reviewed:** 18
**Status:** issues_found

## Summary

This phase replaces the boolean `admin` column with a `rolify`-based role system (`super_admin`, `accountant`). The core security properties requested for review hold up well:

- **Privilege escalation:** `Admin::UsersController#update_roles` allow-lists `params[:roles]` against `[:super_admin, :accountant]` via `Array(params[:roles]).map(&:to_sym) & [:super_admin, :accountant]` before calling `add_role`, so arbitrary role names cannot be injected. `user_params` in `#update` does not permit `:admin` or `:roles`, so mass-assignment through the general update action is blocked (confirmed by `users_controller_spec.rb`'s "without allowing admin flag mass-assignment" test).
- **Self-lockout:** `update_roles` unconditionally refuses `@user == current_user`, which is stricter than strictly necessary but fully prevents both accidental self-demotion and any self-escalation path. Combined with the fact that only an existing `super_admin` can reach this action (`require_super_admin!`), there is no path to zero-super-admin lockout introduced by this code.
- **Authorization coverage:** `require_super_admin!` is applied as a `before_action` on `Admin::RolesController` (applies to all actions, currently just `index`) and scoped correctly to `:update_roles` on `Admin::UsersController`. Both are covered by request specs that assert accountant-only users are redirected with the correct alert.
- **Legacy `admin` boolean decoupling:** `User#admin_access?`, `#super_admin?`, and `#accountant?` are all implemented purely in terms of `has_role?`, with no reference to the legacy `admin` column. This is explicitly verified by `access_control_spec.rb`'s "denies a user with admin: true but no rolify role" test.
- **Migration correctness:** `MigrateAdminFlagToSuperAdminRole#up` is idempotent (`unless user.has_role?(:super_admin)`) and the `down` is an intentional, documented no-op to avoid a destructive access-control rollback.
- **Indexes:** `rolify_create_roles` migration adds composite indexes on `roles(name, resource_type, resource_id)` and `users_roles(user_id, role_id)`; schema.rb additionally shows a `role_id` index and a plain `user_id` index on `users_roles`, so lookups in both directions are indexed.
- **Audit logging:** `update_roles` calls `log_admin_action!("update_roles", @user, details: { from:, to: })`, recorded via `AdminActivityLog.record!`, and this is verified by the roles-audit test in `users_controller_spec.rb`.

One residual issue was found: the legacy `admin` boolean is still displayed to admins as if it reflects access-control status, which is now misleading since it is fully decoupled (see WR-01). A few minor cleanup/completeness items are also noted below.

## Warnings

### WR-01: Legacy `admin` boolean is displayed in the user detail view as if it reflects access status

**File:** `app/views/admin/users/show.html.slim:32`
**Issue:** The view renders `@user.admin? ? "Yes" : "No"` under a field literally labeled "Admin". Since this phase fully decouples the `admin` boolean from access control (confirmed by `access_control_spec.rb`), this field is now stale/misleading: a `super_admin` or `accountant` user who was never toggled through the old boolean flow will show "Admin: No" even though they have full admin-panel access, and conversely a user with `admin: true` left over from before the migration (or manually set) will show "Admin: Yes" despite having no actual access. This is exactly the kind of confusion that could cause an operator to misjudge a user's real privileges while auditing accounts.
**Fix:** Replace the boolean display with the actual role-derived state, e.g.:
```slim
dt.font-medium.text-gray-500
  | Admin Roles
dd.col-span-2.text-gray-900
  - if @user.roles.any?
    = @user.roles.pluck(:name).join(", ")
  - else
    | None
```
Consider also removing the now-vestigial `admin` column in a follow-up migration once all references are cleaned up (see IN-01).

## Info

### IN-01: Legacy `admin` column still present in schema with no remaining functional purpose

**File:** `db/schema.rb:268`, `app/views/admin/users/show.html.slim:32`
**Issue:** The `users.admin` boolean column survives the migration to rolify and is only read in one view (flagged above). Leaving a vestigial, unused-for-authorization column around invites future contributors to accidentally reintroduce logic that branches on it (as almost happened here), especially since its name still suggests "is this user an admin?".
**Fix:** Once WR-01 is fixed and no code paths read `admin`, add a follow-up migration to `remove_column :users, :admin`. If it must be kept temporarily for historical/audit reasons, add a code comment on the schema/model noting it is deprecated and unused for authorization.

### IN-02: `Admin::RolesController#index` and the "Roles" nav link are reachable but denied for accountants — expected but worth a UX note

**File:** `app/views/layouts/admin.html.slim:26`, `app/controllers/admin/roles_controller.rb:2`
**Issue:** The admin nav bar renders a "Roles" link unconditionally for any user who can reach the admin layout (i.e., any `admin_access?` user, including plain accountants). Accountants clicking it are correctly redirected by `require_super_admin!`, so there's no security gap, but the UI surfaces a dead-end link to lower-privileged admins.
**Fix:** Gate the nav link on `current_user.super_admin?`, e.g. `- if current_user.super_admin?` wrapping the `Roles` link, for a cleaner UX (not a security fix, cosmetic only).

### IN-03: `Admin::RolesController#index` issues one extra query per row for role names (N+1)

**File:** `app/views/admin/roles/index.html.slim:20-21`, `app/controllers/admin/roles_controller.rb:4-7`
**Issue:** `@admin_users` is loaded with `.joins(:roles).distinct`, but the view then calls `user.roles.pluck(:name)` per row, issuing a fresh query per user instead of reusing preloaded associations. Flagged for awareness only — performance is out of scope for this review per project convention, but it's cheap to fix alongside other changes in this controller.
**Fix:**
```ruby
@admin_users = User.includes(:roles)
                    .joins(:roles)
                    .where(roles: { name: %w[super_admin accountant] })
                    .distinct
                    .order(:phone)
```
Then in the view use the preloaded `user.roles` (already loaded, no `pluck`) — e.g. `user.roles.map(&:name)`.

### IN-04: `spec/models/role_spec.rb` and `spec/factories/roles.rb` are placeholder stubs with no actual coverage

**File:** `spec/models/role_spec.rb:1-3`, `spec/factories/roles.rb:1-4`
**Issue:** `role_spec.rb` contains only the default `pending "add some examples..."` scaffold generated by `rails g model`, and the `:role` factory defines no attributes at all (relying entirely on rolify's `add_role` helper in the `:user` factory traits, which never actually uses `create(:role, ...)`). This means the `Role` model itself has zero direct test coverage — validations like the `resource_type` inclusion check are entirely untested.
**Fix:** Either remove the empty pending spec/factory (if role behavior is fully exercised via `User#add_role` in the request specs, which is defensible), or add minimal coverage, e.g.:
```ruby
RSpec.describe Role, type: :model do
  it "is valid with a nil resource_type" do
    expect(build(:role, name: "super_admin")).to be_valid
  end

  it "is invalid with a resource_type not in Rolify.resource_types" do
    role = build(:role, name: "super_admin", resource_type: "NotARealModel")
    expect(role).not_to be_valid
  end
end
```

---

_Reviewed: 2026-09-04T15:01:17Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
