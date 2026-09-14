---
phase: 12
slug: redesign-the-ui-to-look-more-professional-and-polished-not-g
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-09-14
---

# Phase 12 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | RSpec (rspec-rails) — request specs + system specs |
| **Config file** | `.rspec`, `spec/rails_helper.rb` |
| **Quick run command** | `bundle exec rspec spec/system spec/requests --fail-fast` |
| **Full suite command** | `bundle exec rspec` |
| **Estimated runtime** | ~60-120s (system specs) |

---

## Sampling Rate

- **After every task commit:** Run relevant `spec/system/*` and `spec/requests/*` specs touching the edited views (no CSS-class assertions exist, so this is a smoke check for broken markup/routes, not a visual check)
- **After every plan wave:** Run `bundle exec rspec spec/system spec/requests` (full request/system subset) + mandatory manual visual review of changed pages
- **Before `/gsd-verify-work`:** Full suite must be green AND a manual visual pass of all changed pages/breakpoints must be completed
- **Max feedback latency:** ~120 seconds (automated) + manual review per wave

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|--------------------|-------------|--------|
| 12-01-01 | 01 | 1 | Design tokens + shared chrome (navbar/footer/layouts) render without errors | — | N/A (visual-only) | system | `bundle exec rspec spec/system` | ✅ | ⬜ pending |
| 12-02-01 | 02 | 2 | Core flows (home, tasks, dashboards, bids) render without errors | — | N/A (visual-only) | system/request | `bundle exec rspec spec/system spec/requests` | ✅ | ⬜ pending |
| 12-03-01 | 03 | 3 | Secondary flows (messaging, reviews, profile, notifications) render without errors | — | N/A (visual-only) | system/request | `bundle exec rspec spec/system spec/requests` | ✅ | ⬜ pending |
| 12-04-01 | 04 | 4 | Admin panel token/primitive swap renders without errors | — | N/A (visual-only) | system/request | `bundle exec rspec spec/system spec/requests` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — RSpec system/request specs already exist and exercise the views in scope (routing/rendering smoke coverage). No new test files or framework installs are needed for Wave 0.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|--------------------|
| Visual conformance to UI-SPEC.md tokens (color/typography/spacing) | D-01–D-11 (CONTEXT.md), UI-SPEC.md | No automated visual-regression or CSS-class assertions exist in the suite (confirmed via RESEARCH.md — only 2 spec files use CSS selectors, and neither asserts on classes) | After each wave, load the changed pages in a browser at mobile + desktop widths, compare against UI-SPEC.md tokens/component patterns (colors, spacing, button/card/nav styles, no leftover `bg-[#...]` hex classes) |
| Devanagari (Nepali locale) font rendering with Inter + fallback | D-07 (CONTEXT.md) | Font rendering/glyph coverage can't be asserted by RSpec; requires visual inspection | Switch to `?locale=ne`, load a page with Nepali text, confirm no missing-glyph tofu boxes and that the fallback font renders legibly alongside Inter for English text |
| Icon-only element accessible names | UI-SPEC.md (Icon-Only Elements — Accessibility) | Requires screen-reader/DOM inspection, not covered by existing specs | Inspect icon-only buttons (nav toggle, close buttons) in devtools; confirm `aria-label` or visually-hidden text is present |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (existing system/request specs) plus mandatory manual visual verification layered on top
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (every wave has a system/request spec run)
- [x] Wave 0 covers all MISSING references (none missing — existing specs suffice)
- [x] No watch-mode flags
- [x] Feedback latency < 120s (automated portion)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-09-14 — visual-only phase; automated specs verify no regressions/broken markup, manual review is the primary verification method for the design intent itself (documented above, not a gap).
