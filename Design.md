# BusinessSajilo — Design Guidelines

## 1. Design Principles

1. **Sajilo first** — every core action (make a bill, check dues, place order) reachable in ≤2 taps from the role's home screen. Users may be non-technical shopkeepers.
2. **Role-shaped UI** — each role gets a purpose-built home, not a generic menu with disabled items. Hide what a role can't do; don't grey it out.
3. **Numbers are the hero** — dues, stock, totals rendered large and unambiguous; NPR formatted Nepali-style (रू 1,23,456.00).
4. **Offline honesty** — always show sync state; never let a user wonder if a bill "went through".
5. **Bilingual by design** — every label has EN + NP from day one; layouts must tolerate longer Devanagari strings.

## 2. Brand & Visual Language

- **Personality:** trustworthy, practical, local. A digital khata, not a Silicon Valley dashboard.
- **Palette:**
  - Primary: deep teal `#0F6E5F` (trust, commerce)
  - Accent: marigold `#F2A33C` (CTAs, highlights — familiar/festive in Nepal)
  - Success `#2E7D32`, Danger/dues `#C62828`, Info `#1565C0`
  - Surfaces: warm off-white `#FAF8F5`, dark text `#1D2421`
- **Typography:** Inter (Latin) + Noto Sans Devanagari (Nepali), single type scale shared across scripts. Numerals always Latin digits for clarity on bills.
- **Shape:** 12px radius cards, 8pt spacing grid, generous touch targets (min 48dp) — used outdoors, on cheap devices, sometimes with dusty fingers.
- Material 3 as the base system, themed with the palette above.

## 3. Role Home Screens

| Role | Home contents |
|---|---|
| Owner | Today's sales, total dues, low-stock count, pending orders; quick actions: New Bill, Add Stock, Add Customer |
| Sales | Pending orders/quotes queue, quick New Bill, recent payments, dues hot-list |
| Warehouse | Confirmed orders to pack/dispatch, low-stock list, quick Stock-In |
| Customer | Product catalog (no prices), My Orders with status chips, My Dues, order chat |

## 4. Key Screen Patterns

- **Billing screen:** product search with big result rows (image, name, stock badge), qty steppers, sticky running total bar, one-tap save → payment sheet (Paid / Partial / Due).
- **Order detail (staff):** timeline of states, quote builder inline, chat thread tab.
- **Quote (customer):** clear per-item pricing table, big Accept / Reject buttons, comment box on reject.
- **Ledger:** statement-style list (debit red / credit green) with running balance, BS+AD dates, filter chips.
- **Stock-in/adjust:** reason required for adjustments; movements list is read-only history.
- **Status chips:** Placed (blue) → Quoted (amber) → Accepted (teal) → Packed/Dispatched (purple) → Billed (green) / Rejected, Cancelled (grey/red).

## 5. Offline & Sync UX

- Persistent subtle indicator: green dot "Synced", amber "X pending", grey "Offline".
- Locally-created bills show provisional number (`D2-17`) with a small clock icon until final number assigned.
- Sync failures surface in a "Pending items" screen with retry; never silent loss.

## 6. Responsive Behavior

- **Phone (default):** bottom navigation (4–5 role-specific tabs), single column.
- **Tablet/Web:** navigation rail + two-pane layouts (list ⇄ detail); owner dashboard becomes a grid of report cards with charts.
- Web targets desktop browsers for owners doing back-office work; data tables get sortable columns + pagination there.

## 7. Localization & Formatting

- Language toggle in settings + onboarding; instant switch, persisted per user.
- Dates: primary BS with AD secondary on bills/ledger (`२०८३ असार २८ · 12 Jul 2026`).
- All strings via Flutter ARB l10n; no hardcoded text.

## 8. Accessibility & Quality Bar

- Contrast AA minimum; dues/success states never rely on color alone (icons + text).
- Scales gracefully to 1.3× system font.
- Empty states with one-line guidance + primary action (e.g. "No products yet — Add your first product").
- Skeleton loaders for lists; optimistic UI for offline writes.
- Error copy in plain language, both languages, with a recovery action.

## 9. Components (Flutter)

Shared design-system widgets in `core/ui/`: `BsAppBar`, `BsCard`, `MoneyText`, `StatusChip`, `QtyStepper`, `SyncBadge`, `LedgerRow`, `EmptyState`, `BsDatePicker` (BS/AD), `SearchField`. All themed via a single `ThemeExtension` so brand changes propagate.
