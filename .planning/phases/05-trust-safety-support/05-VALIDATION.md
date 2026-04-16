---
phase: 5
slug: trust-safety-support
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-16
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | RSpec |
| **Config file** | .rspec, spec/rails_helper.rb |
| **Quick run command** | `bundle exec rspec spec/models spec/services` |
| **Full suite command** | `bundle exec rspec spec/models spec/services spec/requests spec/system` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bundle exec rspec spec/models spec/services`
- **After every plan wave:** Run `bundle exec rspec`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | SAFE-01 | T-05-01 | Strict geofence enforcement | unit | `rspec spec/models/task_spec.rb` | ❌ W0 | ⬜ pending |
| 05-02-01 | 02 | 1 | SAFE-02 | T-05-02 | Blind review isolation | unit | `rspec spec/models/review_spec.rb` | ❌ W0 | ⬜ pending |
| 05-03-01 | 03 | 2 | SAFE-05 | T-05-03 | Message filtering | unit | `rspec spec/models/message_spec.rb` | ❌ W0 | ⬜ pending |
| 05-04-01 | 04 | 2 | SAFE-06 | T-05-04 | Contact masking | unit | `rspec spec/requests/messages_spec.rb` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `spec/models/task_spec.rb` — update for geofencing
- [ ] `spec/models/review_spec.rb` — new for reviews
- [ ] `spec/models/message_spec.rb` — new for filtering
- [ ] `spec/system/geofencing_spec.rb` — integration tests for on-site flow

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GPS Device Integration | SAFE-01 | Requires physical movement/simulator | Use browser location simulation in Capybara/Chrome |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
