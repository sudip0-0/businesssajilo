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

The design style follows a **Corporate / Modern** aesthetic, prioritizing clarity and utility over decorative elements. It utilizes a structured grid, subtle elevation to denote information hierarchy, and a clear functional color language that resonates with financial and operational workflows. The UI must feel grounded and institutional yet accessible to users who may be transitioning from paper-based systems to digital management.

## Colors

This design system uses a logic-driven color palette to facilitate quick decision-making:

- **Primary (Navy Blue):** Used for primary actions, branding, and navigation. It establishes authority and stability.
- **Secondary (Vibrant Green):** Reserved for "Success" states, "Paid" statuses, and positive growth indicators like "Add New" or "Income."
- **Accent (Amber):** Used exclusively for "Warning" states, "Pending" payments, and items requiring attention.
- **Neutrals:** A range of cool greys ensures a "clean" feel. The background is a crisp `#F9FAFB` to reduce eye strain during long working hours.

Text utilizes Deep Charcoal (`#111827`) for maximum contrast against white backgrounds, ensuring high legibility for financial data.

## Typography

The design system uses **Inter** for its exceptional legibility and support for both Latin and Devanagari scripts. 

- **Bi-lingual Balance:** Ensure the line-height is generous enough (minimum 1.4x) to prevent Devanagari vowel signs (matras) from clipping or overlapping between lines.
- **Numerical Clarity:** Use tabular lining for figures in tables and invoices to ensure that currency values align vertically for easy scanning.
- **Hierarchy:** Headlines use tighter tracking and heavier weights to stand out, while labels use all-caps with subtle tracking (0.05em) for category identification.

## Layout & Spacing

The layout utilizes a **Fixed Grid** on desktop (1280px max width) and a **Fluid Grid** on mobile. 

- **The 8pt Rhythm:** All padding, margins, and component heights must be multiples of 4px/8px to maintain a rhythmic vertical flow.
- **Sidebar:** On desktop, the sidebar is a fixed 260px (64px when collapsed). On mobile, it transitions to a bottom navigation bar or a full-screen overlay.
- **Content Area:** Main content follows a 12-column grid on desktop with 16px gutters. Dashboard metrics should be grouped in 3 or 4 columns, while data tables should span the full width.
- **Data Density:** Use "Medium" density for general workflows and "Compact" density (8px vertical padding) for data-heavy tables to maximize information visibility without scrolling.

## Elevation & Depth

Visual hierarchy is established through **Tonal Layers** and **Ambient Shadows**.

1.  **Level 0 (Background):** `#F9FAFB` – The base canvas.
2.  **Level 1 (Cards/Sidebar):** White surface with a `1px` border of `#E5E7EB`.
3.  **Level 2 (Active States/Metrics):** A soft, diffused shadow (0px 4px 6px -1px rgba(0,0,0,0.1)) to lift key performance indicators (KPIs) above the base layer.
4.  **Level 3 (Modals/Dropdowns):** Pronounced shadows with higher blur (0px 10px 15px -3px rgba(0,0,0,0.1)) to indicate temporary interaction layers that require focus.

Avoid heavy dark shadows; depth should feel like light catching the edge of a physical paper document.

## Shapes

The shape language is **Soft**. Standard UI elements like input fields, buttons, and small cards use a `0.25rem` (4px) corner radius. This maintains a professional "business" feel while appearing more modern than sharp edges.

Larger container elements like dashboard sections and main cards may use `rounded-lg` (0.5rem) to create a softer grouping effect. Status badges and tags use a fully rounded "pill" shape to distinguish them from interactive buttons.

## Components

- **Buttons:** Primary buttons are Solid Navy Blue with white text. Success actions ("Add", "Confirm") use Green. Buttons have a height of 40px for standard and 32px for compact views.
- **Status Badges:** Use a "soft-fill" approach: a light background version of the state color (e.g., Light Green background for "Paid") with dark text in the same hue.
- **Input Fields:** 1px neutral borders that turn Primary Blue on focus. Labels are always visible above the field in `label-md` style.
- **Tables:** Row hover states use a light grey tint (`#F3F4F6`). Currency columns (NPR) are right-aligned. The "Status" column is always visible.
- **Currency Formatting:** All NPR values should use the format `Rs. XX,XXX.XX`. 
- **Bi-lingual Toggles:** Positioned in the top-right utility bar. Toggling language should not shift the layout; ensure components can handle the slightly longer character counts often found in Nepali translations.
- **Cards:** Metric cards feature a large `display-md` value, a `label-sm` title, and a small trend indicator (up/down arrow) in green or red.