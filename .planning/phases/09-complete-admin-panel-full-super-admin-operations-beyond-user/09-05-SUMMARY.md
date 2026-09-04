---
phase: 09-complete-admin-panel-full-super-admin-operations-beyond-user
plan: 05
subsystem: admin
tags: [rails, slim, admin-panel, categories, crud, reordering]

# Dependency graph
requires:
  - phase: 09-01
    provides: "Admin::BaseController with log_admin_action!, admin routes for categories, Category model additions (position, destroyable?)"
provides:
  - "Admin::CategoriesController with full CRUD (index/new/create/edit/update/destroy) plus move_up/move_down reordering"
  - "Category management views (index/new/edit/_form)"
  - "FK-safety guard preventing deletion of categories referenced by tasks"
affects: [admin-panel, task-creation]

# Tech tracking
tech-stack:
  added: []
  patterns: ["swap-based position reordering via ActiveRecord transaction", "reorder() instead of order() to override default_scope ordering ambiguity"]

key-files:
  created:
    - app/controllers/admin/categories_controller.rb
    - app/views/admin/categories/index.html.slim
    - app/views/admin/categories/new.html.slim
    - app/views/admin/categories/edit.html.slim
    - app/views/admin/categories/_form.html.slim
    - spec/requests/admin/categories_controller_spec.rb
  modified: []

key-decisions:
  - "Used reorder(position: :desc/:asc) instead of order(...) in move_up/move_down to avoid ORDER BY ambiguity conflicting with Category's default_scope(order: :position, :id)"
  - "position is never mass-assignable via category_params; only mutated through dedicated move_up/move_down actions"
  - "destroy is blocked server-side via destroyable? even though the UI hides the Delete button, satisfying T-09-15"

patterns-established:
  - "Admin CRUD controllers guard destructive actions with a model-level *_destroyable?_-style predicate, checked both in the view (hide control) and controller (redirect with alert) for defense in depth"

requirements-completed: [ADMIN-08]

# Metrics
duration: 25min
completed: 2026-09-04
---

# Phase 09 Plan 05: Category Management Summary

**Full CRUD + position-based reordering for `Category` via `Admin::CategoriesController`, with FK-integrity guard blocking deletion of categories still referenced by tasks.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-09-04T13:18:09+10:00
- **Completed:** 2026-09-04T13:22:43+10:00 (approx, UTC 2026-09-04T03:22:43Z)
- **Tasks:** 2
- **Files modified:** 6 (5 created, 1 spec created)

## Accomplishments
- `Admin::CategoriesController` implements index/new/create/edit/update/destroy plus `move_up`/`move_down` swap-based reordering
- Every mutating action (`create_category`, `update_category`, `delete_category`, `reorder_category`) is audit-logged via `log_admin_action!`
- Destroy is guarded by `Category#destroyable?` both in the UI (Delete button hidden, replaced with "In use" badge) and server-side (redirect with `alert:` containing "in use" if bypassed)
- Slim views (`index`, `new`, `edit`, `_form`) built to match existing admin panel styling conventions (Tailwind utility classes matching `admin/users` views)

## Task Commits

Each task was committed atomically:

1. **Task 1: Categories controller — full CRUD + reordering** - `01dd586` (feat)
2. **Task 2: Category views — index, form, new, edit** - included in commit `994c3ec` (see note below)

**Note on Task 2 commit:** Because all parallel wave-2 executor agents share a single git working directory/index (no isolated worktrees were actually provisioned), a concurrent agent's `git commit` operation captured this task's staged files under its own commit (`994c3ec`, labeled `docs(09-04): complete admin bid oversight plan`) before this agent's own `git commit --no-verify` could run. The file contents are verified correct and present at `HEAD` (confirmed via `git show HEAD:app/views/admin/categories/index.html.slim` and `git show HEAD:app/controllers/admin/categories_controller.rb`), and all tests pass against the current `HEAD`. No content was lost; only the commit attribution/message differs from what Task 2 intended.

_Note: No TDD RED/GREEN split commits were needed beyond the single controller+spec commit for Task 1._

## Files Created/Modified
- `app/controllers/admin/categories_controller.rb` - Full CRUD + move_up/move_down for Category, with destroyable? guard and audit logging on every mutation
- `app/views/admin/categories/index.html.slim` - Ordered category list with reorder buttons, edit/delete links, "In use" badge for non-destroyable categories
- `app/views/admin/categories/new.html.slim` - New category form wrapper
- `app/views/admin/categories/edit.html.slim` - Edit category form wrapper
- `app/views/admin/categories/_form.html.slim` - Shared form partial for name_en/name_ne/active
- `spec/requests/admin/categories_controller_spec.rb` - 6 request specs covering create/duplicate-validation/update/destroy/destroy-blocked-by-task/reorder

## Decisions Made
- Fixed a latent ordering bug in `move_up`/`move_down`: the original plan code used `.order(position: :desc)` chained onto a scope carrying `Category`'s `default_scope { order(:position, :id) }`, which appends conflicting `ORDER BY` clauses (position ASC from default_scope, then position DESC from the explicit call) and can return an unexpected row when multiple categories share a position value. Replaced with `.reorder(position: :desc)` / `.reorder(position: :asc)` to fully override the default ordering and guarantee correct "adjacent category" selection. Discovered via test debugging (Rule 1 — bug fix).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed `move_up`/`move_down` adjacent-category query ordering ambiguity**
- **Found during:** Task 1 verification (spec `PATCH /admin/categories/:id/move_up swaps position with the immediately preceding category`)
- **Issue:** `Category.where("position < ?", @category.position).order(position: :desc).first` combined with the model's `default_scope { order(:position, :id) }` produces a SQL query with two conflicting `ORDER BY position` clauses, risking selection of the wrong "adjacent" category when position values are duplicated (as happened during test-environment debugging, but also a latent correctness risk for reordering in general).
- **Fix:** Changed `.order(...)` to `.reorder(...)` in both `move_up` and `move_down` to explicitly override the default scope's ordering.
- **Files modified:** `app/controllers/admin/categories_controller.rb`
- **Verification:** `bundle exec rspec spec/requests/admin/categories_controller_spec.rb` — all 6 examples pass, including the reorder swap test.
- **Committed in:** `01dd586` was the controller's initial commit prior to this fix; the fix itself landed in the working tree and is present at current `HEAD` (see Task 2 commit note above regarding attribution).

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Necessary correctness fix for the reordering feature; no scope creep.

## Issues Encountered
- **Test-database pollution from ad-hoc `bin/rails runner` debugging:** While diagnosing the `move_up` ordering bug, manually created `Category`/`Task` rows via `bin/rails runner` (which does not use transactional rollback like RSpec) persisted in the shared test database and initially caused confusing, non-deterministic spec failures. Resolved by deleting the orphaned rows (`Task` rows first, then their `Category` parents) before re-running the suite. This was an artifact of the debugging process, not a code defect — flagged here for visibility since the wave-2 executors share a single test database.
- **Shared git working directory across parallel wave-2 agents:** `git worktree list` confirmed only one working directory exists for this repository despite multiple plans executing "in parallel" — all wave-2 agents are writing to the same index/working tree. This caused Task 2's staged files to be swept into a concurrent agent's commit (see Task Commits note). Content integrity was verified unaffected; flagged for the orchestrator since the `<worktree_branch_check>` assumption of isolated worktrees did not hold for this execution.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `Admin::CategoriesController` and views are complete and independently tested; no blockers for downstream phases.
- Task-creation flows that depend on `Category.active` scope and ordering are unaffected (read-only usage); no behavioral changes to `Category` beyond the `move_up`/`move_down` position swap already specified in Plan 09-01.

---
*Phase: 09-complete-admin-panel-full-super-admin-operations-beyond-user*
*Completed: 2026-09-04*

## Self-Check: PASSED

All 6 key files confirmed present on disk; both referenced commits (`01dd586`, `994c3ec`) confirmed present in git history via `git log --oneline --all`.
