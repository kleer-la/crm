## Context

The CRM is a Rails 8 app using Tailwind CSS (v4 via `@import "tailwindcss"`) with Hotwire. The current design uses `bg-gray-800` for the sidebar, `blue-600` as the universal accent, flat gray status badges, and plain `<h1>` page headers with no visual hierarchy. All views are desktop-first with basic responsiveness already added (from the `polish` change).

This design document covers the UI modernization: a cohesive visual language applied across all screens — starting with the Customers index as the pilot, then standardized across all modules.

## Goals / Non-Goals

**Goals:**
- Define a consistent design token set (colors, spacing, corner radius) implemented with Tailwind utilities only
- Establish shared partials for the repeating UI patterns: page header, status badge, filter bar, empty state, flash toast
- Update the sidebar to `slate-700` with an indigo active indicator — lighter, easier on the eyes
- Introduce semantic, color-coded status badges for Prospect and Customer statuses
- Modernize index tables: company initials avatar chip, tighter rows, stronger hover state
- Polish page headers: subtitle line, icon-style secondary buttons (`outline`), solid primary CTA
- Slim the filter bar: remove the card shadow, use a borderless row with condensed inputs
- Improved empty states: centered icon + message + CTA
- Dismissible flash toasts with left color bar + icon + close button

**Non-Goals:**
- Dark mode
- Custom CSS (no new `.css` files — Tailwind utilities only)
- Accessibility audit (separate effort)
- Any behavioral/data changes — purely visual layer
- Animations beyond Tailwind's `transition` utilities

## Decisions

### 1. Design tokens via Tailwind utilities — no CSS variables

**Decision:** Use Tailwind color classes directly (`slate-700`, `indigo-600`, `indigo-50`) as the token layer. No CSS custom properties or extra config.

**Rationale:** The project already uses `@import "tailwindcss"` with zero custom config. Introducing CSS variables would create a second system. If the palette ever needs to change project-wide, a grep-and-replace of the core classes is sufficient at this team size.

**Alternative considered:** Define a `tailwind.config.js` with custom semantic color names (e.g., `brand-primary`). Rejected because it adds build complexity without benefit for a 6-15 person internal tool.

---

### 2. Design token reference (used consistently throughout all views)

| Token | Tailwind class | Used for |
|---|---|---|
| Sidebar bg | `bg-slate-700` | Sidebar background |
| Sidebar active | `bg-indigo-600` pill | Active nav item |
| Sidebar text | `text-slate-200` | Nav item text |
| Sidebar hover | `hover:bg-slate-600` | Nav item hover |
| Brand bar | `bg-slate-800` | Logo/brand header of sidebar |
| Page bg | `bg-slate-50` | `<html>` background |
| Card bg | `bg-white` | Cards, panels |
| Card border | `ring-1 ring-slate-200` | Replace `shadow` with ring |
| Primary button | `bg-slate-800 hover:bg-slate-700 text-white` | Main CTAs |
| Secondary button | `bg-white border border-slate-300 text-slate-700 hover:bg-slate-50` | Edit, Cancel |
| Danger button | `bg-red-600 hover:bg-red-700 text-white` | Destructive actions |
| Table header | `bg-slate-50 text-slate-500 uppercase text-xs` | `<thead>` |
| Table row hover | `hover:bg-indigo-50` | Row highlight |
| Link color | `text-indigo-600 hover:text-indigo-900` | All links |
| Input field | `border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 rounded-lg shadow-sm placeholder:text-slate-400` | Text inputs, selects, textareas |
| Input focus | `focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/20` | Focus state for all inputs |

---

### 3. Color-coded status badges (semantic colors)

**Decision:** Each status value gets a distinct color. Implemented in `ApplicationHelper#status_badge`.

| Status | Background | Text | Meaning |
|---|---|---|---|
| `new` | `bg-sky-100` | `text-sky-700` | Fresh prospect |
| `qualified` | `bg-green-100` | `text-green-700` | Engaged prospect |
| `disqualified` | `bg-red-100` | `text-red-700` | Dead end |
| `converted` | `bg-violet-100` | `text-violet-700` | Became customer |
| `active` | `bg-green-100` | `text-green-700` | Active customer |
| `inactive` | `bg-slate-100` | `text-slate-600` | Lapsed customer |
| `won` (proposal) | `bg-green-100` | `text-green-700` | Won deal |
| `lost` (proposal) | `bg-red-100` | `text-red-700` | Lost deal |
| `draft` (proposal) | `bg-slate-100` | `text-slate-600` | Unsubmitted |
| `sent` (proposal) | `bg-sky-100` | `text-sky-700` | Under review |
| `open` (task) | `bg-amber-100` | `text-amber-700` | Pending task |
| `completed` (task) | `bg-green-100` | `text-green-700` | Done task |
| `cancelled` (task) | `bg-slate-100` | `text-slate-600` | Cancelled task |
| Admin (role) | `bg-violet-100` | `text-violet-700` | Admin user |
| Consultant (role) | `bg-indigo-100` | `text-indigo-700` | Consultant user |
| Pending (role) | `bg-amber-100` | `text-amber-700` | Awaiting approval |

The helper accepts the status/role as a string and maps it. Unknown values fall back to a neutral slate badge.

---

### 4. Shared `_page_header` partial

**Decision:** Extract the repeating `sm:flex sm:items-center sm:justify-between` header block into `app/views/shared/_page_header.html.erb` with a content_for-style API.

```erb
<%= render "shared/page_header", title: "Customers" do |header| %>
  <%= header.with_action { link_to "New customer", ... } %>
<% end %>
```

**Rationale:** Every index and show page has the same header pattern. A partial eliminates drift and makes future changes (e.g., adding breadcrumbs) one-file changes.

**Alternative:** Keep header inline in each view. Rejected — already causing inconsistency between screens.

---

### 5. Filter bar: borderless, lower-weight

**Decision:** Remove the `shadow rounded-lg` card wrapping the filter bar. Replace with a simple `border-b border-slate-200 pb-4 mb-6` divider row.

**Rationale:** The card shadow makes the filter feel heavy. A subtle divider separates it from the table without visual bulk. The screenshot shared by the user shows this exact friction point.

---

### 6. Table rows: company initials chip

**Decision:** For index tables that list companies (Prospects, Customers), prepend a small circle avatar chip showing the first 2 letters of `company_name` in `bg-indigo-100 text-indigo-700`. No image loading, no external dependencies.

**Rationale:** Pure CSS, zero backend changes, adds visual anchoring to each row that makes scanning faster.

---

### 7. Flash: dismissible toast with color-bar

**Decision:** Restyle `_flash.html.erb` to a toast pattern: left 4px color bar, icon (checkmark for notice, exclamation for alert), message text, and an ×  close button. The existing `flash` Stimulus controller (or a minimal new one) handles dismiss.

**Alternative:** Keep current flat border approach. Rejected — it looks dated and doesn't acknowledge success visually.

---

### 8. Primary buttons: slate-800, not indigo

**Decision:** Primary action buttons use `bg-slate-800 hover:bg-slate-700` (dark neutral) rather than `bg-indigo-600`.

**Rationale:** `indigo-600` reads as "default web blue" and doesn't feel distinctive. `slate-800` matches the sidebar palette, gives the UI a composed, professional look (similar to Linear/Vercel), and lets semantic colors (badges, status indicators) carry meaning rather than the chrome.

**Scope:** All primary buttons: page CTAs (`New customer`, `New Prospect`, etc.), form submit buttons, and filter submit buttons. The active nav pill in the sidebar keeps `bg-indigo-600` as an accent — that contrast against `slate-700` is intentional.

---

### 9. Input fields: always include `border`, `bg-white`, and explicit padding

**Decision:** Every `<input>`, `<select>`, and `<textarea>` must include all of: `border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 rounded-lg shadow-sm`.

**Rationale:** Tailwind v4's preflight reset strips all browser default styling from form elements — border, background, and padding are all removed. Specifying only `border-slate-300` (color) without `border` (width) produces an invisible hairline. Adding `bg-white` prevents inputs from inheriting the `bg-slate-50` page background. Padding must be explicit since the browser default is gone.

**Focus state:** `focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/20` — the `focus:ring-indigo-500/20` soft glow replaces the harsh solid ring from `focus:ring-indigo-500`.

**Where enforced:** `_form_field.html.erb` (all 7 types), and any inline filter inputs in index views.

---

### 10. Pilot on Customers, then standardize

**Decision:** Apply all changes to the Customers module first (index + show + form), verify visually, then apply the same patterns to Prospects, Proposals, Tasks, Pipeline, Dashboard, Admin, Search, and Sessions.

**Rationale:** Reduces risk. If a pattern needs adjustment, we catch it on one screen before propagating to all 12+.

## Risks / Trade-offs

- **Tailwind v4 purge behavior** → All classes must appear as complete strings in ERB/helper files; no string interpolation for class composition. Mitigated by always writing full class names in helpers and partials.
- **`role_badge` vs `status_badge`** → Currently two separate helpers with overlapping logic. Will unify into one `badge` helper with a mapping table. Low risk.
- **Partial API design** → If the `_page_header` partial API feels awkward, it can be inlined again without touching functionality. Low risk.
- **Visual regression** → No automated screenshot tests. Mitigated by the pilot-first approach and manual review before standardizing.
