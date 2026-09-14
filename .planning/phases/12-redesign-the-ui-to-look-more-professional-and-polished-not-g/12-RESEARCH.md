# Phase 12: Redesign the UI to look more professional and polished, not generic AI-generated - Research

**Researched:** 2026-09-14
**Domain:** Rails/Slim/Tailwind CSS v4 visual redesign (no JS framework, no component library)
**Confidence:** HIGH (codebase facts, directly verified) / MEDIUM-LOW (external font-coverage claims — no web-search tool was available this session)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Adopt "Modern Neutral SaaS" direction — slate/gray neutrals as dominant palette with a single indigo accent, in the visual family of Linear/Notion/Stripe-adjacent products.
- **D-02:** No Nepali-specific visual branding (no culturally-themed colors, patterns, or imagery). Design must read as international-standard SaaS/marketplace product. Functional bilingual content (Nepali/English text, NPR currency, eSewa branding where contractually/visually required) stays as-is.
- **D-03:** Explicitly move away from the current look: bright violet/purple (`#7C3AED` family) as primary brand color, heavy `backdrop-blur`, glow/shadow-heavy buttons, and hover `translate`/`scale` micro-animations on nearly everything. Replace with a calmer, more restrained interaction language (subtle transitions only, no bouncy hover effects by default).
- **D-04:** Primary accent: indigo (~`#4F46E5` / Tailwind `indigo-600`), used sparingly for primary actions, links, and key highlights — not as a dominant background color.
- **D-05:** Neutrals: slate scale for text/borders/surfaces (e.g. `slate-900` headings, `slate-600` body text, `slate-200` borders, `slate-50`/white backgrounds) replacing current purple-tinted neutrals (`#FAF5FF`, `#4C1D95`, etc.).
- **D-06:** Keep standard semantic colors (green success/online, red destructive/logout, amber warning) — conventional, not reinvented.
- **D-07:** Replace "Mukta" as primary UI font with **Inter** (or system-ui equivalent). Keep bilingual (Nepali/English) rendering compatibility in mind — verify Inter (or fallback stack) renders Devanagari acceptably, or pair with a Devanagari-safe fallback.
- **D-08:** Drop unused "Atkinson Hyperlegible" font import unless actively used — confirm during research.
- **D-09:** No `view_component` gem in use. Introduce a small set of shared Slim partials and/or Tailwind `@theme` design tokens (colors, spacing, shared button/card/form/badge styles) rather than redesigning each of 83 views ad hoc with more one-off hex codes.
- **D-10:** Prioritize order: (1) design tokens (`@theme` in `app/assets/tailwind/application.css`) + shared layout chrome (navbar, footer, flash, layouts) first; (2) core user-facing flows (home/landing, task listing/creation, dashboards, task detail/bids); (3) secondary flows (messaging, reviews, profile, notifications); (4) admin panel last.
- **D-11:** App wrapped via Hotwire Native for mobile — ensure comfortable tap targets, responsive spacing, native-app-appropriate feel — do NOT introduce a bottom tab bar or new navigation pattern.

### the agent's Discretion
- Exact Tailwind shade choices beyond given anchors (e.g. precise `indigo-600` vs `indigo-500`, exact spacing scale).
- Whether to introduce CSS custom properties/Tailwind `@theme` tokens vs. documented reusable utility class combinations, given no `view_component` gem.
- Icon treatment (check current icon usage; keep icons simple/line-style consistent with neutral aesthetic; add lightweight icon set only if needed).
- Whether admin panel gets a lighter pass (tokens/colors only) vs full redesign, given lowest priority.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.

**Note:** `12-UI-SPEC.md` already resolves nearly all of the above discretion areas into concrete decisions (D-12/D-13 numbering continues informally in that doc): Heroicons-outline-style hand-written inline SVG icons (no icon gem), `Inter, "Noto Sans Devanagari", ui-sans-serif, system-ui, sans-serif` font stack, admin gets tokens-and-primitives-only pass, `rounded-lg` buttons/inputs / `rounded-xl` cards / `rounded-full` pills. Treat UI-SPEC.md as the binding design contract; this research focuses on **implementation mechanics** in this specific codebase, not re-litigating visual choices.
</user_constraints>

<phase_requirements>
## Phase Requirements

No formal REQUIREMENTS.md entries map to this phase (net-new UI polish phase, not tied to v1/v1.1 REQ IDs). Traceability table in REQUIREMENTS.md has no ROW for Phase 12. Planner should NOT invent REQ-IDs; verification will be based on the UI-SPEC.md checker sign-off dimensions (Copywriting, Visuals, Color, Typography, Spacing, Registry Safety) rather than functional requirement IDs.
</phase_requirements>

## Summary

This is a pure visual restyle of an already-functional Rails 7 + Hotwire + Slim + Tailwind CSS v4 app. There is no `view_component` gem, no JS build step (Tailwind is compiled via the standalone `tailwindcss-ruby` binary through the `tailwindcss-rails` gem — no `tailwind.config.js`, no npm/node in the CSS pipeline; JS is importmap-based, unrelated to styling), and styling today is 100% inline Tailwind utility classes in Slim templates, heavily using arbitrary hex values (`bg-[#7C3AED]`, `text-[#4C1D95]/40`) rather than theme tokens. 259 arbitrary-hex-color class occurrences were found across 28 view files (verified via grep). The three layout files (`application`, `admin`, `landing`) and three helper methods (`nav_link_class`, `admin_nav_link_class`, `language_link_class` in `app/helpers/application_helper.rb`) are the highest-leverage single-edit points because they cascade to every page.

The codebase already has a `@theme` block in `app/assets/tailwind/application.css` (currently just `--font-sans: "Mukta"`) — this is the correct, idiomatic place to add the new design tokens (`--color-*`, `--font-sans`) per Tailwind v4 conventions, and Tailwind v4's CSS-first config means named custom colors defined there become directly usable as `bg-brand-600` etc. without any JS/config file changes. No test suite risk was found for color-class-specific assertions: the one system spec using `have_selector` asserts on an `h1` tag with text content, not classes, and no request/system specs anywhere assert on Tailwind color classes — the redesign is safe to execute broadly without expecting spec breakage, though system specs (Capybara + selenium_chrome_headless, 1 file found: `spec/system/task_status_system_spec.rb`, plus `spec/system/admin/task_monitoring_spec.rb`) should still be run per-wave as a smoke check since they render real pages end-to-end.

**Primary recommendation:** Add all new design tokens to the existing `@theme` block in `app/assets/tailwind/application.css` first (Wave 0), introduce 3–5 new Rails helper methods (not Slim partials, not view_component) returning class-string constants for button/badge/card variants to keep DRY without new architecture, then execute the D-10 four-wave rollout (chrome → core flows → secondary flows → admin light pass), verifying each wave visually plus running the 2 existing system specs as a non-regression smoke check.

## Standard Stack

### Core (already installed — no new dependencies needed)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|---------------|
| `tailwindcss-rails` | 4.4.0 [VERIFIED: Gemfile.lock] | Rails integration wrapper | Already in use; provides rake tasks (`tailwindcss:build`, `tailwindcss:watch`) |
| `tailwindcss-ruby` | 4.2.2 (platform-specific binary) [VERIFIED: Gemfile.lock] | Standalone Tailwind v4 compiler binary | No Node.js/npm required to build CSS — confirmed no `package.json`/`tailwind.config.js` exists in repo |
| `slim-rails` / `slim` | 5.2.1 [VERIFIED: Gemfile.lock] | Template engine | Already in use for all 79 view files found |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Google Fonts (Inter) | latest via `<link>` tag | Primary UI typeface | Same `<link>`-based loading pattern already used for Mukta/Atkinson — no new gem needed |
| Google Fonts (Noto Sans Devanagari) | latest via `<link>` tag | Devanagari-script fallback for Nepali-locale text | [ASSUMED — see below] Inter's official specimen covers Latin, Latin Extended, Cyrillic, Cyrillic Extended, Greek, Greek Extended, Vietnamese — **not** Devanagari. This is training-knowledge, not verified via a live tool call in this session (no web-search tool was available). Recommend a manual visual spot-check of Nepali text rendering with Inter alone as a Wave 0 task before committing to the fallback-stack assumption. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Rails helper methods returning class strings | `view_component` gem | Rejected by D-09 (not installed, out of scope to introduce for a visual-only phase) |
| Rails helper methods | Slim partials (`_button.html.slim` etc.) taking locals | Valid alternative; UI-SPEC.md mentions both (`shared/_button_primary` or `btn_classes(:primary)` helper) — see Architecture Patterns below for recommended split |
| `@theme` custom color tokens | Plain utility classes memorized/copy-pasted per file | Rejected — is exactly the "ad-hoc hex" problem D-09 aims to fix |
| Hand-authored inline SVG icons | Icon gem (`heroicons-rails`, `phlex-icons`, etc.) or CDN icon font | Rejected — UI-SPEC.md explicit discretion resolution (D-13): keep hand-authored inline SVGs, no new dependency, since only ~38 SVG occurrences exist total and the current visual style (Heroicons-outline, 24×24, stroke 1.5–2px) is already consistent |

**Installation:** None required — all tooling already present. No `npm install` / `bundle add` needed for this phase.

**Version verification:** Versions above pulled directly from `Gemfile.lock` in this repo [VERIFIED: Gemfile.lock, checked 2026-09-14]. This is a locked, already-installed stack — no registry check needed since nothing new is being added.

## Architecture Patterns

### Recommended Token Location
Extend the existing (currently minimal) `@theme` block in `app/assets/tailwind/application.css` — do NOT create a second theme file or a `tailwind.config.js` (Tailwind v4 + `tailwindcss-rails` does not use a JS config file; CSS-first `@theme` directive is the only supported customization surface for this setup) [VERIFIED: current file content, `tailwindcss-rails` 4.4.0/`tailwindcss-ruby` 4.2.2 confirmed installed with no config.js present in repo].

```css
/* Source: current app/assets/tailwind/application.css, extended per D-04/D-05/D-07 */
@import "tailwindcss";

@theme {
  --font-sans: "Inter", "Noto Sans Devanagari", ui-sans-serif, system-ui, sans-serif,
    "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji";
}
```

Note: Tailwind v4 already ships `slate`, `indigo`, `red`, `green`, `amber` in its default palette — UI-SPEC.md's colors (`slate-900`, `indigo-600`, etc.) are **default Tailwind palette classes**, not custom tokens that need defining in `@theme`. The only thing that strictly needs to go in `@theme` is `--font-sans` (already there, just needs the value swapped) and, optionally, any semantic aliases the team wants (e.g. `--color-brand: var(--color-indigo-600)`) for readability — but per UI-SPEC.md's exact class-level prescriptions (`bg-indigo-600`, `text-slate-600`, etc.), using stock Tailwind color utilities directly is sufficient and simpler than inventing semantic token names. **Recommendation: do not over-engineer custom color tokens; rely on Tailwind v4's built-in slate/indigo/red/green/amber scales directly, matching UI-SPEC.md's literal class names.**

### Recommended Project Structure (no new directories needed)
```
app/
├── assets/tailwind/application.css   # @theme font-family token update (Wave 0)
├── helpers/
│   └── application_helper.rb         # extend with new class-string helpers (button/badge/card variants)
├── views/
│   ├── layouts/                      # application, admin, landing — Wave 0 (chrome)
│   ├── shared/                       # _navbar, _flash, _logo — Wave 0 (chrome)
│   ├── home, tasks, posters, tasker_dashboard, bids  # Wave 1 (core flows)
│   ├── conversations, live_chats, messages, notifications, reviews, profiles  # Wave 2 (secondary flows)
│   └── admin/                        # Wave 3 (light pass — tokens/primitives only)
```

### Pattern 1: Class-string helper methods (extend `ApplicationHelper`)
**What:** Ruby methods returning a Tailwind class string, called from Slim as `class: button_class(:primary)`. Mirrors the existing pattern already used for `nav_link_class`, `admin_nav_link_class`, `language_link_class`, and `status_badge_class` in `app/helpers/application_helper.rb` [VERIFIED: read file directly].
**When to use:** For button/badge/input variants that repeat across many views with only a "variant" axis of difference (primary/secondary/destructive/ghost) — this is the lowest-friction option since it requires zero new files, follows an established convention already in the codebase, and Slim call sites change minimally (`class:` attribute swap only).
**Example:**
```ruby
# Source: pattern extends existing app/helpers/application_helper.rb style
def button_class(variant = :primary)
  base = "px-5 py-2.5 rounded-lg text-sm font-semibold transition-colors duration-150 cursor-pointer"
  case variant
  when :primary
    "#{base} bg-indigo-600 text-white hover:bg-indigo-700 focus-visible:ring-2 focus-visible:ring-indigo-600 focus-visible:ring-offset-2"
  when :secondary
    "#{base} bg-white text-slate-700 border border-slate-300 hover:bg-slate-50"
  when :destructive
    "#{base} bg-red-600 text-white hover:bg-red-700"
  end
end
```

### Pattern 2: Slim partials for structural repeats (cards, badges with icon+text)
**What:** `app/views/shared/_card.html.slim`, `_badge.html.slim` accepting locals, rendered via `= render "shared/card", title: ..., do |...|`.
**When to use:** When the repeated unit has *structure* (multiple nested elements: icon + label + count, or a card with header/body/footer slots), not just a class-string swap. Slim's `render` with a block (`= render "shared/card" do`) supports yielding content, similar to a lightweight component. Use this for Card and Badge (structural); use Pattern 1 (helper methods) for Button (near-pure class variance) and nav-link states (already established).
**Recommendation:** Mixed approach — this matches what UI-SPEC.md hints at ("shared/_button_primary or a btn_classes(:primary) helper") without prescribing one exclusively. Given the codebase's existing convention already leans on helper methods for button/nav/badge class logic (`status_badge_class` already exists and returns bg/text pairs per status), **extending that existing helper file is lower-risk and more consistent than introducing new partial files for buttons**, but introducing 1–2 new small shared partials (Card, Badge wrapper) is reasonable since no structural equivalent exists yet.

### Anti-Patterns to Avoid
- **Duplicating token values as new Ruby constants:** Don't create a parallel `AppColors::INDIGO_600 = "#4F46E5"` Ruby constant — Tailwind classes are already the source of truth; a second color-name mapping layer adds indirection with no benefit here (no non-Tailwind consumer of these colors exists, e.g. no PDF generation, no email-client-only inline CSS that can't use Tailwind classes — mailers already use plain inline styles per `user_mailer/otp_code.html.slim`, checked separately, and are out of primary scope per D-10's "layouts" list which lists `application`/`admin`/`landing`, not `mailer`).
- **Introducing `view_component` gem "just for this phase":** explicitly rejected by D-09; would be a structural change beyond a visual-only phase and risks scope creep the user did not approve.
- **New icon gem/CDN:** rejected by UI-SPEC.md D-13 discretion resolution — continue hand-authoring inline SVGs matching the existing Heroicons-outline convention (24×24 viewBox, `stroke="currentColor"`, `fill="none"`, 1.5–2px stroke-width) [VERIFIED: `app/views/shared/_logo.html.slim`, `_flash.html.slim`, `tasks/_task_card.html.slim`, `home/index.html.slim` all follow this exact pattern already].

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Design tokens / theme values | A custom SCSS/CSS-variable system parallel to Tailwind | Tailwind v4's native `@theme` directive + built-in `slate`/`indigo`/`red`/`green`/`amber` palettes | Already the mechanism this codebase uses (`--font-sans` exists there today); v4's CSS-first theming is specifically designed for this — no JS config, no rebuild step beyond the existing `tailwindcss:watch`/`:build` rake tasks |
| Reusable component styling with slots | A homegrown ViewComponent-like Ruby class/render pipeline | Slim `render partial, locals:` + Ruby helper methods (established pattern already in `ApplicationHelper`) | Introducing new component infrastructure is out of scope for a visual-only phase (D-09) and adds review surface area with no functional payoff |
| Icon set | New icon gem, npm icon package, or icon font/CDN | Continue hand-writing inline `<svg>` matching existing Heroicons-outline style | Only ~38 SVG usages total in the whole codebase — not enough volume to justify a new dependency; UI-SPEC.md already made this call (D-13) |
| Devanagari font pairing | Assuming Inter alone "just works" for Nepali text, or hand-rolling a custom webfont subsetting pipeline | Standard Google Fonts `<link>` tag for `Noto Sans Devanagari` as an explicit CSS fallback in the same `@theme --font-sans` stack | Same `<link>`-tag loading pattern already used for Mukta/Atkinson — zero new infra, just swap font names |

**Key insight:** This codebase already has the right lightweight primitives (Tailwind `@theme`, Ruby helper methods for class logic, Slim partials for shared markup) — the redesign should reuse and extend these, not introduce new abstraction layers. The "generic AI-generated" feel this phase corrects came from *decision choices* (purple, glow, motion) baked into inline classes, not from a missing framework.

## Common Pitfalls

### Pitfall 1: Missing an arbitrary-hex occurrence during mass replacement
**What goes wrong:** A `sed`/find-replace pass on `#7C3AED` misses variants with opacity modifiers (`bg-[#7C3AED]/10`, `text-[#4C1D95]/40`) or slightly different casing/whitespace, leaving stray purple accents after the "redesign is done."
**Why it happens:** Tailwind arbitrary-value syntax allows many suffix variants (`/5`, `/10`, `/20`, `/40`, `/60`, `/70`, `/80`) attached to the same hex code; naive string replace on just `bg-[#7C3AED]` misses `bg-[#7C3AED]/20`.
**How to avoid:** Use a regex-based approach (e.g. `grep -roE "bg-\[#[0-9A-Fa-f]{3,6}\](/[0-9]+)?"` or similar) to enumerate ALL distinct hex+opacity combinations first (this research found 259 raw occurrences across 28 files — see counts below), building a complete replacement table before any edit, rather than replacing color-by-color reactively.
**Warning signs:** `grep -rE "#[0-9A-Fa-f]{3,6}" app/views` still returns hits after a wave is marked "done."

### Pitfall 2: Breaking Slim bracket-attribute syntax during find/replace
**What goes wrong:** Several files use Slim's bracket-attribute syntax (`div[class="bg-[#FAF5FF] font-['Mukta'] text-[#4C1D95]"]`) which nests square brackets inside an attribute value already delimited by `[...]` — a careless regex replace across "the whole line" can corrupt the Slim tag delimiters, not just the class string.
**Why it happens:** Slim allows both dot-notation classes (`.bg-white.border`) and bracket-attribute syntax (`div[class="..."]`) in the same codebase (both are used here, e.g. `_navbar.html.slim` mixes both). A blind sed across `[...]` boundaries is fragile.
**How to avoid:** Scope replacements to the string *inside* `class="..."` only (match on `class="([^"]*)"` capture groups), never to the outer `[...]` Slim delimiters. Prefer per-file manual review pass for the ~28 files with arbitrary-hex classes (verified list below) rather than a single repo-wide scripted regex, given the file count is manageable (28 files, not hundreds).
**Warning signs:** Slim template raises a parse error (`Tilt::Slim::Template` error) on render after a scripted replace — run `bin/rails runner ""` or visit a page in dev to catch immediately.

### Pitfall 3: Assuming request/system specs will catch visual regressions
**What goes wrong:** Treating "specs are green" as equivalent to "redesign didn't break anything."
**Why it happens:** This app's specs (verified: only 2 files use `have_css`/`have_selector`/`assert_select` at all, and the single hit — `spec/system/admin/task_monitoring_spec.rb` — asserts on `h1` text content, not CSS classes) do not exercise styling at all. Specs will stay green even if a template's Slim syntax is technically broken in a way that still renders *some* HTML, or if colors regress to something off-brief.
**How to avoid:** Treat spec runs as a **markup-doesn't-crash** smoke check only, not a design-conformance check. Plans must include an explicit manual/visual review step per wave (e.g. spin up `bin/dev`, visit each redesigned page) — this is not optional given zero automated visual coverage exists.
**Warning signs:** None from CI — this must be caught by manual review, which the plan must schedule explicitly per wave.

### Pitfall 4: Devanagari rendering assumption going unverified
**What goes wrong:** Shipping `Inter, "Noto Sans Devanagari", ...` as the font stack without ever loading a Nepali-locale page to confirm Devanagari text actually falls back correctly (browsers usually get font-fallback-by-script right automatically, but web-font `<link>` loading order and `font-display` behavior can cause a flash of Devanagari-in-fallback-serif before the Noto font loads, which may look worse than the current Mukta-for-both-scripts approach).
**Why it happens:** No web-search tool was available this session to verify Inter's actual Unicode block coverage or test actual rendering — this claim rests on general (pre-training) knowledge that Inter's specimen doesn't list Devanagari.
**How to avoid:** Add an explicit Wave 0 manual-verification task: load a Nepali-locale page (`?locale=ne` or via UI toggle) with the new font stack in a real browser and visually confirm Devanagari glyphs render cleanly (no tofu boxes, no visually-jarring font mismatch between Latin and Devanagari runs in mixed-language strings).
**Warning signs:** Tofu boxes (☐☐☐) or a serif/fallback font rendering Devanagari text on the Nepali locale.

## Code Examples

### Current navbar pattern to replace (verified from live file)
```slim
/ Source: app/views/shared/_navbar.html.slim (current, to be replaced)
nav[class="bg-white/80 backdrop-blur-md shadow-sm sticky top-0 z-50 border-b border-[#7C3AED]/5"]
  = link_to root_path, class: "transition-all duration-300 hover:opacity-90 active:scale-95 transform" do
```

### Target pattern per UI-SPEC.md navigation section
```slim
/ Target, per 12-UI-SPEC.md "Navigation" section
nav.bg-white.sticky.top-0.z-50.border-b.border-slate-200
  = link_to root_path, class: "transition-opacity duration-150 hover:opacity-80" do
```

### Existing helper-method convention to extend (verified)
```ruby
# Source: app/helpers/application_helper.rb (current — extend, don't replace, this file's pattern)
def nav_link_class(path)
  base_classes = "text-sm transition-all duration-200 hover:-translate-y-0.5 active:translate-y-0"
  if current_page?(path)
    "#{base_classes} font-semibold text-[#7C3AED]"
  else
    "#{base_classes} font-medium text-[#4C1D95]/70 hover:text-[#7C3AED]"
  end
end
```
Target replacement keeps the same method signature/call sites (zero changes needed in any of the ~15 call sites across navbar/admin layout), only the returned class string changes — this is the single lowest-risk, highest-leverage edit in the whole phase.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Tailwind v3 JS config (`tailwind.config.js`, `theme.extend.colors`) | Tailwind v4 CSS-first `@theme` directive in the main CSS entry file | Tailwind v4 (2025) — this repo is already on `tailwindcss-ruby` 4.2.2 / `tailwindcss-rails` 4.4.0 [VERIFIED: Gemfile.lock] | Confirms the planner should NOT create/expect a `tailwind.config.js` — none exists, none should be added; all token work happens in `app/assets/tailwind/application.css` |

**Deprecated/outdated:** N/A — repo is already on current major versions of its styling toolchain; no migration needed as part of this phase.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|----------------|
| A1 | Inter's font specimen does not cover Devanagari script (Latin/Cyrillic/Greek/Vietnamese only) | Standard Stack, Common Pitfalls #4 | If wrong (Inter actually renders Devanagari acceptably), the `Noto Sans Devanagari` fallback is unnecessary extra weight/complexity — low harm either way, but worth a 2-minute manual browser check before committing the font-stack task |
| A2 | `Noto Sans Devanagari` is a correct, appropriately-styled (weight/x-height matched) pairing for Inter | Standard Stack | If visually mismatched, Nepali text could look inconsistent in weight/size next to Inter Latin text — mitigated by manual visual review task (already recommended in Pitfall #4) |
| A3 | No downstream consumer (PDF export, transactional-email-only styling, print stylesheet) depends on the current purple hex values outside the 79 Slim view files scanned | Anti-Patterns section | Low — mailers were spot-checked (`user_mailer/otp_code.html.slim` uses inline styles, not Tailwind classes, so out of scope regardless) but the other 5 mailer views weren't individually re-verified for embedded hex values |

**If this table is empty:** N/A — see rows above; all other claims in this document were verified directly against the repository (`Gemfile.lock`, live file contents, `grep` counts) in this session.

## Open Questions (RESOLVED — see planning output)

1. **(RESOLVED — split into 4 waves)** Should the phase be split into 4 separate PLAN.md waves matching D-10's priority order, or one large plan with 4 internal task-groups?
   - What we know: D-10 explicitly defines a 4-tier priority order (chrome → core flows → secondary flows → admin), and 28 files carry arbitrary-hex classes needing replacement, spread unevenly across those tiers (tokens+chrome: ~6 files; core flows — tasks/bids/dashboards: ~14 files; secondary — messaging/reviews/profile: ~5 files; admin: ~3 files touched, rest of admin's ~25 files get lighter/no hex-specific changes since admin currently uses mostly `gray-*` Tailwind defaults already, not purple hex — verified: `admin.html.slim` uses `bg-gray-100`/`bg-gray-800`, no arbitrary hex at all).
   - What's unclear: Whether the planner's granularity setting (`standard`, per config.json) implies one PLAN.md per wave (4 plans) or fewer, larger plans.
   - Recommendation: Given `parallelization: true` and `workflow.node_repair` in config, and that D-10 order is a *dependency* order (chrome cascades to every page, so must land first) rather than independent parallel work, recommend 4 sequential waves as separate plans (e.g. `12-01` chrome/tokens, `12-02` core flows, `12-03` secondary flows, `12-04` admin light pass), each independently reviewable/shippable per the phase's own "independently reviewable and shippable" goal.

2. **(RESOLVED — mailer views excluded)** Do the 6 Devise mailer views + `user_mailer/otp_code.html.slim` need visual updates in this phase?
   - What we know: They exist under `app/views/users/mailer/` and `app/views/user_mailer/`, use Slim, but email clients have very limited CSS support (no external stylesheets, often no `@theme`/Tailwind-class support depending on how they're compiled) — these were not in CONTEXT.md's explicit "4 layouts" list (`application`, `admin`, `landing`, and separately `mailer.html.slim`/`mailer.text.erb` are mentioned as a 4th layout in code_context but not deeply researched here).
   - What's unclear: Whether mailer styling is in-scope at all for "83 view files" count, and whether Tailwind classes even work in the mailer layout (`layouts/mailer.html.slim` wasn't inspected for whether it inlines a stylesheet or requires manual inline `style=` attributes, which is the email-safe convention).
   - Recommendation: Planner should explicitly scope-in or scope-out mailer templates in the first plan; if in-scope, expect to hand-write inline `style="..."` attributes (Tailwind classes typically do NOT survive in email HTML sent via most mail clients) rather than reusing Tailwind utility classes — this is a different, higher-effort task type than the rest of the phase and should not be estimated the same way.

## Environment Availability

Skip condition met partially — this phase is templates/CSS/Ruby-helper changes only, but does depend on the Tailwind build pipeline being runnable to visually verify changes locally.

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `tailwindcss-ruby` binary | Compiling `@theme` changes to CSS | ✓ [VERIFIED: Gemfile.lock] | 4.2.2 | — |
| `bin/rails tailwindcss:watch` / `bin/dev` | Local visual verification during implementation | ✓ [VERIFIED: `Procfile.dev` has `css: bin/rails tailwindcss:watch`] | n/a | — |
| Selenium + headless Chrome (system specs) | Running `spec/system/*` as smoke check | ✓ [VERIFIED: Gemfile `capybara`, `selenium-webdriver` in `:test` group; `driven_by :selenium_chrome_headless` in `rails_helper.rb`] | not version-pinned in Gemfile.lock excerpt checked | — |
| Google Fonts CDN reachability | Loading Inter + Noto Sans Devanagari `<link>` tags | Assumed reachable (same mechanism already used for Mukta/Atkinson in production) | n/a | If offline/blocked, fonts fall back to `ui-sans-serif, system-ui, sans-serif` per the existing stack tail — already accounted for in the font-family fallback chain |

**Missing dependencies with no fallback:** None identified.

**Missing dependencies with fallback:** Google Fonts CDN reachability — already has a system-font fallback baked into the `@theme --font-sans` stack.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | RSpec (`spec/` — primary, active suite) + a largely-empty Minitest `test/` scaffold (only `.keep` files found under `test/system`, `test/mailers` etc. — Rails-default scaffold, not actively used) [VERIFIED: `find test -name "*.rb"` returned 10 files vs. `find spec -name "*.rb"` returned 64 files; `.rspec` config present] |
| Config file | `spec/rails_helper.rb`, `spec/spec_helper.rb`, `.rspec` |
| Quick run command | `bundle exec rspec spec/system/task_status_system_spec.rb spec/system/admin/task_monitoring_spec.rb` |
| Full suite command | `bundle exec rspec` |

### Phase Requirements → Test Map
No formal REQ-IDs apply to this phase (see `phase_requirements` above). Instead, map to UI-SPEC.md's checker dimensions:

| Dimension | Behavior | Test Type | Automated Command | File Exists? |
|-----------|----------|-----------|---------------------|--------------|
| Non-regression: pages still render | Every redesigned template compiles/renders without Slim/HTML errors | system (smoke) | `bundle exec rspec spec/system/` | ✅ existing |
| Non-regression: text content unchanged (i18n keys preserved) | `have_selector("h1", text: ...)`-style assertions still pass | system | `bundle exec rspec spec/system/admin/task_monitoring_spec.rb` | ✅ existing |
| Visual conformance to UI-SPEC.md (colors, spacing, typography, motion) | N/A — no automated visual regression tooling exists in this repo | manual-only | manual browser walkthrough per wave, cross-checked against `12-UI-SPEC.md` component-pattern definitions | ❌ — no visual regression tool installed (e.g. no Percy/Chromatic/screenshot-diffing gem found in Gemfile) |

### Sampling Rate
- **Per task commit:** Manual visual check in `bin/dev` local server for the specific view(s) touched.
- **Per wave merge:** `bundle exec rspec spec/system/` (both existing system specs) + manual pass over all views touched in that wave (navbar/footer/flash appear on every page, so Wave 0's manual check should tour the whole app, not just one page).
- **Phase gate:** Full `bundle exec rspec` suite green (mostly unrelated to styling, but confirms no incidental breakage from a stray Slim syntax error) + final manual pass against UI-SPEC.md's 6 checker dimensions before marking the phase done.

### Wave 0 Gaps
- No automated visual-regression tooling exists (e.g. no screenshot-diff gem). Given this is a one-time redesign phase (not an ongoing design-system with regression risk), **recommend NOT introducing a visual regression testing tool for this phase** — the cost (new gem, baseline screenshot capture across 79 views) outweighs benefit for a single-pass redesign with a human-authored, human-reviewed UI-SPEC.md as the source of truth. Manual review per wave, checked against UI-SPEC.md's Checker Sign-Off dimensions, is the appropriate verification method here.
- None — existing RSpec system-spec infrastructure is sufficient for the narrow "does it still render / still say the right words" non-regression check this phase needs.

## Security Domain

Not applicable — this phase makes zero changes to authentication, authorization, session handling, input validation, or cryptography. It is a Tailwind-class/Slim-markup/font-loading change only. No new user input surfaces, no new data flows, no new external API integrations. `security_enforcement` should be treated as not-applicable for this phase's scope; a security reviewer need only confirm no `<script>`/`onclick=` or other unescaped-content patterns are introduced when touching flash/toast rendering (which already uses safe Rails helpers — verified `_flash.html.slim` uses `= message` interpolation via Rails' auto-escaping `=`, not raw HTML).

## Sources

### Primary (HIGH confidence — verified directly against this repository in this session)
- `Gemfile.lock` — confirmed `tailwindcss-rails` 4.4.0, `tailwindcss-ruby` 4.2.2, `slim` 5.2.1
- `Gemfile` — confirmed `capybara`, `selenium-webdriver` in `:test` group, no `view_component`, no icon gem
- `app/assets/tailwind/application.css` — confirmed current `@theme` block content (only `--font-sans: "Mukta"`)
- `app/views/layouts/{application,admin,landing}.html.slim` — read in full
- `app/views/shared/{_navbar,_flash,_logo}.html.slim` — read in full
- `app/helpers/application_helper.rb` — read in full, confirmed existing helper-method convention
- `find`/`grep` commands across `app/views` — confirmed 79 `.slim` files, 259 arbitrary-hex-color class occurrences across 28 files, 38 total `svg` occurrences, only 3 layout files reference "Mukta"/"Atkinson" (no per-view font overrides)
- `spec/` directory structure and `.rspec` — confirmed RSpec is the active test framework; `spec/system/task_status_system_spec.rb` and `spec/system/admin/task_monitoring_spec.rb` are the only files using `have_css`/`have_selector`/`assert_select`, neither asserts on styling classes
- `12-CONTEXT.md`, `12-UI-SPEC.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `copilot-instructions.md`/`PROJECT.md` snapshot — read in full per mandatory-read instructions

### Secondary (MEDIUM confidence)
None — no WebFetch/WebSearch tool was invoked or available this session.

### Tertiary (LOW confidence — flagged for validation, see Assumptions Log)
- Inter font's Unicode script coverage (does not include Devanagari) — based on training knowledge of the public Google Fonts specimen for Inter, not verified via a live tool call this session (no web-search/WebFetch tool was available in this agent's toolset). Flagged as A1/A2 in Assumptions Log; recommend a quick manual browser verification as a Wave 0 task rather than treating this as settled fact.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all versions/tools directly read from `Gemfile.lock`/`Gemfile`, no external verification needed since nothing new is being added
- Architecture: HIGH — patterns extend directly-observed existing conventions in this codebase (helper methods, `@theme` block, Slim partial structure)
- Pitfalls: HIGH for markup/regex/spec-coverage pitfalls (directly observed via grep); MEDIUM-LOW for the Devanagari font-coverage claim (no live verification tool available this session)

**Research date:** 2026-09-14
**Valid until:** No expiry concern — this is a static analysis of an already-fixed, already-installed dependency set (no fast-moving external API or library version to go stale). Re-check only if `Gemfile.lock` versions change before this phase executes.
