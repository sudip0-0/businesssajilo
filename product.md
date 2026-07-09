# BusinessSajilo — Product Requirements Document (PRD)

## 1. Vision

BusinessSajilo is a multi-tenant SaaS platform for small-to-medium dealers and distributors in Nepal who sell to retailers. It replaces copy books, Viber orders, and Excel sheets with one app covering inventory, ordering, quoting, billing (non-VAT), credit (udharo) tracking, and customer communication.

**Tagline:** "Tapaiko business, sajilo tarika le."

## 2. Target Users

| Persona | Description | Primary device |
|---|---|---|
| Business Owner | Dealer/distributor owner; wants visibility & control | Android / Web |
| Sales Person | Handles orders, quotes, billing, payment collection | Android (often in field) |
| Warehouse Manager | Manages godown stock, fulfillment | Android / Web |
| Customer (Retailer) | Shop owner buying from the dealer | Android |

## 3. Tenancy & Accounts

- Multi-tenant SaaS: businesses self-register; all data isolated per business (Supabase RLS on `business_id`).
- One user account can belong to one business with one role (v1 simplification).
- **Owner** registers the business and invites/creates all other users.
- **Customer credentials are created by the Owner** (phone number + initial password / OTP). Customers cannot self-register; they are always attached to a specific business.

## 4. Roles & Permissions Matrix

| Capability | Owner | Sales | Warehouse | Customer |
|---|:-:|:-:|:-:|:-:|
| Manage business settings, staff users | ✅ | ❌ | ❌ | ❌ |
| Create customer credentials | ✅ | ❌ | ❌ | ❌ |
| Add/edit customers (profile data) | ✅ | ❌ | ❌ | own profile |
| Create/edit products & categories | ✅ | ❌ | ❌ | ❌ |
| Stock-in, adjustments, stock counts | ✅ | ❌ | ✅ | ❌ |
| View stock levels | ✅ | ✅ | ✅ | ❌ |
| Create bills/invoices | ✅ | ✅ | ❌ | ❌ |
| Respond to orders / send quotes | ✅ | ✅ | ❌ | ❌ |
| Record payments | ✅ | ✅ | ❌ | ❌ |
| View customer ledger / dues | ✅ | ✅ | ❌ | own ledger |
| Place orders, accept/reject quotes | ❌ | ❌ | ❌ | ✅ |
| Order-thread chat | ✅ | ✅ | ❌ | ✅ |
| Reports & dashboard | ✅ | limited | ❌ | ❌ |

Hard rule: **Warehouse Manager can never create or view bills.** Enforced at the database (RLS) level, not just UI.

## 5. Core Flows

### 5.1 Order → Quote → Bill (the spine of the app)

1. Customer browses catalog (products, **no prices shown** — pricing is negotiated per quote).
2. Customer places an order (items + quantities + note).
3. Sales/Owner receives notification, reviews, and sends a **Quote** (per-item rates, discounts, total).
4. Customer **accepts** or **rejects** (with comment) the quote. Counter-discussion happens in the order's chat thread.
5. On acceptance, order moves to **Confirmed**. Warehouse sees it for fulfillment (packed → dispatched).
6. Sales/Owner generates the **Bill** from the confirmed order. Payment recorded as full, partial (credit), or due.

Order states: `draft → placed → quoted → accepted | rejected → confirmed → packed → dispatched → billed → closed | cancelled`

### 5.2 Billing (non-VAT)

- Itemized invoice: items, qty, rate, line discount, bill discount, grand total. No VAT/tax fields in v1.
- Walk-in billing also supported (bill without prior order, for counter sales).
- Bill numbering: per-business sequential (`BS-0001`), works offline (device prefix to avoid collisions, reconciled on sync).
- Invoice PDF/image generation & share (Viber/WhatsApp) — **shipped**.
- Sales returns via credit notes (per-business CN numbering, optional restock, ledger integration) — **shipped**.

### 5.3 Credit / Udharo & Ledger

- Every customer has a running ledger: bills (debit), payments (credit).
- **Account-level** payment recording in v1 (optional `bill_id` exists in schema; UI does not allocate to a specific bill). Bill-level / oldest-first allocation is v1.2.
- Payment methods recorded manually: cash, cheque, eSewa/Khalti/bank ref (no gateway integration in v1).
- Outstanding dues visible to staff and to the customer in their own app.
- Dues aging report for the owner.

### 5.4 Inventory (v1 scope)

- Products: name (EN/NP), SKU, category, unit, cost price, selling reference price, image, low-stock threshold.
- Stock-in (purchases simplified as stock-in entries), manual adjustments with reason, automatic deduction on dispatch.
- Low-stock alerts via push.
- Out of scope v1: multi-warehouse, batches/expiry, unit conversions (carton↔piece) — see roadmap.

### 5.5 Messaging

- Chat threads **tied to orders/quotes only** (no general chat). Participants: customer + staff with sales rights.
- Supports text + image attachments. Realtime via Supabase Realtime; push notification on new message.

### 5.6 Reports & Dashboard (Owner)

- Sales summary: daily / weekly / monthly, top products, top customers.
- Outstanding dues with aging buckets (0–30 / 31–60 / 60+ days).
- Stock valuation (qty × cost) and low-stock list.
- CSV export & share for all reports — **shipped**.

## 6. Localization

- UI in English and Nepali (user-switchable).
- Dates shown in both BS (Bikram Sambat) and AD where relevant (bills, ledgers).
- Currency: NPR only, formatted Nepali-style (e.g. रू 1,23,456).

## 7. Offline Strategy

- **Staff apps (mobile): offline-first** for billing, payment recording, and stock operations. Local SQLite (Drift) with a sync queue; conflict policy = last-write-wins per field with audit log, stock movements are append-only events so they merge safely.
- **Customer app: online-only** — catalog requires connectivity (no Drift cache in v1); placing orders, quotes, and chat also require connectivity.
- **Web: online-only.**

## 8. Notifications

Push (FCM) for: order placed (staff), quote received / quote response (customer/staff), order status changes, new chat message, low stock (owner/warehouse), payment recorded (customer). In-app notification center mirrors all pushes.

## 9. Platforms

Flutter single codebase → Android, iOS, Web — shipped together. Responsive layouts: phone-first for staff/customer, desktop-grade layout on web for owner dashboards.

## 10. Monetization

Free during launch. Schema includes `businesses.subscription_plan` so feature-gating/billing can be added later without remodeling; **no subscription UI or gating is implemented in v1**.

## 11. Non-Goals (v1)

- VAT/IRD-compliant billing, CBMS integration
- Payment gateway integration (eSewa/Khalti checkout)
- Multi-warehouse, batch/expiry, unit conversion
- Purchase orders to suppliers, supplier ledger
- Multi-business per user, accounting (P&L, balance sheet)
- SMS notifications

## 12. Roadmap

Already shipped from the original v1.1 scope: PDF/image invoices, sales returns (credit notes), report CSV export.

1. **Launch hardening (pre-release)** — password reset, phone-number login, account deletion (store compliance), reorder from past order, shareable customer statement shipped in app; registration captcha / prod Auth hardening remain dashboard ops (see `docs/SECURITY.md`). See tasks.md Phase 11.
2. **v1.2** — Bill-level payment allocation, quote expiry + stale-order nudges, dues reminders (push), last-quoted-rate memory; thermal print only if pilot users ask.
3. **v1.3** — Price tiers per customer, supplier purchases + supplier ledger, multi-warehouse, unit conversions, batch/expiry.
4. **v2** — Payment gateways, SMS reminders (Sparrow SMS), subscriptions/feature gating, sales-person performance & route planning, VAT billing mode.

## 13. Success Metrics

- A business can go from signup → first bill in under 15 minutes.
- ≥70% of orders flowing through quote flow (vs. phone calls) for active businesses after 1 month.
- Offline bill creation success rate ≥99% (no data loss on sync).
