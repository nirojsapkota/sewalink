# Phase 5: Trust, Safety & Support - Research

**Researched:** 2024-04-16
**Domain:** Trust, Safety, Geofencing, Blind Reviews, In-App Messaging
**Confidence:** HIGH

## Summary

This research establishes the technical foundation for Phase 5, focusing on location-based task integrity, social reputation through blind reviews, and secure communication. We will leverage the existing `geocoder` gem for physical verification, introduce a bid-linked messaging architecture for secure coordination, and implement a "blind" review system to ensure unbiased social trust.

**Primary recommendation:** Use a Stimulus-driven geolocation pattern for auto-check-in and a robust state-machine validation to block completion unless the Tasker is physically within the 200m geofence.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01: On-site Scope:** Add `on_site: boolean (default: true)` to the `Task` model. Geofencing logic applies strictly to tasks where `on_site` is true.
- **D-02: Auto-Check-in:** When a Tasker is assigned to an on-site task and opens the task view within a **200m radius**, the system automatically transitions the status to `in_progress`.
- **D-03: Hard Completion Block:** The "Mark as Done" action is strictly disabled unless the Tasker is currently within the 200m geofence.
- **D-04: Radius:** Default radius is set to **200m** to balance precision with GPS drift in urban environments.
- **D-05: Protected Public Model:** Only reviews left by **Posters for Taskers** are public.
- **D-06: Private Tasker Feedback:** Feedback from Taskers regarding Posters is captured as a **private note to Admin** (internal trust score) and never displayed publicly.
- **D-07: Blind Logic:** Neither party can see the other's feedback until both have submitted OR the 14-day window has expired.
- **D-08: Window:** A **14-day window** is established for leaving reviews post-completion.
- **D-12: Bid-Linked Messaging:** A private 1-to-1 chat thread is automatically initialized when a `Bid` is created.
- **D-15: Chat Lifecycle:** 
    1. **Bidding Stage:** Poster can chat privately with each bidder.
    2. **Assignment:** Non-assigned bidder chats are archived/hidden.
    3. **Active Stage:** Coordination continues for the assigned tasker.
    4. **Completion:** Chat remains open for 14 days post-completion (matching review window), then becomes **Read-Only**.
- **D-13: Contact Masking:** User phone numbers and email addresses are **strictly hidden** in the UI (profiles, task views) until the task status is `assigned`. 
- **D-16: Message Content Filtering:** Implement regex-based masking for phone numbers and email addresses within chat messages. This filter is active for all parties until the task is `assigned`, after which it is lifted only for the Poster and the Assigned Tasker.
- **D-14: Messaging Scope:** Chat remains active from the moment a bid is placed until 14 days after the task is `completed`.
- **D-09: Mandatory Completion Photo:** Taskers **must** take/upload a photo while on-site to verify completion before the `completed` status can be saved.
- **D-10: Post-Payment Evidence:** Posters retain the ability to upload evidence (photos/videos) even after payment is released to support late-discovery disputes.

### the agent's Discretion
- Messaging implementation details (Turbo Streams vs standard polling - *Decision: Turbo Streams*).
- Specific regex patterns for Nepal number masking.
- Database schema for the Blind Review system.

### Deferred Ideas (OUT OF SCOPE)
- **AI Support Assistant:** Moved to Phase 8.
- **Live Location Sharing:** Deferred (v2/Post-MVP).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SAFE-01 | Geofencing: Taskers must be within perimeter to mark as 'Done'. | `geocoder` gem + Stimulus `geolocation` controller. |
| SAFE-02 | Social Trust: Mutual ratings and reviews. | Blind review schema + 14-day background job/logic. |
| SAFE-04 | Evidence Submission: Photo/video for disputes. | `ActiveStorage` + custom AASM validations. |
| SAFE-05 | In-App Messaging: Bid-linked chat. | `Conversation` belongs to `Bid` architecture. |
| SAFE-06 | Contact Masking: Hide phone/emails + filter messages. | Regex masking + conditional UI rendering. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Geocoder | 1.8 | Distance calculation | [VERIFIED: Gemfile] De facto standard for Rails location logic. |
| AASM | 5.5 | Task lifecycle state management | [VERIFIED: Gemfile] Provides clean transition hooks and validations. |
| ActiveStorage | Rails 7.1 | Evidence & Completion photos | [VERIFIED: Rails standard] Native integration with AWS/GCS/Disk. |
| Turbo | Rails 7.1 | Real-time chat & UI updates | [VERIFIED: Gemfile] High-performance updates without manual JS. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|--------------|
| Sidekiq/Solid Queue | TBD | Closing review windows | Auto-publish reviews after 14 days. |

**Installation:**
```bash
# Geocoder, AASM already installed.
# Need to generate migrations for reviews and conversations.
```

## Architecture Patterns

### Recommended Project Structure
```
app/
├── javascript/
│   └── controllers/
│       └── geolocation_controller.js  # Geolocation API bridge
├── models/
│   ├── conversation.rb               # Bid-linked chat container
│   ├── message.rb                    # Individual messages with content filtering
│   └── review.rb                     # Blind review logic
├── services/
│   └── content_filter_service.rb     # Regex masking logic
└── views/
    ├── conversations/                # Chat UI
    └── reviews/                      # Blind review forms
```

### Pattern 1: Geofence Validation (AASM)
Integrate distance checks directly into the state machine to ensure hard enforcement.
```ruby
# [ASSUMED Pattern]
event :complete do
  transitions from: :in_progress, to: :completed, 
              guard: :within_geofence?,
              if: :completion_photo_attached?
end
```

### Pattern 2: Bid-Linked Messaging
Each `Bid` initializes its own `Conversation`. This isolates negotiations and coordination to the specific context of the offer.

### Anti-Patterns to Avoid
- **Manual Polling:** Don't use setInterval for chat; use Turbo Streams.
- **Client-only Geofencing:** Never trust the client for completion verification. Always verify coordinates on the server using `Geocoder`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Distance Math | Haversine formula | `geocoder` gem | Handles edge cases, units, and spherical math correctly. |
| State Validation | Manual `if/else` in controller | `AASM` Guards | Centralizes logic and prevents invalid transitions from console/API. |
| File Uploads | Custom controller/storage | `ActiveStorage` | Security, cloud-readiness, and variant support out of the box. |

## Common Pitfalls

### Pitfall 1: GPS Drift & Accuracy
**What goes wrong:** User is at the location, but GPS says they are 205m away (D-04 radius is 200m).
**How to avoid:** Provide clear UI feedback ("You are 5m outside the zone"). Implement a "Manual Location Refresh" button. Use `enableHighAccuracy: true` in JS.

### Pitfall 2: Message Masking Bypass
**What goes wrong:** Users typing "9 8 4 1..." or "nine-eight-four..."
**How to avoid:** Use regex that accounts for common separator variations (hyphens, spaces). 
**Note:** Absolute prevention is impossible; the goal is to *deter* and protect accidental exposure.

### Pitfall 3: Blind Review Leaks
**What goes wrong:** One party sees the review count/rating increase before they submit their own.
**How to avoid:** Ensure the `Review` status/visibility is strictly enforced in the Model/Policy, not just the View.

## Code Examples

### Nepal Phone Number Regex
Used for both validation and content filtering.
```ruby
# Source: Nepal Telecommunications Authority (NTA) Numbering Plan 2024
NEPAL_PHONE_REGEX = /(\+977|00977)?(9[678]\d{8}|0[1-9]\d{7})/

# In Message.rb
def filtered_content
  return content if conversation.task.assigned? # Lift mask if assigned
  content.gsub(NEPAL_PHONE_REGEX, "[CONTACT MASKED]")
end
```

### Geolocation Stimulus Controller
```javascript
// app/javascript/controllers/geolocation_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.checkGeofence()
  }

  checkGeofence() {
    navigator.geolocation.getCurrentPosition((pos) => {
      const { latitude, longitude } = pos.coords
      // Send to server via Turbo.visit or Fetch to trigger auto-check-in
    }, null, { enableHighAccuracy: true })
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Generic Inbox | Contextual Conversations | Recent Apps | Reduces noise, keeps history tied to the specific job. |
| Public Reviews | Blind Reviews | 2018+ (Airbnb model) | Prevents "retaliatory" reviews; increases honesty. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Task location is geocodable to lat/lng. | Summary | Distance checks will fail if location string is ambiguous. |
| A2 | Users have GPS-enabled devices. | Geofencing | On-site completion will be impossible for non-GPS users. |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Geocoder | SAFE-01 | ✓ | 1.8 | — |
| PostGIS/PG | Geofencing | ✓ | 16 (PG) | Standard Ruby Geocoder math |
| ActiveStorage | SAFE-04 | ✓ | 7.1 | — |
| Redis | Turbo Streams | ✗ | — | Async/Polling (Needs Redis for Production) |

**Missing dependencies with no fallback:**
- **Redis:** Required for ActionCable/Turbo Streams in production environments. Local `async` adapter works for development but lacks multi-server scaling.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | RSpec + Capybara |
| Config file | `spec/rails_helper.rb` |
| Quick run command | `bundle exec rspec spec/models/review_spec.rb` |
| Full suite command | `bundle exec rspec` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SAFE-01 | Block completion if distance > 200m | Unit/Model | `rspec spec/models/task_spec.rb` | ❌ Wave 0 |
| SAFE-02 | Review content hidden until both submit | Unit/Model | `rspec spec/models/review_spec.rb` | ❌ Wave 0 |
| SAFE-05 | Message masks numbers until assigned | Integration | `rspec spec/requests/messages_spec.rb` | ❌ Wave 0 |

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V4 Access Control | yes | Pundit: Only assigned Tasker/Poster can access Chat/Evidence. |
| V5 Input Validation | yes | Regex filtering for messages; Image size/type validation for evidence. |

### Known Threat Patterns for Rails

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Insecure Direct Object Reference (IDOR) | Information Disclosure | Scoped queries (e.g., `current_user.conversations.find(params[:id])`) |
| Location Spoofing | Tampering | High-accuracy flag in client + sanity checks on server (velocity checks). |

## Sources

### Primary (HIGH confidence)
- `Gemfile` - Verified libraries (Geocoder, AASM).
- `db/schema.rb` - Current data structure.
- [Official Geocoder Docs](https://github.com/alexreisner/geocoder) - Distance methods.

### Secondary (MEDIUM confidence)
- Nepal Telecommunications Authority - Numbering plan for regex.
- Rails real-time patterns - Stimulus/Turbo best practices.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Libraries already in use or standard Rails.
- Architecture: HIGH - Follows established marketplace patterns (Airbnb/Uber).
- Pitfalls: MEDIUM - Dependent on user device GPS quality.

**Research date:** 2024-04-16
**Valid until:** 2024-05-16
