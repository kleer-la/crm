## 1. Design System Foundation (Helpers & Shared Partials)

- [x] 1.1 Update `ApplicationHelper#status_badge` to map all status values to semantic color classes per the design token table (prospect: new/qualified/disqualified/converted; customer: active/inactive; proposal: draft/sent/won/lost; task: open/completed/cancelled)
- [x] 1.2 Update `ApplicationHelper#role_badge` (or unify into `status_badge`) to map admin→violet, consultant→indigo, pending→amber
- [x] 1.3 Update `ApplicationHelper#sidebar_link` to use `slate-700` bg, `indigo-600` active pill, `text-slate-200` / `hover:bg-slate-600` inactive state
- [x] 1.4 Update `layouts/_sidebar.html.erb` to use `bg-slate-700` and brand bar `bg-slate-800`
- [x] 1.5 Restyle `layouts/_flash.html.erb` as dismissible toast: left 4px color bar, SVG icon, message, × close button (green for notice, red for alert)
- [x] 1.6 Restyle `shared/_filter_bar.html.erb` — remove shadow card, replace with flat borderless row + `border-b border-slate-200` divider; update input/select classes to `rounded-lg`
- [x] 1.7 Write helper tests in `test/helpers/application_helper_test.rb` for `status_badge` (all statuses) and `role_badge` (all roles), verifying correct CSS classes are rendered

## 2. Pilot — Customers Module

- [x] 2.1 Update `customers/index.html.erb`: swap `blue-600` → `indigo-600` on the New Customer button; add company initials chip per row; update row link to `text-indigo-600`; update `hover:bg-gray-50` → `hover:bg-indigo-50`; improve empty state with SVG icon + message + CTA
- [x] 2.2 Update `customers/index.html.erb`: replace `bg-white shadow rounded-lg` card with `bg-white ring-1 ring-slate-200 rounded-xl` on the table wrapper
- [x] 2.3 Update `customers/show.html.erb`: replace all `shadow rounded-lg` cards with `ring-1 ring-slate-200 rounded-xl`; swap blue links → indigo; update the Edit button to secondary outline style
- [x] 2.4 Update `customers/_form.html.erb`: swap blue focus/button classes → indigo; update Cancel button to secondary outline style
- [x] 2.5 Write an integration test `test/integration/ui_design_system_test.rb` covering: Customers index renders indigo initials chip, correct empty state structure, and status badge color classes

## 3. Prospects Module

- [x] 3.1 Update `prospects/index.html.erb`: company initials chip, indigo links, indigo-50 row hover, empty state with icon + CTA, ring card wrapper
- [x] 3.2 Update `prospects/show.html.erb`: ring cards, indigo buttons/links, secondary outline Edit button, indigo Convert button replaces green
- [x] 3.3 Update `prospects/_form.html.erb`: indigo focus/button classes, secondary Cancel button

## 4. Proposals Module

- [x] 4.1 Update `proposals/index.html.erb`: indigo links, indigo-50 row hover, empty state, ring card wrapper
- [x] 4.2 Update `proposals/show.html.erb`: ring cards, indigo links/buttons
- [x] 4.3 Update `proposals/_form.html.erb`: indigo focus/button classes

## 5. Tasks Module

- [x] 5.1 Update `tasks/index.html.erb`: indigo links, indigo-50 row hover, empty state with icon + CTA, ring card wrapper
- [x] 5.2 Update `tasks/show.html.erb`: ring cards, indigo links/buttons
- [x] 5.3 Update `tasks/_form.html.erb`: indigo focus/button classes

## 6. Pipeline, Dashboard & Search

- [x] 6.1 Update `pipeline/index.html.erb`: indigo column headers/accents, ring cards on lane containers
- [x] 6.2 Update `dashboard/show.html.erb` (if present): ring card wrappers, indigo stat highlights, empty states
- [x] 6.3 Update `search/index.html.erb`: indigo result links, ring result card

## 7. Admin & Sessions

- [x] 7.1 Update `admin/` views (users index/show, import): ring cards, indigo buttons, role badge colors from updated helper
- [x] 7.2 Update `sessions/new.html.erb` (login screen): indigo or slate accent on the sign-in button

## 8. Cleanup & CI

- [x] 8.1 Search entire codebase for `blue-600`, `blue-700`, `blue-500`, `blue-900` and replace with `indigo-` equivalents in all views and helpers
- [x] 8.2 Search for `bg-gray-800`, `bg-gray-900` in sidebar/layout partials and confirm all replaced with `slate-` equivalents
- [x] 8.3 Search for `shadow rounded-lg` on card containers and confirm replaced with `ring-1 ring-slate-200 rounded-xl`
- [x] 8.4 Run `bin/ci` and fix any rubocop or test failures
