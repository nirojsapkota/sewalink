# Phase 07: Admin Panel and Analytics - Research

**Researched:** 2026-04-18
**Domain:** Administrative Oversight, Financial Monitoring, Growth Analytics
**Confidence:** HIGH

## Summary

Phase 07 focuses on providing the platform administrators with tools for oversight, user management, and growth monitoring. While basic payout management exists, this phase expands the `Admin::` namespace into a comprehensive dashboard.

The strategy involves building a custom admin dashboard using standard Rails controllers and Tailwind UI to maintain consistency with the localized and Hotwire-native nature of `sewaLink`. For analytics, `Chartkick` and `Groupdate` are recommended as they integrate seamlessly with Rails and provide high-quality visualizations with minimal configuration.

**Primary recommendation:** Use a custom-built admin panel under the existing `Admin::` namespace, leveraging `Chartkick` for growth analytics and `DoubleEntry` for financial oversight.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Rails | 7.1.6 | Web framework | Existing project foundation [VERIFIED: rails -v] |
| Chartkick | ~> 5.0 | Charting | Standard for Rails analytics dashboards [ASSUMED] |
| Groupdate | ~> 6.4 | SQL grouping by time | Required for time-series analytics [ASSUMED] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|--------------|
| DoubleEntry | existing | Financial ledger | For auditing platform revenue and escrow balances [VERIFIED: Gemfile] |
| Kaminari | existing | Pagination | For listing users and tasks [VERIFIED: Gemfile] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom Panel | Avo | Avo is modern and Hotwire-native, but the community version has limits on custom dashboards, and a custom panel allows tighter integration with existing localized styles. |
| Custom Panel | Administrate | Good middle ground, but custom controllers are already started (`Admin::PayoutsController`). |

**Installation:**
```bash
bundle add chartkick groupdate
```

**Version verification:**
Verified current stable versions:
- `chartkick`: 5.1.2 (2024-11) [CITED: rubygems.org]
- `groupdate`: 6.4.1 (2024-10) [CITED: rubygems.org]

## Architecture Patterns

### Recommended Project Structure
```
app/
├── controllers/
│   └── admin/
│       ├── base_controller.rb      # Common admin logic (auth, layout)
│       ├── dashboards_controller.rb # Analytics summary
│       ├── users_controller.rb      # User management
│       ├── tasks_controller.rb      # Task oversight
│       ├── disputes_controller.rb   # Dispute resolution
│       └── payouts_controller.rb    # Financial oversight (existing)
├── views/
│   ├── admin/
│   │   ├── dashboards/
│   │   ├── users/
│   │   ├── tasks/
│   │   └── disputes/
│   └── layouts/
│       └── admin.html.erb           # Specialized admin layout
```

### Pattern 1: Admin Base Class
**What:** Encapsulate admin-only authorization and custom layout in a base class.
**When to use:** All admin controllers.
**Example:**
```ruby
# app/controllers/admin/base_controller.rb
class Admin::BaseController < ApplicationController
  layout 'admin'
  before_action :authenticate_user!
  before_action :ensure_admin!

  private

  def ensure_admin!
    redirect_to root_path, alert: "Access denied." unless current_user.admin?
  end
end
```

### Pattern 2: Analytics Aggregation
**What:** Use simple SQL aggregations for growth metrics.
**Example:**
```ruby
# app/controllers/admin/dashboards_controller.rb
def show
  @new_users_by_day = User.group_by_day(:created_at).count
  @tasks_completed_by_day = Task.completed.group_by_day(:completed_at).count
  @gmv_total = Task.completed.sum(:budget_cents)
end
```

### Anti-Patterns to Avoid
- **Raw SQL for aggregations:** Use `groupdate` to handle time-zone-aware SQL grouping.
- **Heavy Dashboards on Home Page:** Complex analytics should be behind an admin-only route to prevent performance leakage to public users.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Time-series charts | Custom JS chart logic | Chartkick | Handles tooltips, responsive resizing, and multiple adapters out of the box. |
| SQL date grouping | Custom date_trunc logic | Groupdate | Handles varying DB adapters (Postgres/MySQL/SQLite) and timezones. |
| Transaction Ledger | Custom balance tracking | DoubleEntry | Existing immutable ledger ensures financial integrity. |

## Runtime State Inventory

> This phase adds oversight to existing state. No migrations of existing data required, but new views for existing data will be created.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `DoubleEntry` ledger records | Build views to audit balances and transfers. |
| Stored data | `DisputeEvidence` photos | Interface to view evidences in Admin panel. |

## Common Pitfalls

### Pitfall 1: Data Leakage
**What goes wrong:** Admin-only views accidentally accessible via non-admin routes.
**Prevention strategy:** Inherit from `Admin::BaseController` which has strict `ensure_admin!` check. Use `pundit` for fine-grained resource actions.

### Pitfall 2: Performance (N+1 in Lists)
**What goes wrong:** Admin views listing hundreds of users/tasks without eager loading associations.
**Prevention strategy:** Always use `.includes(:user, :category)` etc. in index actions.

## Code Examples

### Dispute Resolution Action
```ruby
# app/controllers/admin/disputes_controller.rb
def resolve
  @task = Task.find(params[:id])
  if params[:decision] == 'release'
    @task.release_payment! # Triggers LedgerManager.release_from_escrow
    redirect_to admin_disputes_path, notice: "Funds released to tasker."
  else
    # New logic needed for refund
    Payments::LedgerManager.refund_poster(@task)
    @task.update!(status: :cancelled)
    redirect_to admin_disputes_path, notice: "Funds refunded to poster."
  end
end
```

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Ruby | Runtime | ✓ | 3.2.1 | — |
| Rails | Runtime | ✓ | 7.1.6 | — |
| PostgreSQL | Data Storage | ✓ | 17.4 | — |
| Chartkick | Analytics | ✗ | — | Install during Phase 07 |
| Groupdate | Analytics | ✗ | — | Install during Phase 07 |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | RSpec |
| Config file | spec/rails_helper.rb |
| Quick run command | `bundle exec rspec spec/requests/admin` |
| Full suite command | `bundle exec rspec` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADMIN-01 | Admin dashboard shows key growth metrics | request | `rspec spec/requests/admin/dashboard_spec.rb` | ❌ Wave 0 |
| ADMIN-02 | Admin can view and manage all users | system | `rspec spec/system/admin/user_management_spec.rb` | ❌ Wave 0 |
| ADMIN-03 | Admin can oversee all task lifecycles | system | `rspec spec/system/admin/task_monitoring_spec.rb` | ❌ Wave 0 |
| ADMIN-04 | Admin can resolve disputes with evidence | system | `rspec spec/system/admin/dispute_resolution_spec.rb` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `spec/requests/admin/dashboard_spec.rb` — covers analytics.
- [ ] `spec/system/admin/dispute_resolution_spec.rb` — covers dispute flow.
- [ ] `app/controllers/admin/base_controller.rb` — shared foundation.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V4 Access Control | yes | `ensure_admin!` before_action and Pundit policies. |
| V5 Input Validation | yes | Strong params for admin actions (rejection reasons, dispute decisions). |

### Known Threat Patterns for Rails Admin

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Insecure Direct Object Reference (IDOR) | Information Disclosure | Scoping admin queries to appropriate resources and checking permissions. |
| Mass Assignment | Elevation of Privilege | Strict `permit` lists in `Admin::` controllers. |

## Sources

### Primary (HIGH confidence)
- Existing codebase (`Admin::PayoutsController`, `Task` model, `DoubleEntry` config).
- Official Rails Documentation for Namespacing.
- Chartkick / Groupdate official documentation.

### Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Libraries are industry standard and confirmed current.
- Architecture: HIGH - Follows existing project patterns and standard Rails conventions.
- Pitfalls: MEDIUM - Performance risks are predictable but depend on future data volume.

**Research date:** 2026-04-18
**Valid until:** 2026-05-18
