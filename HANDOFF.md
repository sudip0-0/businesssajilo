# HANDOFF — Web UI Redesign (“Digital Ledger”)

**Date:** 2026-07-19  
**Scope:** Full visual redesign of the Flutter **web** experience for BusinessSajilo  
**Status:** Design system + shell + auth + kit + owner dashboard largely complete; feature-page polish, verification, and docs still open  

---

## 1. Goal

Replace the generic Inter / cool-grey / white-card admin look with a distinctive **“Digital Ledger” (डिजिटल खाता)** aesthetic:

| Pillar | Choice |
|--------|--------|
| Surfaces | Warm paper canvas (`#F7F4EC`), warm-white cards (`#FFFDF8`) |
| Authority | Deep ink-navy rail (`#0E1B2C`) + brand navy (`#00236F`) |
| Accent | Brass / saffron (`#AE8126` / `#DBA94A`) — used sparingly |
| Display type | **Spectral** (serif) — titles, brand, KPI numbers |
| UI type | **Barlow** (sans) — body, labels, chrome |
| Data type | **IBM Plex Mono** — money, bill nos, IDs |
| Devanagari | **Noto Sans Devanagari** fallback (unchanged) |
| Atmosphere | Paper grain overlay, ledger-line brand panel, रू watermark |
| Status | Stamp-style chips (border + dot/icon + uppercase micro-label) |

**Hard constraints (from `Agent.md`) preserved:**

- Mobile theme (`AppTheme` / `BsColors`) left as the mobile source of truth  
- Web-only palette lives in `lib/web/theme/web_palette.dart`  
- User-facing copy via ARB l10n (new keys added for sidebar tooltips)  
- Integration keys on sidebar / dashboard CTAs kept  
- No tax/VAT, no warehouse bill access, no client service-role usage  

---

## 2. What was completed

### 2.1 Fonts & assets

**New bundled OFL fonts** under `assets/fonts/`:

| Family | Files |
|--------|--------|
| Spectral | Regular, Medium, SemiBold, Bold, Italic + `OFL-Spectral.txt` |
| Barlow | Regular, Medium, SemiBold, Bold + `OFL-Barlow.txt` |
| IBM Plex Mono | Regular, Medium, SemiBold + `OFL-IBMPlexMono.txt` |

**`pubspec.yaml`** — all three families registered (Inter kept for mobile).

### 2.2 Web design system (cascade layer)

| File | Change |
|------|--------|
| `lib/web/theme/web_palette.dart` | **NEW** — paper / ink / rail / brass / status washes / tinted shadows / gradients |
| `lib/web/theme/web_tokens.dart` | Layout metrics (sidebar 264/72, content 1320, top bar 60, radii 10/6) + palette shadows |
| `lib/web/theme/web_typography.dart` | Barlow base + Spectral display + mono helpers (`serif`, `mono`, `eyebrow`, `metricValue`) |
| `lib/web/theme/web_theme.dart` | Full light overhaul (buttons w/ hover states, inputs, tables, chips, snackbar, tooltip, nav bar, segmented control); dark kept compiling |

### 2.3 Shell & atmosphere

| File | Change |
|------|--------|
| `lib/web/layout/web_sidebar.dart` | Ink-navy rail, brass brand mark + Spectral wordmark, brass selection tick, hover states, brass footer CTA theme override, staggered nav entrance |
| `lib/web/layout/web_top_bar.dart` | Warm card bar, brass notification badge, squircle avatar, l10n `openMenu` |
| `lib/web/layout/web_app_shell.dart` | Paper grain over content area only (not over dark rail) |
| `lib/web/layout/web_page_header.dart` | Spectral titles, brass-dot breadcrumbs |
| `lib/web/layout/web_bento_grid.dart` | Warm cards, tinted shadow, hover lift (`translateY(-2)`), refined stagger |
| `lib/web/ui/web_paper.dart` | **NEW** — `WebPaperGrain` + `LedgerLinesPainter` |

### 2.4 UI kit

| File | Change |
|------|--------|
| `lib/web/ui/web_stat_tile.dart` | Serif metrics, eyebrow labels, stamp trend badges, brass hover rule |
| `lib/web/ui/web_data_table.dart` | Ledger card chrome, mono pagination, phosphor caret page buttons, warm hover/selected rows |
| `lib/web/ui/web_empty_state.dart` | Brass medallion + serif message |
| `lib/web/ui/web_form_card.dart` | Navy icon medallion, serif title, section labels with hairline rules |
| `lib/web/ui/web_skeleton.dart` | Paper-tinted shimmer |
| `lib/web/ui/web_search_field.dart` | Unchanged API (inherits new `InputDecorationTheme`) |

### 2.5 Auth

| File | Change |
|------|--------|
| `lib/web/auth/web_auth_brand_panel.dart` | **NEW** — shared brand panel (gradient, ledger lines, brass mark, Spectral headline, feature rows, microline footer, रू watermark) |
| `lib/web/auth/web_login_page.dart` | Split layout using brand panel + warm paper form, refined error banner, full-width navy CTA |
| `lib/web/auth/web_register_page.dart` | Matched to login (brand panel + paper form + same error/CTA treatment) |

### 2.6 Shared core (web-aware / dual-platform)

| File | Change |
|------|--------|
| `lib/core/ui/status_chip.dart` | Stamp style (border + color dot + uppercase) |
| `lib/core/ui/bill_status_chip.dart` | Stamp style (border + icon + uppercase) |
| `lib/core/ui/money_text.dart` | **Web only:** IBM Plex Mono via `kIsWeb`; mobile unchanged |

### 2.7 Owner dashboard

`lib/web/features/dashboard/web_owner_dashboard_page.dart`:

- Switched hard `BsColors` usage to `WebPalette` / `WebTypography`  
- Mono bill nos + amounts in today’s transactions table  
- Brass-dot footer line for © / Made for Nepal  
- Activity row icons/colors aligned to palette  

### 2.8 Bootstrap / PWA

| File | Change |
|------|--------|
| `web/index.html` | Branded splash (ink gradient, “Bs” mark, wordmark, brass rule, scan bar); `flutter-first-frame` dismiss; font preloads for Spectral/Barlow/Plex Mono; richer meta/OG/`theme-color` |
| `web/manifest.json` | `background_color` / `theme_color` → ink `#0E1B2C`; description aligned |

### 2.9 l10n

New keys in `app_en.arb` + `app_ne.arb` (regenerated):

- `sidebarExpand`  
- `sidebarCollapse`  
- `openMenu`  

### 2.10 Design preview harness (dev tool)

`tool/design_preview/main.dart` — offline mock shell with:

- Dashboard (stat tiles, chart, activity, transactions)  
- Billing list (WebDataTable + stamp chips + pagination)  
- Forms (WebFormCard + empty state + skeleton)  

**Run:**

```bash
flutter run -t tool/design_preview/main.dart -d chrome
# or build:
flutter build web --release -t tool/design_preview/main.dart -o build/web_preview
```

Uses **hash routing** (`/#/dashboard`, `/#/billing`, `/#/forms`).

---

## 3. Visual verification already done

Screenshots were captured (local temp paths under `%TEMP%\opencode\`):

| Screen | Result |
|--------|--------|
| Login (real app build) | Ink brand panel + paper form + Spectral titles + रू watermark |
| Register (real app build) | Matched brand panel + form |
| Splash (standalone HTML of splash markup) | Ink gradient + brass mark + scan bar |
| Design preview — Dashboard | Ink rail, brass CTA, serif KPIs, chart, activity |
| Design preview — Billing | Ledger table, stamp chips, mono amounts, pagination |
| Design preview — Forms | Form card, section rules, empty state, skeleton |
| Design preview — Collapsed rail | 72px icon rail + brass + button |

**Not fully verified in browser yet:**

- Real authenticated interior routes (local Supabase was down; Docker unavailable)  
- Hover micro-interactions under automated canvas pointer events (logic is standard MouseRegion; not screenshot-proven)  
- Compact / mobile web shell (bottom nav + drawer) end-to-end  
- Nepali locale layout stress on redesigned pages  

---

## 4. Pre-existing dirty files (do not mix blindly)

These were **already modified before this redesign** (unrelated work). Treat as separate commits:

- `lib/core/invoicing/invoice_export_service.dart`  
- `lib/features/customers/add_customer_sheet.dart`  
- `lib/web/features/billing/web_bill_form_content.dart`  
- `lib/web/features/customers/web_customer_form_page.dart`  

Redesign did **not** intentionally restyle those files beyond whatever was already dirty.

---

## 5. Remaining work (prioritized)

### P0 — Must finish before merge

1. **`flutter analyze` + `flutter test` clean**  
   - Last full analyze on `lib` was clean of redesign errors mid-session; re-run after all final edits.  
   - Run unit + any web integration gates the repo expects (`flutter test`, optionally `npm run e2e:web` if Supabase is up).

2. **Update `Design.md`**  
   - Agent.md treats Design.md as source of truth.  
   - Document Digital Ledger: fonts, paper/ink/brass, rail, stamp chips, web vs mobile split.  
   - Keep mobile Inter + existing BsColors story unless product wants mobile to follow.

3. **Commit strategy**  
   - Prefer **one focused redesign commit** (fonts + web theme/shell/kit/auth/dashboard + index/manifest + l10n).  
   - Keep pre-existing dirty files in separate commit(s).  
   - Do **not** commit `.env.local`, `build/`, e2e screenshots, or secrets.

4. **Real-app smoke with backend**  
   - `supabase start` (Docker required) + seed / e2e owner user.  
   - `flutter run -d chrome` with dart-defines from `.env.local`.  
   - Walk owner routes: dashboard, inventory, billing list/form, customers, orders, reports, staff, settings.  
   - Spot-check sales / warehouse / customer shells.

### P1 — Feature pages still on old hard colors

Many list/detail pages still hardcode `BsColors.*` for borders/hovers/avatars. They **inherit** the new theme for scaffold/cards/buttons/tables, but local chrome is inconsistent.

**Suggested pass (replace with `WebPalette` / theme tokens where web-only):**

| Area | Files (non-exhaustive) |
|------|-------------------------|
| Inventory | `web_product_list_page.dart`, detail/form if needed |
| Customers | `web_customer_list_page.dart`, ledger page |
| Billing | `web_bill_list_page.dart`, form content (careful: already dirty) |
| Staff | `web_staff_list_page.dart` |
| Reports | `web_reports_hub_page.dart`, dues aging, sales, stock |
| Orders | list/detail/fulfillment/catalog |
| Settings / notifications | `web_settings_page.dart`, `web_notifications_page.dart` |
| Other dashboards | `web_sales_dashboard_page.dart`, `web_warehouse_dashboard_page.dart`, `web_customer_dashboard_page.dart` |

Pattern:

- Borders → `WebPalette.hairline` / `hairlineStrong`  
- Hover rows → `WebPalette.paperDeep`  
- Primary tints → `WebPalette.navy` / `navyWash`  
- Success/danger → `WebPalette.success` / `danger` (or keep `ColorScheme` extensions)  
- Prefer `Theme.of(context).colorScheme` where possible so dark mode stays viable  

### P2 — Polish & product quality

5. **Side panel title color** — `lib/core/ui/web_side_panel.dart` still uses `BsColors.textCharcoal` for the title. On web with `WebTheme.light()` surface, fine; optionally use `colorScheme.onSurface` for consistency.

6. **Compact web shell**  
   - Verify drawer (`inDrawer: true` ink sidebar) + `NavigationBar` at &lt;768px.  
   - NavigationBar theme was added in `WebTheme.light()`; validate selected/unselected labels in EN + NE.

7. **Hover / press states**  
   - Manually verify: bento/stat tile lift + brass rule, sidebar hover, table row hover, filled button hover deepen.  
   - Consider press `scale(0.98)` on primary CTAs if product wants more tactile feedback (optional).

8. **Nepali layout stress**  
   - Toggle NE on login, dashboard headers, table headers, long sidebar labels (`staffManagement`, etc.).  
   - Devanagari line-height / clipping on Spectral titles with Noto fallback (titles may mix faces).

9. **Chart theming**  
   - `BsSalesLineChart` still uses `BsColors` / core theme. Consider optional web-friendly colors (navy line already OK; grid/fill may still feel cool-grey).

10. **Dark mode (web)**  
    - Web forces light in `app.dart` today. `WebTheme.dark()` compiles but is not the product surface.  
    - If dark web is desired later: map paper→ink surfaces, brass accents on dark rail inverted, etc.

11. **Accessibility**  
    - Contrast: brass text on paper (`brassDeep`), rail text, stamp chips.  
    - Focus rings on inputs/buttons (theme focus colors set; keyboard tab through login + shell).  
    - Flutter web a11y tree for redesigned shell.

12. **Performance**  
    - Paper grain `CustomPaint` redraws on size change only (`shouldRepaint` opacity-based) — OK.  
    - Sidebar stagger `flutter_animate` on every rebuild of the list — if janky, animate only on first mount.  
    - Font payload: Spectral + Barlow + Plex Mono + Inter + Noto — web download size up. Consider subsetting or dropping Inter from **web** asset tree later if mobile packaging allows (Flutter currently ships all fonts for all platforms unless split carefully).

13. **Design preview harness hygiene**  
    - Keep as dev tool **or** document in README and `.gitignore` `build/web_preview`.  
    - Optional: wire real `WebAppShell` once provider overrides for auth/notifications are easy.  
    - Remove hardcoded English strings from harness if it ever ships (currently dev-only OK).

### P3 — Nice-to-haves / out of original scope

14. Mobile visual alignment with Digital Ledger (product decision — currently web-only by design).  
15. Custom brand illustration / real storefront mark instead of Phosphor storefront.  
16. Favicon refresh to match brass/ink mark.  
17. Storybook/widgetbook permanent gallery (harness is a lightweight substitute).  
18. Close remaining `BsColors` hardcodes in web feature files listed in §5 P1.  
19. E2E script updates if canvas click coordinates shifted after denser top bar / sidebar.  

---

## 6. How to continue (next agent / human)

### 6.1 Local verify (no backend)

```powershell
# Design system with mock data
flutter run -t tool/design_preview/main.dart -d chrome

# Auth chrome only (needs dart-defines; login form renders even if API down)
$env = @{}; Get-Content .env.local | ForEach-Object { $k,$v = $_ -split '=',2; $env[$k]=$v }
flutter run -d chrome `
  --dart-define=SUPABASE_URL=$($env['SUPABASE_URL']) `
  --dart-define=SUPABASE_ANON_KEY=$($env['SUPABASE_ANON_KEY'])
```

### 6.2 Full verify (with backend)

```powershell
# Requires Docker Desktop running
supabase start
# seed / e2e user per repo docs (e2e-owner@test.com / password123 per scripts/e2e_web.mjs)
flutter build web --release --dart-define=...
# serve build/web and run npm run e2e:web
```

### 6.3 Suggested next implementation order

1. Re-run analyze + test; fix any fallout.  
2. Update `Design.md`.  
3. Sweep P1 feature pages for `BsColors` → `WebPalette` (start with list pages: products, customers, bills, staff).  
4. Smoke authenticated owner flow.  
5. Compact viewport + NE locale pass.  
6. Commit redesign separately from unrelated dirty files.  

---

## 7. Architecture notes for implementers

### 7.1 Where to put web-only styles

- **Colors / shadows / gradients:** `WebPalette`  
- **Spacing / radii / breakpoints:** `WebTokens`  
- **Type:** `WebTypography`  
- **Do not** put warm paper tokens into `BsColors` unless product wants mobile to change.

### 7.2 Money on web

`MoneyText` auto-switches to IBM Plex Mono when `kIsWeb`.  
Raw `Text(formatNpr(...))` in tables **does not** — use `MoneyText` or `WebTypography.mono(...)` (as on owner dashboard transactions).

### 7.3 Sidebar footer CTAs

`WebSidebar` wraps `footer` in a local `Theme` so `FilledButton` becomes **brass** on the ink rail. Any shell footer CTA inherits this automatically.

### 7.4 Integration keys (do not remove)

- `IntegrationKeys.sidebarNav(path)`  
- `IntegrationKeys.sidebarCreateBill`  
- `IntegrationKeys.dashboardAddProduct` / `dashboardNewBill`  

E2E canvas clicks may need coordinate retuning if chrome height/width shifted.

### 7.5 Phosphor icons

Prefer icons that exist in the bundled Phosphor set.  
`PhosphorIconsRegular.caretLineLeft` rendered as a missing glyph — replaced with `caretLeft`.

---

## 8. File inventory (redesign-related)

### New

```
assets/fonts/Spectral-*.ttf
assets/fonts/Barlow-*.ttf
assets/fonts/IBMPlexMono-*.ttf
assets/fonts/OFL-Spectral.txt
assets/fonts/OFL-Barlow.txt
assets/fonts/OFL-IBMPlexMono.txt
lib/web/theme/web_palette.dart
lib/web/auth/web_auth_brand_panel.dart
lib/web/ui/web_paper.dart
tool/design_preview/main.dart
HANDOFF.md  (this file)
```

### Modified (redesign)

```
pubspec.yaml
web/index.html
web/manifest.json
lib/core/l10n/app_en.arb
lib/core/l10n/app_ne.arb
lib/core/l10n/app_localizations*.dart
lib/core/ui/status_chip.dart
lib/core/ui/bill_status_chip.dart
lib/core/ui/money_text.dart
lib/web/theme/web_theme.dart
lib/web/theme/web_tokens.dart
lib/web/theme/web_typography.dart
lib/web/layout/web_sidebar.dart
lib/web/layout/web_top_bar.dart
lib/web/layout/web_app_shell.dart
lib/web/layout/web_page_header.dart
lib/web/layout/web_bento_grid.dart
lib/web/ui/web_stat_tile.dart
lib/web/ui/web_data_table.dart
lib/web/ui/web_empty_state.dart
lib/web/ui/web_form_card.dart
lib/web/ui/web_skeleton.dart
lib/web/auth/web_login_page.dart
lib/web/auth/web_register_page.dart
lib/web/features/dashboard/web_owner_dashboard_page.dart
```

### Intentionally not rewritten (still need P1 polish)

Most files under `lib/web/features/**` except owner dashboard — they inherit the kit but may still hardcode `BsColors`.

---

## 9. Known risks / gotchas

| Risk | Mitigation |
|------|------------|
| Web font payload larger (Inter + new families) | Accept for v1; later platform-split fonts or subset |
| Spectral titles + Devanagari fallback may look mixed | Test NE; if jarring, use Barlow for bilingual titles |
| Stamp chips uppercase may lengthen NE labels | Check overflow on chips in lists |
| Local Supabase/Docker required for real data screenshots | Use `tool/design_preview` until Docker is available |
| E2E canvas coordinates fragile | Prefer key-based / URL navigation in e2e (already has fallbacks) |
| User had uncommitted non-redesign diffs | Keep commits separate |
| `app_ne.arb` was already missing some EN keys | Pre-existing gap; only new sidebar keys were added to both |

---

## 10. Definition of done (for this initiative)

- [x] Distinctive web design system (palette, type, tokens, theme)  
- [x] Ink rail shell + paper content + grain  
- [x] Auth login/register brand experience  
- [x] Shared kit upgraded (tiles, tables, empty, forms, skeleton)  
- [x] Stamp chips + web mono money  
- [x] Owner dashboard composition polish  
- [x] Branded web splash + manifest  
- [x] Offline design preview harness  
- [x] Analyze + tests green on final tree  
- [x] `Design.md` updated  
- [x] P1 feature-page color sweep  
- [x] Authenticated owner smoke on real backend (`npm run e2e:web` — 38/41; canvas soft-fails only)  
- [x] Compact shell themed + NE locale toggle verified in e2e  
- [ ] Clean, focused git commit(s)  

---

## 11. One-line summary for the next person

**The web app’s design system and chrome are redesigned as a warm “Digital Ledger” (Spectral + Barlow + Plex Mono, ink rail, brass accents); finish by greening tests, updating Design.md, sweeping remaining feature pages off hard `BsColors`, and smoke-testing authenticated routes once Supabase is available.**
