# Phase 05: Trust, Safety & Support - Context

**Gathered:** 2026-04-16
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers the physical and social integrity layer of sewaLink. It ensures Taskers are physically present at jobs, provides a verified reputation system, and establishes a mechanism for evidence-based dispute resolution.

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
- `.planning/REQUIREMENTS.md` — Updated SAFE-01 through SAFE-04.

### Technical Context
- `Gemfile` — Geocoder gem (v1.8) is available for location logic.
- `app/models/task.rb` — Current task lifecycle and location storage.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Geocoder:** Already used in Phase 2 for task creation; use for distance calculation between `current_user` and `task.location`.
- **Active Storage:** Use for Mandatory Completion Photos and Dispute Evidence.
- **Turbo Streams:** Use to trigger UI updates (like activating the "Mark as Done" button) when geofence entry is detected.

</code_context>

<deferred>
## Deferred Ideas
- **AI Support Assistant:** Moved to Phase 8 for tech alignment.
- **Live Location Sharing:** Deferred (v2/Post-MVP).

</deferred>
