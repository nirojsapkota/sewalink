# Phase 3 — UI Review

**Audited:** 2026-04-14
**Baseline:** design-system/sewalink/MASTER.md
**Screenshots:** Not captured (code-only audit)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Localized landing page is excellent, but checkout view is English-only. |
| 2. Visuals | 3/4 | Theme colors correctly applied, but checkout view uses indigo. |
| 3. Color | 3/4 | Consistent purple/green usage, with minor indigo leftovers. |
| 4. Typography | 2/4 | High-quality Mukta font used, but too many font sizes (>8) in one view. |
| 5. Spacing | 4/4 | Consistent Tailwind spacing scale usage throughout. |
| 6. Experience Design | 3/4 | Good use of loading spinners and interaction feedback. |

**Overall: 18/24**

---

## Top 3 Priority Fixes

1. **Fix `indigo-600` in `checkout.html.erb`** — Visual inconsistency — Replace `indigo-600` with `#7C3AED` (Primary Purple) and `border-indigo-600` with `border-[#7C3AED]`.
2. **Localize `checkout.html.erb`** — Accessibility gap — Add `landing.redirecting_to_esewa` and `landing.proceed_to_esewa` keys to `en.yml` and `ne.yml`.
3. **Consolidate font sizes on landing page** — Typography clutter — Reduce the number of font sizes from 8 down to 4 standardized sizes (e.g., Use `text-5xl` for all H1s, `text-3xl` for H2s, `text-xl` for subtitles, and `text-base` for body).

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)
- **Strengths:** Excellent translation coverage for the landing page (`t('landing.*')`). Clear, benefit-driven CTAs in both English and Nepali.
- **Gaps:** `app/views/payments/checkout.html.erb` contains hardcoded English strings:
  - Line 2: `Redirecting to eSewa...`
  - Line 18: `Proceed to eSewa`

### Pillar 2: Visuals (3/4)
- **Strengths:** Visual hierarchy on the landing page is strong with clear hero and feature sections. Use of backdrop-blur and glassmorphism in the navbar looks modern.
- **Gaps:**
  - `app/views/payments/checkout.html.erb` uses `indigo-600` which clashes with the platform's primary purple.
  - The role switcher in `shared/_navbar.html.erb` uses `animate-pulse` correctly but could benefit from more distinct visual feedback for active vs. inactive roles.

### Pillar 3: Color (3/4)
- **Strengths:** Successful implementation of the "#7C3AED" (Primary Purple) and "#22C55E" (Transaction Green) palette across the site.
- **Gaps:**
  - `app/views/payments/checkout.html.erb:3`: `border-indigo-600`
  - `app/views/payments/checkout.html.erb:18`: `bg-indigo-600`

### Pillar 4: Typography (2/4)
- **Strengths:** `Mukta` font is a great choice for the Nepali market, providing excellent legibility for both scripts.
- **Gaps:**
  - **Size Proliferation:** The landing page (`home/index.html.erb`) uses: `6xl`, `5xl`, `4xl`, `3xl`, `2xl`, `xl`, `lg`, `sm`. This is too many sizes and violates the "4 sizes maximum" rule of thumb.
  - **Baseline Mismatch:** `MASTER.md` specifies `Atkinson Hyperlegible` as the primary font, but `Mukta` is used instead. While justified for the market, the design system should be updated to reflect this choice.

### Pillar 5: Spacing (4/4)
- **Strengths:** Consistent use of standard Tailwind spacing tokens (e.g., `py-16 md:py-24`, `space-y-8`, `gap-12`).
- **Gaps:**
  - `app/views/home/index.html.erb:200`: `rounded-[3rem]` is an arbitrary value, though it works well for the design's "blobby" aesthetic.

### Pillar 6: Experience Design (3/4)
- **Strengths:** 
  - Loading spinner in `checkout.html.erb` provides immediate feedback during redirects.
  - Smooth transitions (`transition-all`, `duration-200`) on buttons and cards.
- **Gaps:**
  - Lack of clear "empty state" handling in the Tasker Wallet view if no transactions are present.

---

## Files Audited
- `app/views/home/index.html.erb`
- `app/views/payments/checkout.html.erb`
- `app/views/shared/_navbar.html.erb`
- `app/views/layouts/application.html.erb`
- `app/views/layouts/landing.html.erb`
- `app/views/tasker/wallets/show.html.erb`
- `app/views/tasks/index.html.erb`
- `config/locales/en.yml`
- `config/locales/ne.yml`
- `design-system/sewalink/MASTER.md`
