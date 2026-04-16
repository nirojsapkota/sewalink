# Phase 2: Task Marketplace Core - Research

**Researched:** 2026-04-14
**Domain:** Marketplace Lifecycle, Bidding, & Real-time UI
**Confidence:** HIGH

## Summary

This phase implements the core marketplace loop: task creation by Posters, browsing by Taskers, and a bidding/assignment workflow. Following the mobile-first requirement, the implementation will leverage Rails 7.1's native features and Turbo 8's new morphing capabilities to provide a snappy, "SPA-like" experience without the overhead of a heavy JS framework.

**Primary recommendation:** Use Rails 7.1's `enum :status, ..., validate: true` for the task lifecycle and `broadcasts_refreshes` with Turbo 8 Morphing to keep lists and bid views synchronized across all users in real-time.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AUTH-03 | Dual-profile system | Current `User#active_role` enum and `ProfilesController#toggle_role` provide a solid base. Research confirms session-based role switching is standard for dual-profile apps. |
| TASK-01 | Task Creation | Standard Rails forms with `Active Storage` and `geocoder` for location handling. |
| TASK-03 | Rich Listings | `has_many_attached :photos` with Stimulus-based image previews for high-quality mobile UX. |
| TASK-04 | Browsing & Filters | `Turbo Frames` combined with `geocoder` radius searches and simple PG queries for proximity and category filtering. |
| TASK-05 | Bidding System | `Bid` model with real-time updates via `Turbo 8 Morphing`. Bids will be private to other Taskers but visible to the Poster. |
| TASK-06 | Task Assignment | `Task` lifecycle management using enums and transition-safe methods in the model. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| rails | ~> 7.1.2 | Web Framework | Native `enum` validation and Turbo 8 support. [VERIFIED: Gemfile] |
| turbo-rails | ~> 2.0 | Dynamic UI | Turbo 8 Morphing provides seamless updates without custom Stream partials. [CITED: turbo.hotwired.dev] |
| geocoder | ~> 1.8 | Proximity Search | Simple radius filtering and coordinate handling without PostGIS overhead. [VERIFIED: npm registry/rubygems] |
| pundit | ~> 2.3 | Authorization | Essential for restricting task/bid actions based on `active_role`. [ASSUMED: Industry Standard] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|--------------|
| image_processing | ~> 1.14 | Image Resizing | Required for Active Storage thumbnails. [VERIFIED: Gemfile] |
| kaminari | ~> 1.2 | Pagination | For performance in task browsing views. [ASSUMED] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| geocoder | PostGIS | PostGIS is faster for millions of records but adds dev/deployment complexity. Geocoder is enough for v1. |
| aasm | Rails 7.1 Enum | Native enums are simpler to maintain for small state machines. |

**Installation:**
```bash
# Add missing gems
bundle add geocoder pundit kaminari
rails generate pundit:install
rails generate geocoder:config
```

## Architecture Patterns

### Recommended Project Structure
```
app/
├── controllers/
│   ├── tasks_controller.rb       # Browsing/Creation
│   ├── bids_controller.rb        # Bidding/Assignment
├── models/
│   ├── task.rb                   # Lifecycle, Scopes
│   ├── bid.rb                    # Bidding Logic
│   ├── category.rb               # Task categories (Plumbing, Repair, etc.)
├── javascript/
│   ├── controllers/
│   │   ├── search_controller.js  # Live filter debouncing
│   │   ├── preview_controller.js # Image upload preview
```

### Pattern 1: Real-time Updates with Turbo 8 Morphing
Instead of manual `Turbo::StreamsChannel.broadcast_replace_to`, use the new "Happy Path":
```ruby
# app/models/task.rb
class Task < ApplicationRecord
  # Signals all clients watching this task's page or a list containing it
  # to refresh and morph their current view when data changes.
  broadcasts_refreshes
end
```

### Anti-Patterns to Avoid
- **N+1 on Listings:** Never render tasks without `.with_attached_photos` or `.includes(:user)`.
- **Race Condition in Assignment:** Avoid `task.update(status: :assigned)` without a database transaction and `lock_version` check if multiple users can accept simultaneously.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Proximity Math | Custom SQL | `geocoder` gem | Handles Haversine formula and various DB backends (SQLite/PG) transparently. |
| Authorization | Role checks in views | `Pundit` | Centralizes rules (e.g., "Only Taskers can bid" vs "Only Poster can see all bids"). |
| Image Previews | Complex JS | URL.createObjectURL | Simple Stimulus logic handles multi-file previews with ~10 lines of code. |

## Common Pitfalls

### Pitfall 1: Fragile Bid Forms
**What goes wrong:** User submits a bid, page refreshes, they lose context.
**How to avoid:** Use `Turbo Frames` to wrap the bid form. Use `requestSubmit()` in Stimulus for AJAX submission that doesn't break browser state.

### Pitfall 2: Over-indexing on Search
**What goes wrong:** implementing ElasticSearch/PostGIS too early.
**How to avoid:** Start with `Geocoder` + float columns. It's performant up to ~50k records and simplifies deployment.

## Code Examples

### Role-Switching UX
```ruby
# app/controllers/profiles_controller.rb
def toggle_role
  new_role = current_user.poster? ? 'tasker' : 'poster'
  current_user.update(active_role: new_role)
  # Turbo Morphing will update the navbar and current view automatically
  redirect_back fallback_location: root_path
end
```

### Live Filtering (Stimulus + Turbo Frame)
```javascript
// app/javascript/controllers/search_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]
  
  submit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, 300)
  }
}
```

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Geocoder performance is sufficient | Standard Stack | If 100k+ tasks at launch, queries might be slow. Mitigation: Add GIST index early if using PG. |
| A2 | Blind Bidding is preferred | Phase Requirements | User might expect open bidding. Mitigation: Confirm with user during Phase 2 setup. |
| A3 | Categories are static enough for a table | Architecture | If categories change hourly, hardcoding is better. Mitigation: DB table is more flexible. |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| ImageMagick | image_processing | ✓ | 7.1.1 | — |
| Redis | Action Cable / Turbo | ✓ | 7.x (PONG) | — |
| PostgreSQL | Data Storage | ✓ | 17.4 | — |

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V4 Access Control | yes | Pundit policies for Tasks/Bids |
| V5 Input Validation | yes | Strong parameters + Model-level enum validation |
| V6 Cryptography | yes | `ActiveRecord::Encryption` for sensitive bid data (if needed) |

### Known Threat Patterns for Marketplace

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Bid Tampering | Tampering | Authorize `update` action in Pundit; only allow creator. |
| Task Spying | Info Disclosure | Blind bidding via Pundit scopes (Taskers only see their own bids). |

## Sources

### Primary (HIGH confidence)
- [Official Rails Docs] - Enum validation (`validate: true`) and ActiveRecord::Encryption.
- [Hotwire.dev] - Turbo 8 Morphing and `broadcasts_refreshes`.
- [Geocoder Gem README] - Haversine proximity and radius search patterns.

### Secondary (MEDIUM confidence)
- Community patterns for marketplace role switching (session-based vs persistent).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Verified in Gemfile or latest Rails 7.1 standards.
- Architecture: HIGH - Matches established Rails/Hotwire patterns.
- Pitfalls: MEDIUM - Based on common marketplace experience.

**Research date:** 2026-04-14
**Valid until:** 2026-05-14
