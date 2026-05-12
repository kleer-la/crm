## Why

The current dashboard mixes personal worklists, team alerts, personal alerts, personal metrics, and admin-only team metrics into a single long scroll, making focus and scanning difficult. The admin-only gating no longer reflects how the team operates — we are a flat organization where admins do not have privileged CRM access (only user-management responsibilities). Splitting Team and Mine into clearly separated tabs, with team metrics always visible above, gives every consultant the same shared view of pipeline health plus a focused personal worklist.

## What Changes

- Restructure the dashboard into two tabs: **Team** (default, eager-loaded) and **Mine** (lazy-loaded via Turbo Frame so no work happens for the inactive tab on first paint).
- Add an always-visible team-wide KPI strip above the tabs: team pipeline value, team proposals sent this month, team proposals won this month.
- **Team tab** shows per-type alert boxes (pending conversions, stale proposals, overdue tasks) and an open-proposals browse list in the left 2/3, plus all-team recent activity in the right 1/3.
- **Mine tab** shows my pending conversions, my stale proposals, my open tasks, my open proposals, my active prospects in the left 2/3, plus my recent activity in the right 1/3.
- **NEW**: surface "Overdue tasks" as a Team-tab alert box (replaces the removed admin-only "all overdue tasks" widget).
- **BREAKING**: Remove all admin-only gating from the dashboard. Admins see exactly what consultants see. The current `current_user.admin?` block (admin metrics + admin overdue-tasks list) is removed.
- Default tab is Team on every visit (no per-user memory, no URL state).
- Alerts remain non-dismissible — they disappear only when the underlying condition resolves.

## Capabilities

### New Capabilities
None. All changes live within the existing `dashboard` capability.

### Modified Capabilities
- `dashboard`: Add tabbed view structure (Team default, Mine lazy), always-visible team KPI strip, Team-tab open-proposals browse widget, and Overdue-tasks team alert. Narrow personal-dashboard requirements to the Mine tab. Expand team-alert requirements to cover the per-type box layout. Remove the admin-only dashboard requirement.

## Impact

- **Code**: `DashboardController#index` is restructured to render only the shell (KPI strip + tab nav + two turbo frames). Two new actions `#team_panel` and `#mine_panel` render per-tab content. Routes added for both. Views are reorganized into one shell template plus two panel partials and a Stimulus controller for tab switching. The current single `index.html.erb` is rewritten.
- **Authorization**: `current_user.admin?` checks removed from the dashboard controller and views. No other controllers are affected by this change.
- **Tests**: `dashboard_controller_test.rb` is updated to cover the shell + the two panel actions; admin-vs-consultant test cases collapse into one.
- **Performance**: Net win on first paint for users who only need Team data — the Mine queries do not run until the user clicks the Mine tab. No caching introduced (live data preserved per existing spec).
- **Dependencies**: None. Uses existing Hotwire stack.
