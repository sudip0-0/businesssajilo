---
name: BusinessSajilo
colors:
  surface: '#faf8ff'
  surface-dim: '#dad9e1'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f4f3fa'
  surface-container: '#eeedf4'
  surface-container-high: '#e9e7ef'
  surface-container-highest: '#e3e1e9'
  on-surface: '#1a1b21'
  on-surface-variant: '#444651'
  inverse-surface: '#2f3036'
  inverse-on-surface: '#f1f0f7'
  outline: '#757682'
  outline-variant: '#c5c5d3'
  surface-tint: '#4059aa'
  primary: '#00236f'
  on-primary: '#ffffff'
  primary-container: '#1e3a8a'
  on-primary-container: '#90a8ff'
  inverse-primary: '#b6c4ff'
  secondary: '#006c49'
  on-secondary: '#ffffff'
  secondary-container: '#6cf8bb'
  on-secondary-container: '#00714d'
  tertiary: '#4b1c00'
  on-tertiary: '#ffffff'
  tertiary-container: '#6e2c00'
  on-tertiary-container: '#f39461'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dce1ff'
  primary-fixed-dim: '#b6c4ff'
  on-primary-fixed: '#00164e'
  on-primary-fixed-variant: '#264191'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#ffdbcb'
  tertiary-fixed-dim: '#ffb691'
  on-tertiary-fixed: '#341100'
  on-tertiary-fixed-variant: '#773205'
  background: '#faf8ff'
  on-background: '#1a1b21'
  surface-variant: '#e3e1e9'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  display-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
  display-md-mobile:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  container-margin: 24px
  gutter: 16px
---

## Brand & Style

The design system is engineered for efficiency, reliability, and local relevance. It targets small to medium enterprise owners who require a stable tool to manage complex business operations. The brand personality is **Professional, Trustworthy, and Efficient**.

**Mobile** follows a **Corporate / Modern** aesthetic: clarity and utility, structured grid, subtle elevation, cool neutrals. **Web** uses a distinctive **Digital Ledger** (डिजिटल खाता) aesthetic — warm paper, ink-navy rail, brass accents — while keeping the same navy brand anchor (`#00236F`). Both surfaces must feel grounded and institutional for users transitioning from paper ledgers to digital management.

---

## Mobile (source of truth for `BsColors` / Inter)

### Colors

This palette facilitates quick decision-making on Android/iOS:

- **Primary (Navy Blue):** Primary actions, branding, and navigation.
- **Secondary (Vibrant Green):** Success states, "Paid", positive growth.
- **Accent (Amber):** Warning / pending attention only.
- **Neutrals:** Cool greys. Scaffold `#F9FAFB` (`BsColors.background`); elevated surfaces `#FAF8FF` (`BsColors.surface`).

Text uses Deep Charcoal (`#111827`) for contrast on light backgrounds.

### Typography

**Inter** (bundled under `assets/fonts/`) for Latin UI and **Noto Sans Devanagari** as the Devanagari fallback.

- **Bi-lingual Balance:** Line-height at least 1.4x so Devanagari matras do not clip.
- **Numerical Clarity:** Tabular lining for figures in tables and invoices.
- **Hierarchy:** Headlines use tighter tracking and heavier weights; labels may use all-caps with subtle tracking (0.05em).

### Layout & Spacing (mobile)

Fluid grid; 8pt rhythm (multiples of 4px/8px). Bottom navigation or full-screen overlay on small screens. Medium density for general workflows; compact density for data-heavy lists.

### Elevation, shapes, components (mobile)

Tonal layers on cool grey canvas; soft corner radii; **status badges use soft-fill pills** (tinted background + same-hue text). Primary buttons are solid navy; success actions may use green. Tables hover with light grey (`#F3F4F6`).

---

## Web — Digital Ledger

Web-only tokens live in `lib/web/theme/web_palette.dart`, `web_tokens.dart`, `web_typography.dart`, and `web_theme.dart`. **Do not** move paper/brass tokens into `BsColors` unless product decides to restyle mobile.

### Surfaces & color

| Role | Token | Hex |
|------|--------|-----|
| Paper canvas | `WebPalette.paper` | `#F7F4EC` |
| Recessed / hover | `WebPalette.paperDeep` | `#EFEBDF` |
| Card | `WebPalette.card` | `#FFFDF8` |
| Ink text | `WebPalette.ink` | `#17202E` |
| Hairline | `WebPalette.hairline` | `#E4DECF` |
| Brand navy | `WebPalette.navy` | `#00236F` |
| Ink rail | `WebPalette.rail` | `#0E1B2C` |
| Brass accent | `WebPalette.brass` / `brassBright` | `#AE8126` / `#DBA94A` |
| Brass text on paper | `WebPalette.brassDeep` | `#8A6614` |

Brass is used sparingly (brand mark, selection tick, focus moments, rail footer CTA). Status washes (`success`, `danger`, `warning`) are harmonized to the paper surface.

### Typography (web)

| Role | Family | Use |
|------|--------|-----|
| Display | **Spectral** (serif) | Titles, brand wordmark, KPI numbers |
| UI | **Barlow** (sans) | Body, labels, chrome |
| Data | **IBM Plex Mono** | Money, bill nos, IDs |
| Devanagari | **Noto Sans Devanagari** | Fallback (unchanged) |

Helpers: `WebTypography.serif`, `mono`, `eyebrow`, `metricValue`.

### Shell & layout (web)

From `WebTokens.light`:

- Sidebar **264px** expanded / **72px** collapsed (ink rail; paper grain overlays **content only**, not the rail)
- Content max width **1320px**; top bar **60px**; page padding **28px**; gutters **16px**
- Card radius **10**; input radius **6**
- Compact breakpoint **768** (drawer + `NavigationBar`); desktop **1024**; wide **1280**

Atmosphere: subtle paper grain (`WebPaperGrain`), ledger-line auth brand panel, रू watermark on login/register.

### Components (web)

- **Stamp-style status chips** (shared `StatusChip` / `BillStatusChip`): border + color dot or icon + uppercase micro-label — not soft-fill pills.
- **Ledger tables** (`WebDataTable`): warm card chrome, mono pagination, warm hover/selected rows (`paperDeep` / navy wash).
- **KPI tiles** (`WebStatTile`): Spectral metrics, eyebrow labels, stamp trend badges, brass hover rule.
- **Form cards** (`WebFormCard`): navy icon medallion, serif title, section hairline rules.
- **Empty states:** brass medallion + serif message.
- **Sidebar footer CTAs:** local theme override makes `FilledButton` **brass** on the ink rail.
- **Buttons:** primary filled navy with hover deepen; standard height 40 / compact 36.

### Money on web

`MoneyText` switches to IBM Plex Mono when `kIsWeb`. Raw `Text(formatNpr(...))` does **not** — use `MoneyText` or `WebTypography.mono(...)`.

### Dark mode (v1)

BusinessSajilo v1 ships **light theme only** on mobile and web. `WebTheme.dark()` and Material dark schemes compile for future use but are not exposed in settings and must not be enabled in production builds until a dedicated dark-mode pass lands.

### Dark mode (web — legacy note)

Product web forces light (`WebTheme.light()`). `WebTheme.dark()` compiles but is not the shipped surface.

---

## Shared rules (both platforms)

- **Currency Formatting:** All NPR values use Nepali grouping via `formatNpr` (e.g. `रू 1,23,456.50`).
- **Bi-lingual Toggles:** Top-right utility bar on web; layouts must tolerate longer Nepali strings.
- **Primary brand navy** `#00236F` is shared across mobile and web.
- Offline design preview harness: `tool/design_preview/main.dart` (`flutter run -t tool/design_preview/main.dart -d chrome`).