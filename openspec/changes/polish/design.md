## Context

The CRM has a sidebar + top bar layout built with Tailwind CSS. All CRUD modules (Prospects, Customers, Proposals, Tasks), Pipeline, Dashboard, and Search are implemented. The layout has basic structure but hasn't been systematically tested for mobile/tablet breakpoints. Flash messages and form errors exist but styling varies across modules.

## Goals / Non-Goals

**Goals:**
- Ensure all views work well on mobile (≥320px), tablet (≥768px), and desktop (≥1024px)
- Sidebar collapses to a hamburger menu on mobile
- Tables scroll horizontally on small screens
- Forms stack fields vertically on mobile
- Flash messages have consistent, visually distinct styling (success=green, error=red, notice=blue)
- Form errors show both a summary block and inline per-field messages

**Non-Goals:**
- Redesign or visual overhaul — just responsive fixes and consistency
- Dark mode
- Accessibility audit (separate effort)
- Animation or transitions

## Decisions

### 1. Tailwind breakpoints only — no custom CSS

**Decision:** Use Tailwind's responsive prefixes (sm:, md:, lg:) for all layout adjustments. No custom media queries or CSS files.

**Rationale:** The project already uses Tailwind exclusively. Custom CSS would introduce a second styling system. Tailwind's utility-first approach is sufficient for responsive layout fixes.

### 2. Shared flash message partial in application layout

**Decision:** Create a `_flash.html.erb` partial rendered in the application layout. Style with Tailwind (green for success/notice, red for alert/error). Auto-dismiss after 5 seconds via Stimulus controller.

**Rationale:** Centralizing flash display ensures every controller gets consistent feedback styling without per-view changes.

### 3. Form error display via shared partial

**Decision:** Create a `_form_errors.html.erb` partial that renders a summary of all errors at the top of a form, plus add inline error messages below each field in the existing form partials.

**Rationale:** Users need both a summary (to know something failed) and inline markers (to find which fields to fix). This is a standard Rails form pattern.

## Risks / Trade-offs

- **Auditing all views is manual work** → Systematic pass through each module's index/show/edit/new views. No automated responsive testing available.
- **Table horizontal scroll may hide columns** → Acceptable trade-off for mobile; users can scroll to see all data.
