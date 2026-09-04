---
phase: 09-complete-admin-panel-full-super-admin-operations-beyond-user
reviewed: 2026-09-04T03:31:00Z
depth: standard
files_reviewed: 27
files_reviewed_list:
  - app/controllers/admin/base_controller.rb
  - app/controllers/admin/bids_controller.rb
  - app/controllers/admin/categories_controller.rb
  - app/controllers/admin/disputes_controller.rb
  - app/controllers/admin/settings_controller.rb
  - app/controllers/admin/tasks_controller.rb
  - app/controllers/admin/users_controller.rb
  - app/models/admin_activity_log.rb
  - app/models/category.rb
  - app/models/platform_setting.rb
  - app/models/task.rb
  - app/models/user.rb
  - app/services/payments/commission_calculator.rb
  - app/services/payments/ledger_manager.rb
  - app/views/admin/bids/index.html.slim
  - app/views/admin/categories/_form.html.slim
  - app/views/admin/categories/edit.html.slim
  - app/views/admin/categories/index.html.slim
  - app/views/admin/categories/new.html.slim
  - app/views/admin/disputes/show.html.slim
  - app/views/admin/settings/show.html.slim
  - app/views/admin/tasks/edit.html.slim
  - app/views/admin/tasks/show.html.slim
  - app/views/admin/users/edit.html.slim
  - app/views/admin/users/index.html.slim
  - app/views/admin/users/show.html.slim
  - app/views/layouts/admin.html.slim
findings:
  critical: 1
  warning: 3
  info: 3
  total: 7
status: issues_found
---

# Phase 9: Code Review Report

**Reviewed:** 2026-09-04T03:31:00Z
**Depth:** standard
**Files Reviewed:** 27 (plus supporting migration, schema, routes, config, and spec files read for context)
**Status:** issues_found

## Summary

Reviewed the full admin-panel expansion: user suspension/role management, task force-cancel, bid oversight, category CRUD, platform settings/commission rate, and dispute resolution (release/refund/split/reopen). Authorization is centralized correctly in `Admin::BaseController#ensure_admin!` and every admin controller inherits from it, so there is no privilege-escalation path via missing gating — this part is solid. Audit logging (`log_admin_action!`) is consistently called for every destructive/financial action across all controllers. Financial flows in `LedgerManager` are protected against double-transfer via `escrow_balance == 0` early-return guards, and `CommissionCalculator`'s tasker/commission split is internally consistent (no cent leakage) because one leg is always derived by subtraction rather than independent computation.

The most significant finding is that `Admin::UsersController#user_params` permits the `:admin` boolean directly through the generic `edit`/`update` action, rather than through a dedicated, specially-audited action (e.g., `grant_admin`/`revoke_admin`) as called for by the mass-assignment safety guidance for this phase. This is intentional and covered by a request spec, but it still represents an unguarded, high-blast-radius privilege change bundled with ordinary profile edits (no self-demotion guard, no distinct audit action name, no secondary confirmation). It is flagged as Critical because it is a privilege-escalation-adjacent control that deserves a narrower, deliberately-audited surface.

Additionally, three of the four dispute-resolution branches (`release`, `refund`, `split`) can raise an unhandled `AASM::InvalidTransition` when invoked against a task that is not actually in a resolvable state (the `resolve_reopen` branch is the only one that rescues this), a duplicate-query inefficiency exists in `Admin::TasksController#show`, and a couple of minor UX/data-precision issues exist in the dispute split/refund flows. None of these rise to data-loss or security-critical severity given the guards already in `LedgerManager`, but they should be fixed for robustness and consistency.

## Critical Issues

### CR-01: `:admin` role flag is mass-assignable through the generic user edit/update action

**File:** `app/controllers/admin/users_controller.rb:52` (permit list) and `app/views/admin/users/edit.html.slim:19-21` (checkbox in generic edit form)
**Issue:** `user_params` permits `:admin` alongside ordinary profile fields (`first_name`, `last_name`, `bio`, `locale`, `active_role`):

```ruby
def user_params
  params.require(:user).permit(:first_name, :last_name, :bio, :locale, :admin, :active_role)
end
```

This means any super-admin editing a user's bio/name can, in the same request, silently grant (or revoke) platform-admin privileges, since the checkbox lives in the same form and the same `update` action logs everything generically as `"update_user"` with `details: { changes: user_params.to_h }`. This conflates a low-risk profile edit with the single most sensitive privilege change in the system:
- There is no dedicated `grant_admin!`/`revoke_admin!` action with its own audit `action` name (unlike `suspend_user`/`reactivate_user`, which *do* have dedicated actions).
- There is no self-demotion/self-escalation guard analogous to the "cannot suspend your own account" check in `suspend`.
- A single accidental/malicious form submission (or CSRF-adjacent mistake, or a bug in an unrelated field) can flip a user's admin status without any distinct, greppable log entry — the change is buried inside a generic `changes` hash together with unrelated fields.

**Fix:** Split this into a dedicated, explicitly-audited action, and remove `:admin` from the general-purpose `user_params`:

```ruby
# routes.rb
resources :users, only: [:index, :show, :edit, :update] do
  member do
    patch :suspend
    patch :reactivate
    patch :grant_admin
    patch :revoke_admin
  end
end

# users_controller.rb
def grant_admin
  return redirect_to admin_user_path(@user), alert: "You cannot modify your own admin status." if @user == current_user
  @user.update!(admin: true)
  log_admin_action!("grant_admin", @user)
  redirect_to admin_user_path(@user), notice: "Admin access granted."
end

def revoke_admin
  return redirect_to admin_user_path(@user), alert: "You cannot modify your own admin status." if @user == current_user
  @user.update!(admin: false)
  log_admin_action!("revoke_admin", @user)
  redirect_to admin_user_path(@user), notice: "Admin access revoked."
end

private

def user_params
  params.require(:user).permit(:first_name, :last_name, :bio, :locale, :active_role)
end
```

Then replace the checkbox in `edit.html.slim` with two explicit buttons (mirroring the suspend/reactivate pattern in `show.html.slim`), each with its own `data: { confirm: ... }`.

## Warnings

### WR-01: Unhandled `AASM::InvalidTransition` in three of four dispute-resolution branches

**File:** `app/controllers/admin/disputes_controller.rb:33-58`
**Issue:** `resolve_release` (`@task.release_payment!`), `resolve_refund` (`@task.cancel!`), and `resolve_split` (`@task.release_payment!`) all call bang (`!`) AASM event methods with no `rescue AASM::InvalidTransition`, unlike `resolve_reopen` (line 63-68) which correctly rescues it, and unlike `Admin::BidsController`/`Admin::TasksController` which rescue this exception at every call site. Since `disputes#resolve` accepts an arbitrary `:id` and the `set_task` before_action does not restrict to `Task.dispute`, hitting `PATCH /admin/disputes/:id/resolve` with `decision=release` (or `refund`/`split`) against a task that is not in a resolvable AASM state (e.g., already `completed`, or `open`) raises an unhandled exception and returns a 500 instead of a graceful redirect with a flash message — an inconsistency with the rest of the admin surface, and a poor failure mode for an internal tool driven by manually-typed/bookmarked admin URLs.
**Fix:** Wrap the whole dispatch in `resolve`, or add local rescues consistent with `resolve_reopen`:

```ruby
def resolve
  case params[:decision]
  when 'release' then resolve_release
  when 'refund'  then resolve_refund
  when 'split'   then resolve_split
  when 'reopen'  then resolve_reopen
  else flash[:alert] = "Invalid resolution decision."
  end
  redirect_to admin_disputes_path
rescue AASM::InvalidTransition
  flash[:alert] = "Task could not be resolved from its current status (#{@task.status})."
  redirect_to admin_disputes_path
end
```

### WR-02: Misleading "Failed to refund funds" flash when escrow is already empty (idempotent no-op reported as failure)

**File:** `app/controllers/admin/disputes_controller.rb:41-47`; `app/services/payments/ledger_manager.rb:34-42`
**Issue:** `LedgerManager.refund_poster` returns `nil` (the result of the guarded `return if escrow_balance(task) == 0`) when there is nothing left to refund (e.g., a second click, or a task that was already force-cancelled via `Admin::TasksController#force_cancel`, which itself calls `refund_poster`). `resolve_refund` treats this `nil`/falsy return as an outright failure:

```ruby
def resolve_refund
  if Payments::LedgerManager.refund_poster(@task)
    @task.cancel!
    ...
  else
    flash[:alert] = "Failed to refund funds."
  end
end
```

This correctly prevents a double-refund (good), but it also prevents `@task.cancel!` and the audit log from ever running in that case, and shows an admin a "failed" message for what is actually an idempotent no-op. An admin retrying after seeing "failed" could be confused about whether the poster was actually refunded.
**Fix:** Distinguish "already empty" from an actual transfer failure, e.g. have `refund_poster` return `true` for the already-refunded case too (or check `escrow_balance(@task).zero?` before calling and treat that as an already-resolved state rather than a failure), and still transition/log:

```ruby
def resolve_refund
  Payments::LedgerManager.refund_poster(@task)
  if @task.cancel!
    log_admin_action!("resolve_dispute", @task, details: { decision: "refund" })
    flash[:notice] = "Dispute resolved: Funds refunded to poster."
  end
rescue AASM::InvalidTransition
  flash[:alert] = "Task could not be cancelled from its current status."
end
```

### WR-03: Duplicate query in `Admin::TasksController#show` — `before_action` result is discarded and re-fetched

**File:** `app/controllers/admin/tasks_controller.rb:9-13`
**Issue:** `set_task` (the `before_action` for `show`, `edit`, `update`, `force_cancel`) already loads `@task = Task.find(params[:id])`. The `show` action then unconditionally re-queries and overwrites it:

```ruby
before_action :set_task, only: [:show, :edit, :update, :force_cancel]

def show
  @task = Task.includes(:user, :category, :tasker, :payment_transactions, :reviews, :dispute_evidences).find(params[:id])
end
```

The first query's result is thrown away — a wasted round-trip on every single task detail page view (this is a correctness/duplication issue, not merely a performance one, since it silently masks the fact that `set_task` isn't doing the eager-loading `show` actually needs).
**Fix:** Remove `:show` from the `set_task` before_action list (or add the includes to `set_task` itself and use it for all actions):

```ruby
before_action :set_task, only: [:edit, :update, :force_cancel]

def show
  @task = Task.includes(:user, :category, :tasker, :payment_transactions, :reviews, :dispute_evidences).find(params[:id])
end
```

## Info

### IN-01: Escrow split percentage truncated to integer in audit log and flash message

**File:** `app/controllers/admin/disputes_controller.rb:50-56`
**Issue:** `resolve_split` accepts a float percentage (`params[:tasker_percentage].to_f`, validated to be between 0–100) but logs and displays it via `percentage.to_i`:

```ruby
log_admin_action!("resolve_dispute", @task, details: { decision: "split", tasker_percentage: percentage.to_i })
flash[:notice] = "Dispute resolved: Funds split #{percentage}% tasker / #{100 - percentage.to_i}% poster."
```

If an admin enters a fractional percentage (e.g., `33.5`), the audit trail records `33` while the actual transfer used `33.5`, understating the true split in the permanent record.
**Fix:** Preserve the actual float value in the log and message: `tasker_percentage: percentage.to_f`, and `"...#{100 - percentage.to_f}% poster."`.

### IN-02: "Split" dispute resolution silently degrades to a full commission deduction for cash tasks, with a misleading success message

**File:** `app/controllers/admin/disputes_controller.rb:48-58`; `app/services/payments/ledger_manager.rb:44-63`
**Issue:** `split_escrow` returns early with no-op when `escrow_balance(task) == 0`, which is always true for `cash` tasks (no escrow account is ever funded for cash payment_type). `resolve_split` doesn't check `@task.esewa?` before proceeding, so for a cash task in dispute: no split transfer happens, but `@task.release_payment!` still runs afterward, which (via `Task#release_escrow_if_completed`) triggers `LedgerManager.record_cash_commission` — the *standard* full commission deduction, not the admin's requested split. The admin nonetheless sees "Dispute resolved: Funds split 60% tasker / 40% poster," which does not reflect what actually happened financially.
**Fix:** Guard the split path to esewa tasks only, and return an explicit alert otherwise:

```ruby
def resolve_split
  unless @task.esewa?
    flash[:alert] = "Split resolution is only available for eSewa (escrow) tasks."
    return
  end
  ...
end
```

### IN-03: Authorization negative-path (non-admin access) untested for four of six admin request specs

**File:** `spec/requests/admin/categories_controller_spec.rb`, `spec/requests/admin/disputes_controller_spec.rb`, `spec/requests/admin/settings_controller_spec.rb`, `spec/requests/admin/tasks_controller_spec.rb`
**Issue:** `spec/requests/admin/bids_controller_spec.rb` and `spec/requests/admin/users_controller_spec.rb` both include an explicit "as a non-admin user … redirects to root_path with Access denied" case. The other four admin request specs (categories, disputes, settings, tasks) exercise only the happy path and never assert that a signed-in non-admin (or signed-out) request is rejected. Since all controllers correctly inherit `Admin::BaseController`, this is not currently exploitable, but it is an untested regression risk — a future refactor that accidentally changes a controller's superclass or overrides `ensure_admin!` would not be caught by the suite for these four controllers.
**Fix:** Add a shared example (e.g. `it_behaves_like "admin only controller"`) or duplicate the non-admin-redirect assertion already used in the bids/users specs into the categories, disputes, settings, and tasks specs.

---

_Reviewed: 2026-09-04T03:31:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
