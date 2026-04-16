# Phase 05: Trust, Safety & Support - Context

**Gathered:** 2026-04-16
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers the physical, social, and communication integrity layer of sewaLink. It ensures Taskers are physically present, establishes community reputation, and provides a secure, monitored channel for coordination without exposing private contact info prematurely.

</domain>

<decisions>
## Implementation Decisions

### Geofencing & Location Verification
- **D-01: On-site Scope:** Add `on_site: boolean (default: true)` to the `Task` model. Geofencing logic applies strictly to tasks where `on_site` is true.
- **D-02: Auto-Check-in:** When a Tasker is assigned to an on-site task and opens the task view within a **200m radius**, the system automatically transitions the status to `in_progress`.
- **D-03: Hard Completion Block:** The "Mark as Done" action is strictly disabled unless the Tasker is currently within the 200m geofence.
- **D-04: Radius:** Default radius is set to **200m** to balance precision with GPS drift in urban environments.

### Social Trust (Reviews & Ratings)
- **D-05: Protected Public Model:** Only reviews left by **Posters for Taskers** are public.
- **D-06: Private Tasker Feedback:** Feedback from Taskers regarding Posters is captured as a **private note to Admin** (internal trust score) and never displayed publicly.
- **D-07: Blind Logic:** Neither party can see the other's feedback until both have submitted OR the 14-day window has expired.
- **D-08: Window:** A **14-day window** is established for leaving reviews post-completion.

### Communication & Privacy
- **D-12: Bid-Linked Messaging:** A private 1-to-1 chat thread is automatically initialized when a `Bid` is created.
- **D-15: Chat Lifecycle:** 
    1. **Bidding Stage:** Poster can chat privately with each bidder.
    2. **Assignment:** Non-assigned bidder chats are archived/hidden.
    3. **Active Stage:** Coordination continues for the assigned tasker.
    4. **Completion:** Chat remains open for 14 days post-completion (matching review window), then becomes **Read-Only**.
- **D-13: Contact Masking:** User phone numbers and email addresses are **strictly hidden** in the UI (profiles, task views) until the task status is `assigned`. 
- **D-16: Message Content Filtering:** Implement regex-based masking for phone numbers and email addresses within chat messages. This filter is active for all parties until the task is `assigned`, after which it is lifted only for the Poster and the Assigned Tasker.
- **D-14: Messaging Scope:** Chat remains active from the moment a bid is placed until 14 days after the task is `completed`.

### Evidence & Disputes
- **D-09: Mandatory Completion Photo:** Taskers **must** take/upload a photo while on-site to verify completion before the `completed` status can be saved.
- **D-10: Post-Payment Evidence:** Posters retain the ability to upload evidence (photos/videos) even after payment is released to support late-discovery disputes.

### AI Evolution (Roadmap Change)
- **D-11: AI Support Consolidation:** The AI Support Assistant (SAFE-03) is deferred to **Phase 8** to utilize the same high-fidelity streaming tech (Gemini Live) planned for the unified AI chat.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Core Specs
- `.planning/ROADMAP.md` — Updated phase definitions.
- `.planning/REQUIREMENTS.md` — Updated SAFE-01 through SAFE-06.

### Technical Context
- `Gemfile` — Geocoder gem (v1.8) is available.
- `app/models/task.rb` — Current task lifecycle.
- `app/models/bid.rb` — Initial message source.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Geocoder:** Already used for distance calculation.
- **Active Storage:** Use for Mandatory Completion Photos and Dispute Evidence.
- **Turbo Streams:** Use for live messaging updates and geofence state changes.

### Integration Points
- **Bids#create:** Hook here to initialize the `Conversation` or `Message` thread.
- **Profiles/Tasks UI:** Apply conditional visibility logic for phone/email based on `task.assigned_to?(user)`.
- **Message#content:** Add a helper or callback to apply regex masking before rendering/saving.

</code_context>

<deferred>
## Deferred Ideas
- **AI Support Assistant:** Moved to Phase 8.
- **Live Location Sharing:** Deferred (v2/Post-MVP).

</deferred>
