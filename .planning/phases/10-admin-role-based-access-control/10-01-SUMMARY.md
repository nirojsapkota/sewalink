---
phase: 10-admin-role-based-access-control
plan: 01
subsystem: auth
tags: [rolify, rbac, admin, devise, rails]

# Dependency graph
requires:
  - phase: 09-complete-admin-panel
    provides: Admin::BaseController with boolean-based ensure_admin! gate, AdminActivityLog
provides:
  - rolify gem installed with Role model and roles/users_roles tables
  - User#admin_access?/#super_admin?/#accountant? role-check helpers
  - Admin::BaseController#ensure_admin! gated on roles (admin_access?) instead of the legacy admin boolean
  - Admin::BaseController#require_super_admin! guard for role-management-only actions
  - Data migration converting all admin:true users to hold the super_admin role
  - Updated :admin/:super_admin/:accountant factory traits
affects: [10-02-role-management-ui]

# Tech tracking
tech-stack:
  added: [rolify]
  patterns:
    - "Role-based access control via rolify has_role?/add_role instead of boolean flags"
    - "Admin::BaseController#require_super_admin! as a reusable before_action guard for super-admin-only actions"

key-files:
  created:
    - app/models/role.rb
    - config/initializers/rolify.rb
    - db/migrate/20260904045108_rolify_create_roles.rb
    - db/migrate/20260904045142_migrate_admin_flag_to_super_admin_role.rb
    - spec/models/role_spec.rb
    - spec/factories/roles.rb
    - spec/requests/admin/access_control_spec.rb
  modified:
    - Gemfile
    - Gemfile.lock
    - app/models/user.rb
    - app/controllers/admin/base_controller.rb
    - spec/factories/users.rb
    - db/schema.rb

key-decisions:
  - "Legacy admin boolean column left in schema untouched, fully decoupled from access-control decisions"
  - "Data migration is idempotent (checks has_role? before add_role) and has a no-op down (never strips access-control roles on rollback)"
  - "require_super_admin! guard added now (unused in this plan) so 10-02's role-management controller can build directly on it"

requirements-completed: [ADMIN-12]

# Metrics
duration: 25min
completed: 2026-09-04
---

# Phase 10 Plan 01: Rolify Installation & Role-Based Access Control Summary

**Installed `rolify`, migrated all `admin: true` users to a `super_admin` role, and rewired `Admin::BaseController#ensure_admin!` to gate `/admin` access on roles instead of the legacy boolean column.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-09-04T04:49:00Z
- **Completed:** 2026-09-04T04:54:30Z
- **Tasks:** 3
- **Files modified:** 13 (7 created, 6 modified)

## Accomplishments
- `rolify` gem installed; `Role` model and `roles`/`users_roles` tables added via generated migration
- `User#admin_access?`, `#super_admin?`, `#accountant?` helper methods added
- Idempotent data migration grants `super_admin` role to every pre-existing `admin: true` user
- `Admin::BaseController#ensure_admin!` now checks `admin_access?` (role-based); legacy `admin` boolean fully decoupled from access control
- `Admin::BaseController#require_super_admin!` guard added for the next plan's role-management controller
- `:admin` factory trait now also grants `super_admin`; new `:super_admin`/`:accountant` traits added
- New `spec/requests/admin/access_control_spec.rb` (5 examples) proves role-gated access, boolean decoupling, and backward compatibility of the `:admin` trait
- Full `spec/requests/admin` suite (40 examples) passes with zero new failures introduced

## Task Commits

Each task was committed atomically:

1. **Task 1: Install rolify, generate Role model, migrate schema** - `f795a87` (feat)
2. **Task 2: Data-migrate admin:true users to super_admin role** - `cd9c897` (feat)
3. **Task 3: Gate admin access on roles, update factory** - `90bdb34` (test, RED) + `8f06f0d` (feat, GREEN)

## Files Created/Modified
- `Gemfile` / `Gemfile.lock` - Added `rolify` gem
- `app/models/role.rb` - Generated rolify `Role` model (HABTM users, polymorphic resource)
- `config/initializers/rolify.rb` - Generated rolify configuration (defaults, untouched)
- `db/migrate/20260904045108_rolify_create_roles.rb` - Creates `roles` and `users_roles` tables
- `db/migrate/20260904045142_migrate_admin_flag_to_super_admin_role.rb` - Idempotent data migration; no-op `down`
- `db/schema.rb` - Updated with new tables
- `app/models/user.rb` - `rolify` concern + `admin_access?`/`super_admin?`/`accountant?` helpers
- `app/controllers/admin/base_controller.rb` - `ensure_admin!` now role-based; `require_super_admin!` guard added
- `spec/factories/users.rb` - `:admin` trait grants `super_admin`; new `:super_admin`/`:accountant` traits
- `spec/requests/admin/access_control_spec.rb` - 5 new examples covering role-based access control
- `spec/models/role_spec.rb`, `spec/factories/roles.rb` - Generator scaffolding (unmodified defaults)

## Decisions Made
- Kept the legacy `admin` boolean column in the schema per plan instructions — it is now inert for access-control purposes, verified explicitly by Test 4 (`admin: true` + no role ⇒ denied).
- Data migration's `down` is intentionally a no-op (documented in the migration file) since stripping roles on rollback would be a destructive, irreversible access-control regression.
- Added `require_super_admin!` now, ahead of its first use in 10-02, exactly as directed by the plan so the next plan's role-management controller can adopt it directly as a `before_action`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Adjusted access_control_spec denial assertions to check `flash[:alert]` instead of `response.body` after `follow_redirect!`**
- **Found during:** Task 3 (writing the RED/GREEN spec)
- **Issue:** The plan's Test 3/Test 4 behavior spec (as literally written) expected `response.body` to include `"Access denied. Admin only."` after `follow_redirect!` to `root_path`. This assertion pattern already exists verbatim in the pre-existing `spec/requests/admin/dashboards_spec.rb:40` and fails identically on `main` *before* this plan's changes — the signed-in root page (`dashboards#show`) does not render flash messages into a non-empty body in the test/request-spec rendering path (an out-of-scope, pre-existing issue unrelated to role-based access control). Confirmed via a controlled reproduction against the pre-plan commit.
- **Fix:** Changed the two denial assertions in `access_control_spec.rb` to check `expect(flash[:alert]).to eq("Access denied. Admin only.")` directly, matching the working pattern already used in `spec/requests/admin/bids_controller_spec.rb:105`. This preserves full behavioral coverage (redirect target + exact alert message) without relying on the broken body-rendering assertion.
- **Files modified:** `spec/requests/admin/access_control_spec.rb`
- **Verification:** `bundle exec rspec spec/requests/admin/access_control_spec.rb` → 5 examples, 0 failures
- **Committed in:** `8f06f0d` (Task 3 GREEN commit)
- **Note:** The pre-existing `dashboards_spec.rb:36` failure (same root cause, out of scope per plan's file list) is left untouched and logged below under Deferred Issues — it is not caused by this plan's changes and was failing identically before this plan started.

---

**Total deviations:** 1 auto-fixed (1 bug workaround in new test code, not production code)
**Impact on plan:** No production code changed as a result. All 3 plan tasks implemented exactly as specified; only the new spec's assertion style was adjusted to avoid asserting against a known-broken, out-of-scope rendering path.

## Issues Encountered
- `spec/requests/admin/dashboards_spec.rb:36` ("redirects to root path" / "Access denied. Admin only." in body) fails both before and after this plan's changes — confirmed via reproduction against the pre-plan commit. This is a pre-existing, out-of-scope issue (empty response body after `follow_redirect!` to the signed-in root page) not touched by this plan and not in this plan's file list. Logged here for visibility; not fixed per scope-boundary rules.
- `spec/system/admin/task_monitoring_spec.rb` and `spec/system/admin/dispute_resolution_spec.rb` fail in this sandbox due to a chromedriver crash (Selenium::WebDriver::Error::WebDriverError), confirmed identical on the pre-plan commit — an environment/tooling issue unrelated to this plan's code changes, not caused by role-based access control changes. Not in this plan's required verification scope (`spec/requests/admin` only).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `require_super_admin!`, `Role` model, `User#admin_access?`/`#super_admin?`/`#accountant?`, and the updated `:admin`/`:super_admin`/`:accountant` factory traits are all in place and correctly named per the plan, ready for Plan 10-02's super-admin-only role management UI.
- No blockers identified for 10-02.

---
*Phase: 10-admin-role-based-access-control*
*Completed: 2026-09-04*

## Self-Check: PASSED

All created files verified present on disk:
- FOUND: app/models/role.rb
- FOUND: config/initializers/rolify.rb
- FOUND: db/migrate/20260904045108_rolify_create_roles.rb
- FOUND: db/migrate/20260904045142_migrate_admin_flag_to_super_admin_role.rb
- FOUND: spec/requests/admin/access_control_spec.rb
- FOUND: app/models/user.rb
- FOUND: app/controllers/admin/base_controller.rb
- FOUND: spec/factories/users.rb

All task commit hashes verified present in git history:
- FOUND: f795a87 (Task 1)
- FOUND: cd9c897 (Task 2)
- FOUND: 90bdb34 (Task 3 RED)
- FOUND: 8f06f0d (Task 3 GREEN)
