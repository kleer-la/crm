# UI Design System

## Requirement: Color-coded status badges
The system SHALL display status badges with semantic colors that visually distinguish each status value at a glance. The `status_badge` helper SHALL map known status strings to specific Tailwind color combinations. Unknown statuses SHALL fall back to a neutral slate badge.

### Scenario: Prospect new status badge
- **WHEN** a prospect has status `new`
- **THEN** the badge SHALL render with sky-blue background and text (`bg-sky-100 text-sky-700`)

### Scenario: Prospect qualified status badge
- **WHEN** a prospect has status `qualified`
- **THEN** the badge SHALL render with green background and text (`bg-green-100 text-green-700`)

### Scenario: Prospect disqualified status badge
- **WHEN** a prospect has status `disqualified`
- **THEN** the badge SHALL render with red background and text (`bg-red-100 text-red-700`)

### Scenario: Prospect converted status badge
- **WHEN** a prospect has status `converted`
- **THEN** the badge SHALL render with violet background and text (`bg-violet-100 text-violet-700`)

### Scenario: Customer active status badge
- **WHEN** a customer has status `active`
- **THEN** the badge SHALL render with green background and text (`bg-green-100 text-green-700`)

### Scenario: Customer inactive status badge
- **WHEN** a customer has status `inactive`
- **THEN** the badge SHALL render with slate background and text (`bg-slate-100 text-slate-600`)

### Scenario: Proposal won badge
- **WHEN** a proposal has status `won`
- **THEN** the badge SHALL render with green background and text (`bg-green-100 text-green-700`)

### Scenario: Proposal lost badge
- **WHEN** a proposal has status `lost`
- **THEN** the badge SHALL render with red background and text (`bg-red-100 text-red-700`)

### Scenario: Proposal draft badge
- **WHEN** a proposal has status `draft`
- **THEN** the badge SHALL render with slate background and text (`bg-slate-100 text-slate-600`)

### Scenario: Proposal sent badge
- **WHEN** a proposal has status `sent`
- **THEN** the badge SHALL render with sky-blue background and text (`bg-sky-100 text-sky-700`)

### Scenario: Unknown status fallback
- **WHEN** `status_badge` is called with an unrecognized status
- **THEN** the badge SHALL render with neutral slate background (`bg-slate-100 text-slate-600`)

---

## Requirement: Sidebar uses slate-700 with slate active indicator
The sidebar navigation SHALL use `bg-slate-700` as its background. The active navigation item SHALL be highlighted with a `bg-slate-500` pill. Non-active items SHALL display as `text-slate-200` with `hover:bg-slate-600` hover state. The brand bar at the top SHALL use `bg-slate-800`.

### Scenario: Active nav item
- **WHEN** the current page matches a navigation link
- **THEN** that link SHALL render with `bg-slate-500 text-white` classes applied

### Scenario: Inactive nav item
- **WHEN** the current page does not match a navigation link
- **THEN** that link SHALL render with `text-slate-200 hover:bg-slate-600 hover:text-white` classes

---

## Requirement: Indigo accent replaces blue throughout
All interactive elements that previously used `blue-600` as the accent SHALL use `indigo-600`. This includes primary buttons, link text, focus ring colors, active filter states, and the primary action button on all forms.

### Scenario: Primary CTA button color
- **WHEN** a primary action button is rendered (e.g., "New Customer", "Save")
- **THEN** it SHALL use `bg-indigo-600 hover:bg-indigo-700` classes

### Scenario: Link color
- **WHEN** a clickable company name or record link is rendered in a table
- **THEN** it SHALL use `text-indigo-600 hover:text-indigo-900` classes

---

## Requirement: Index tables include company initials chip
For index views listing companies (Prospects and Customers), each row SHALL display a circular avatar chip showing the first two letters of `company_name` in uppercase. The chip SHALL use `bg-indigo-100 text-indigo-700` styling.

### Scenario: Company initials shown in row
- **WHEN** a prospect or customer row is rendered in the index table
- **THEN** a circle avatar containing the first two letters of the company name SHALL appear before the company name link

### Scenario: Short company name
- **WHEN** a company name has only one character
- **THEN** the avatar chip SHALL display that single character

---

## Requirement: Empty states include icon and CTA
When a query returns no results, the empty state row SHALL display a centered icon (SVG), a descriptive message, and a link/button CTA (e.g., "Add your first customer"). The message SHALL not be a plain "No X found." string.

### Scenario: Empty index view
- **WHEN** no records match the current filter on an index page
- **THEN** the empty state SHALL render with an SVG icon, a brief message, and a primary CTA link

---

## Requirement: Flash messages use dismissible toast style
Flash messages SHALL render as dismissible toasts with a left 4px color accent bar, an inline SVG icon (checkmark for notice/success, exclamation triangle for alert/error), the message text, and an × close button. Alerts SHALL use red accent; notices SHALL use green accent.

### Scenario: Success flash displayed
- **WHEN** a controller sets `flash[:notice]`
- **THEN** the layout renders a green-accented toast with a checkmark icon and a dismiss button

### Scenario: Alert flash displayed
- **WHEN** a controller sets `flash[:alert]`
- **THEN** the layout renders a red-accented toast with an exclamation icon and a dismiss button

### Scenario: Flash dismissed
- **WHEN** the user clicks the × button on a flash toast
- **THEN** the toast SHALL be removed from the page without a full page reload

---

## Requirement: Filter bar uses borderless row style
The filter bar SHALL NOT be wrapped in a full shadow card. Instead, it SHALL render as a flat row separated from the table by a subtle `border-b border-slate-200` divider. Input fields and selects SHALL use `rounded-lg` corner radius for a more modern feel.

### Scenario: Filter bar renders without card
- **WHEN** any index page renders its filter bar
- **THEN** there SHALL be no `shadow` or `rounded-lg` card wrapping the filter fields — only a bottom-border separator

---

## Requirement: Role badge uses semantic colors
The `role_badge` helper SHALL use role-specific colors: admin in violet, consultant in indigo, pending in amber.

### Scenario: Admin role badge
- **WHEN** a user with role `admin` is displayed
- **THEN** the badge SHALL use `bg-violet-100 text-violet-700` classes

### Scenario: Consultant role badge
- **WHEN** a user with role `consultant` is displayed
- **THEN** the badge SHALL use `bg-indigo-100 text-indigo-700` classes

### Scenario: Pending role badge
- **WHEN** a user with role `pending` is displayed
- **THEN** the badge SHALL use `bg-amber-100 text-amber-700` classes
