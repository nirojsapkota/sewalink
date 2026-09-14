---
status: partial
phase: 12-redesign-the-ui-to-look-more-professional-and-polished-not-g
source: [12-VERIFICATION.md]
started: 2026-09-14T20:00:00+10:00
updated: 2026-09-14T20:00:00+10:00
---

## Current Test

[awaiting human testing]

## Tests

### 1. Visual conformance to Modern Neutral SaaS direction
expected: Load home, tasks index/show, poster/tasker dashboards, messaging, profile, checkout, and Devise auth pages in a browser at mobile and desktop widths. Confirm slate/indigo "Modern Neutral SaaS" look with no purple, no glow, no bounce hover effects, a single clear visual anchor per screen, matching 12-UI-SPEC.md component patterns.
result: [pending]

### 2. Devanagari (Nepali locale) font rendering
expected: Switch to `?locale=ne` and view pages containing Nepali text (task titles/categories, nav labels, onboarding) with the new Inter + Noto Sans Devanagari fallback font stack. Devanagari glyphs should render legibly with no missing-glyph tofu boxes, and Inter should render cleanly for English text on the same page.
result: [pending]

### 3. Color contrast spot-check
expected: Inspect color contrast of slate-500/slate-600 text on white/slate-50 backgrounds and indigo-600 buttons/focus rings across representative pages using browser devtools or a contrast checker. Body text, muted text, and interactive elements should meet WCAG AA contrast ratios.
result: [pending]

## Summary

total: 3
passed: 0
issues: 0
pending: 3
skipped: 0
blocked: 0

## Gaps
