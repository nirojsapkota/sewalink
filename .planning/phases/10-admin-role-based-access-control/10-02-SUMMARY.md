---
phase: 10-admin-role-based-access-control
plan: 02
subsystem: auth
tags: [rolify, rbac, admin, rails, slim]

# Dependency graph
requires:
  - phase: 10-admin-role-based-access-control
    provides: "Plan 10-01: rolify Role model, User#admin_access?/#super_admin?/#accountant?, Admin::BaseController#require_super_admin! guard"
provides:
  - Admin::RolesController#index listing all admin-role (super_admin/accountant) users, super-admin-only
  - Admin::UsersController#update_roles replacing the legacy boolean change_role action, super-admin-only + self-lockout guarded
  - Role-assignment checkbox UI on the edit-user page (super_admin/accountant), visible only to super admins
  - Admin nav "Roles" link and /admin/roles index view
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Role-management UI/controller pattern: allow-list requested roles against a fixed set before calling add_role, destroy_all existing admin-capable roles before re-adding requested ones"
    - "Self-lockout guard pattern: explicit @user == current_user check before mutating another user's privileged attributes"

key-files:
  created:
    - app/controllers/admin/roles_controller.rb
    - app/views/admin/roles/index.html.slim
    - spec/requests/admin/roles_controller_spec.rb
  modified:
    - config/routes.rb
    - app/controllers/admin/users_controller.rb
    - app/views/admin/users/edit.html.slim
    - app/views/layouts/admin.html.slim
    - spec/requests/admin/users_controller_spec.rb

key-decisions:
  - "Legacy change_role action, route, and view form fully removed (not deprecated/aliased) per plan instructions — no dangling references remain anywhere in app/, spec/, or config/"
  - "update_roles allow-lists params[:roles] against [:super_admin, :accountant] before calling add_role, preventing assignment of arbitrary/unknown role names (T-10-08 mitigation)"
  - "update_roles destroys existing super_admin/accountant role rows for the target user before re-adding requested ones, so submitting roles: [] fully revokes all admin-capable roles in one request"

requirements-completed: [ADMIN-13]

# Metrics
duration: 20min
completed: 2026-09-04
---

# Phase 10 Plan 02: Role Management UI Summary

**Built the super-admin-only role management UI (`Admin::RolesController#index` + `Admin::UsersController#update_roles`), fully replacing Phase 9's legacy boolean `change_role` action with rolify-based role assignment/revocation, completing ADMIN-13.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-09-04T04:56:30Z
- **Completed:** 2026-09-04T05:16:30Z
- **Tasks:** 3
- **Files modified:** 8 (3 created, 5 modified)

## Accomplishments
- `config/routes.rb`: legacy `patch :change_role` member route replaced with `patch :roles, action: :update_roles`; new `resources :roles, only: [:index]` added to the `admin` namespace
- `Admin::UsersController#update_roles` replaces `#change_role` — guarded by `before_action :require_super_admin!, only: [:update_roles]`, blocks self-role-changes, allow-lists `params[:roles]` against `[:super_admin, :accountant]`, logs `"update_roles"` to `AdminActivityLog` with `from`/`to` role-name arrays
- New `Admin::RolesController#index` (super-admin-only via controller-level `require_super_admin!`) lists all users holding `super_admin` or `accountant`
- `app/views/admin/users/edit.html.slim` "Admin Access" boolean form replaced with a role-assignment checkbox form (`super_admin`/`accountant`), rendered only for `current_user.super_admin?` and hidden entirely when editing yourself
- New `app/views/admin/roles/index.html.slim` table listing admin-role users with a "Manage Roles" link to each user's edit page
- New "Roles" nav link added to `app/views/layouts/admin.html.slim` between Categories and Payouts
- 6 new/replaced request-spec examples covering role grant, full revocation, self-lockout, and accountant-denied-access for both the update action and the index page
- Full `spec/requests/admin` suite: 43 examples, 1 pre-existing unrelated failure (`dashboards_spec.rb:36`, documented in 10-01-SUMMARY.md as failing before and after Phase 10's changes)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add roles route, replace change_role with update_roles action** - `5013f85` (feat)
2. **Task 2: Build role-management views and nav link** - `c71dcff` (feat)
3. **Task 3: Request specs for role management and super-admin-only enforcement** - `eaacd46` (test)

## Files Created/Modified
- `config/routes.rb` - `patch :roles, action: :update_roles` member route; new `resources :roles, only: [:index]`
- `app/controllers/admin/users_controller.rb` - `change_role` deleted; `update_roles` added with `require_super_admin!` + self-lockout guard + role allow-list
- `app/controllers/admin/roles_controller.rb` - new controller, `index` action, `require_super_admin!` on all actions
- `app/views/admin/users/edit.html.slim` - role-assignment checkbox form replacing the old admin-boolean form
- `app/views/admin/roles/index.html.slim` - new admin-role user listing table
- `app/views/layouts/admin.html.slim` - new "Roles" nav link
- `spec/requests/admin/users_controller_spec.rb` - `change_role` describe block replaced with `update_roles` describe block (4 examples: grant, revoke-all, self-lockout, accountant-denied)
- `spec/requests/admin/roles_controller_spec.rb` - new spec file (2 examples: accountant-denied, super-admin-allowed + lists user)

## Decisions Made
- Fully removed the legacy `change_role` action/route/view rather than keeping it as a deprecated alias — confirmed via `grep -rn "change_role" app/ spec/ config/` returning zero matches after the change.
- `update_roles` destroys all existing `super_admin`/`accountant` role rows for the target user before re-adding the requested set, making `roles: []` an explicit full-revocation request in a single idempotent request rather than requiring separate add/remove semantics.
- Requested roles are allow-listed (`Array(params[:roles]).map(&:to_sym) & [:super_admin, :accountant]`) before any `add_role` call, directly mitigating threat T-10-08 (tampering via arbitrary role-name injection).

## Deviations from Plan

None - plan executed exactly as written. All routes, controller actions, views, and spec behaviors match the plan's specified file paths, method names, and route helpers exactly.

## Issues Encountered
- `spec/requests/admin/dashboards_spec.rb:36` continues to fail (pre-existing, confirmed in 10-01-SUMMARY.md as failing before this plan started, unrelated to role management, not in this plan's file list) — left untouched per scope-boundary rules.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- ADMIN-13 fully implemented and verified: super admins can view all admin-role users at `/admin/roles` and grant/revoke `super_admin`/`accountant` roles for any other user via the edit-user page; accountant-only users are denied at the controller level for both the index and update actions; no self-lockout path exists.
- Phase 10 (Admin Role-Based Access Control) is now complete — both plans (10-01, 10-02) executed, all admin request specs green except the one pre-existing, out-of-scope failure documented above.
- No blockers identified for subsequent phases.

---
*Phase: 10-admin-role-based-access-control*
*Completed: 2026-09-04*

## Self-Check: PASSED

All created files verified present on disk:
- FOUND: app/controllers/admin/roles_controller.rb
- FOUND: app/views/admin/roles/index.html.slim
- FOUND: spec/requests/admin/roles_controller_spec.rb
- FOUND: config/routes.rb (modified)
- FOUND: app/controllers/admin/users_controller.rb (modified)
- FOUND: app/views/admin/users/edit.html.slim (modified)
- FOUND: app/views/layouts/admin.html.slim (modified)
- FOUND: spec/requests/admin/users_controller_spec.rb (modified)

All task commit hashes verified present in git history:
- FOUND: 5013f85 (Task 1)
- FOUND: c71dcff (Task 2)
- FOUND: eaacd46 (Task 3)
