# Phase 12: Redesign the UI to look more professional and polished, not generic AI-generated - Context

**Gathered:** 2026-09-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Visual/UX redesign of sewaLink's existing Rails + Hotwire (Slim + Tailwind CSS v4) frontend. This phase changes HOW the app looks and feels — layout, color, typography, spacing, component styling, micro-interactions — across the app's ~83 view templates. It does not add new features, pages, or capabilities. Scope covers public pages, auth, poster/tasker dashboards, tasks, bids, messaging/live chat, notifications, reviews, profiles, and the admin panel.

</domain>

<decisions>
## Implementation Decisions

### Design Direction
- **D-01:** Adopt "Modern Neutral SaaS" direction — slate/gray neutrals as the dominant palette with a single indigo accent color, in the visual family of Linear/Notion/Stripe-adjacent products.
- **D-02:** No Nepali-specific visual branding (no culturally-themed colors, patterns, or imagery). Design must read as international-standard SaaS/marketplace product. Functional bilingual content (Nepali/English text, NPR currency, eSewa branding where contractually/visually required) stays as-is — this is about visual design language, not removing localization features.
- **D-03:** Explicitly move away from the current look: bright violet/purple (#7C3AED family) as primary brand color, heavy `backdrop-blur`, glow/shadow-heavy buttons, and hover `translate`/`scale` micro-animations on nearly everything. These read as generic "AI-generated template" style and should be replaced with a calmer, more restrained interaction language (subtle transitions only, no bouncy hover effects by default).

### Color Palette
- **D-04:** Primary accent: indigo (~`#4F46E5` / Tailwind `indigo-600`), used sparingly for primary actions, links, and key highlights — not as a dominant background color.
- **D-05:** Neutrals: slate scale for text/borders/surfaces (e.g. `slate-900` headings, `slate-600` body text, `slate-200` borders, `slate-50`/white backgrounds) replacing the current purple-tinted neutrals (`#FAF5FF`, `#4C1D95`, etc.).
- **D-06:** Keep standard semantic colors (green for success/online status, red for destructive/logout actions, amber for warnings) — these already exist in the codebase and should stay conventional, not be reinvented.

### Typography
- **D-07:** Replace "Mukta" as the primary UI font with **Inter** (or system-ui equivalent already available via Tailwind defaults) for a cleaner international SaaS feel. Keep bilingual (Nepali/English) rendering compatibility in mind — verify Inter (or fallback stack) renders Devanagari acceptably, or pair with a Devanagari-safe fallback for Nepali locale content.
- **D-08:** Drop the unused "Atkinson Hyperlegible" font import unless it's actively used somewhere — the agent's discretion to confirm during planning/research.

### Design System & Consistency
- **D-09:** No `view_component` gem currently in use — styling is done via inline Tailwind utility classes directly in Slim templates with hardcoded hex colors (e.g. `bg-[#7C3AED]`). Introduce a small set of **shared Slim partials and/or Tailwind `@theme` design tokens** (colors, spacing, shared button/card/form/badge styles) so the new look is consistent and maintainable, rather than redesigning each of the 83 views ad hoc with more one-off hex codes.
- **D-10:** Prioritize order: (1) design tokens (Tailwind `@theme` in `app/assets/tailwind/application.css`) + shared layout chrome (navbar, footer, flash/notifications, layouts) first, since these appear on every page; (2) core user-facing flows (home/landing, task listing/creation, dashboards, task detail/bids); (3) secondary flows (messaging, reviews, profile, notifications); (4) admin panel last, since it's lower-traffic and already has a separate layout.

### Mobile / Hotwire Native Feel
- **D-11:** App is wrapped via Hotwire Native for mobile, so redesign should ensure comfortable tap targets, responsive spacing, and a native-app-appropriate feel (already has a `md:hidden` mobile nav row) — but do NOT introduce a bottom tab bar or other new navigation pattern; that would be a structural/UX change beyond this visual redesign phase.

### the agent's Discretion
- Exact Tailwind shade choices beyond the anchors given above (e.g. precise `indigo-600` vs `indigo-500`, exact spacing scale) — implementer's judgment as long as it matches the "Modern Neutral SaaS" direction.
- Whether to introduce CSS custom properties/Tailwind `@theme` tokens vs. a documented set of reusable utility class combinations, given no `view_component` gem is installed.
- Icon treatment (the codebase's current icon usage should be checked during research; keep icons simple/line-style consistent with the neutral aesthetic, add a lightweight icon set only if needed).
- Whether admin panel gets a lighter pass (tokens/colors only) vs full redesign, given it's explicitly lowest priority.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

No external specs/ADRs found for this phase in ROADMAP.md, REQUIREMENTS.md, or PROJECT.md — this is a net-new phase not tied to existing v1/v1.1 requirements. Downstream agents should treat this CONTEXT.md as the primary source of truth for design direction.

### Existing Frontend Entry Points (for research/planning reference)
- `app/assets/tailwind/application.css` — current Tailwind v4 `@theme` config (only defines `--font-sans: "Mukta"`); this is where new design tokens should be added.
- `app/views/layouts/application.html.slim` — main layout: fonts, body background/text color, navbar/footer wrapper.
- `app/views/shared/_navbar.html.slim` — global nav, current purple color scheme and hover animation patterns to replace.
- `app/views/layouts/admin.html.slim`, `app/views/layouts/landing.html.slim` — additional layouts in scope.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `app/views/shared/` partials (navbar, logo, flash, footer) — central chrome shared across all pages; redesigning these first cascades the new look everywhere.
- Tailwind v4 already in use via `tailwindcss-rails` gem with `@theme` directive support — no separate `tailwind.config.js`; design tokens go directly in `app/assets/tailwind/application.css`.

### Established Patterns
- Styling is 100% inline Tailwind utility classes in Slim templates, frequently with arbitrary hex values (`bg-[#7C3AED]`, `text-[#4C1D95]/40`) rather than named/theme colors — this is the main source of visual inconsistency and "generated" feel.
- No `view_component` gem or component library currently installed.
- i18n (`t(...)`) used throughout for bilingual (English/Nepali) text — redesign must not disturb translation keys/content, only visual presentation.

### Integration Points
- 83 view files across: admin, bids, conversations, dispute_evidences, home, layouts, live_chats, messages, notifications, onboarding, payments, posters, profiles, reviews, shared, tasker, tasker_dashboard, tasks, user_mailer, users.
- 4 layouts: `application`, `admin`, `landing`, `mailer` (html + text).

</code_context>

<specifics>
## Specific Ideas

User requested a few concrete design direction options be presented rather than open-ended questions. Presented 4 directions (Trust Blue/Fintech, Modern Neutral SaaS, Marketplace Warm, Minimal Monochrome); user selected **Modern Neutral SaaS** (slate + indigo, Inter font, minimal shadows, generous whitespace, Linear/Notion-inspired). No Nepali-specific branding requested — international standard product look.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. No todos existed to fold in or defer.

</deferred>

---

*Phase: 12-redesign-the-ui-to-look-more-professional-and-polished-not-g*
*Context gathered: 2026-09-14*
