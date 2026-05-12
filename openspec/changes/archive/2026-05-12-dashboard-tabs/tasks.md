## 1. Routes and controller skeleton

- [x] 1.1 Add `get "dashboard/team_panel"` and `get "dashboard/mine_panel"` routes (both mapped to `dashboard#team_panel` / `dashboard#mine_panel`) in `config/routes.rb`
- [x] 1.2 Refactor `DashboardController#index` to load only the team KPI strip data (`@team_pipeline_value`, `@team_proposals_sent`, `@team_proposals_won`) and remove all admin gating
- [x] 1.3 Extract a `TeamMetricsLoader` private method (or simple PORO) so the same KPI computation is reusable and unit-testable
- [x] 1.4 Add `DashboardController#team_panel` action loading: team pending conversions, team stale proposals, team overdue tasks, team open proposals, team-wide recent activity
- [x] 1.5 Add `DashboardController#mine_panel` action loading: my pending conversions, my stale proposals, my open tasks, my open proposals, my active prospects, my recent activity (preserve existing `my_record_ids` helper)
- [x] 1.6 Both panel actions render with `layout: false` so the response is the bare frame content
- [x] 1.7 Remove the now-unused `load_personal_data`, `load_team_alerts`, and `load_admin_data` private methods (their content has moved into the panel actions)

## 2. Views — shell and tab navigation

- [x] 2.1 Rewrite `app/views/dashboard/index.html.erb` as the shell: page heading, KPI strip, tab navigation, and the two `<turbo-frame>` containers
- [x] 2.2 Add the Team frame with `src=` pointing to `dashboard_team_panel_path` (eager-loaded)
- [x] 2.3 Add the Mine frame with `src=` and `loading="lazy"` so its request fires only when the frame becomes visible
- [x] 2.4 Add `app/javascript/controllers/dashboard_tabs_controller.js` (Stimulus) that toggles `hidden` on the two frame containers and `aria-selected` on the tab buttons; default-active tab is Team
- [x] 2.5 Register the Stimulus controller in the index manifest if controllers aren't auto-loaded

## 3. Views — Team tab content

- [x] 3.1 Create `app/views/dashboard/team_panel.html.erb` wrapping content in `<turbo-frame id="dashboard-team">` with the 2/3 + 1/3 grid
- [x] 3.2 Create `app/views/dashboard/_team_pending_conversions.html.erb` partial — alert box per conversion, only rendered when at least one alert exists
- [x] 3.3 Create `app/views/dashboard/_team_stale_proposals.html.erb` partial — alert box per stale proposal, only rendered when at least one alert exists
- [x] 3.4 Create `app/views/dashboard/_team_overdue_tasks.html.erb` partial — alert box listing every overdue open/in-progress task with assignee, only rendered when at least one alert exists, no dismiss control
- [x] 3.5 Create `app/views/dashboard/_team_open_proposals.html.erb` partial — browse list of all open proposals with title, linked Prospect/Customer name, responsible consultant, estimated value; renders calm empty state when none
- [x] 3.6 Render the all-team activity timeline in the right 1/3 column using the existing `shared/activity_timeline` partial

## 4. Views — Mine tab content

- [x] 4.1 Create `app/views/dashboard/mine_panel.html.erb` wrapping content in `<turbo-frame id="dashboard-mine">` with the 2/3 + 1/3 grid
- [x] 4.2 Create `app/views/dashboard/_mine_pending_conversions.html.erb` partial — only Won proposals where the user is responsible or a collaborating consultant on the linked Prospect
- [x] 4.3 Create `app/views/dashboard/_mine_stale_proposals.html.erb` partial — only stale proposals where the user is responsible or a collaborating consultant
- [x] 4.4 Create `app/views/dashboard/_mine_open_tasks.html.erb` partial — overdue first, then by due_date (existing behavior preserved)
- [x] 4.5 Create `app/views/dashboard/_mine_open_proposals.html.erb` partial — grouped by status (existing behavior preserved)
- [x] 4.6 Create `app/views/dashboard/_mine_active_prospects.html.erb` partial — top 10 by `last_activity_date` (existing behavior preserved)
- [x] 4.7 Render the user's recent activity in the right 1/3 column using the existing `shared/activity_timeline` partial

## 5. Views — KPI strip

- [x] 5.1 Create `app/views/dashboard/_kpi_strip.html.erb` partial showing team pipeline value, team proposals sent this month, team proposals won this month, using existing card styling
- [x] 5.2 Render the partial in `index.html.erb` above the tab navigation so it stays visible regardless of active tab

## 6. Remove legacy admin block

- [x] 6.1 Delete the admin-only "Admin: Team overview" block from the legacy view (subsumed by the rewrite of `index.html.erb`)
- [x] 6.2 Confirm by grep that no remaining `current_user.admin?` checks exist anywhere in `app/controllers/dashboard_controller.rb` or `app/views/dashboard/`

## 7. Tests

- [x] 7.1 Update `test/controllers/dashboard_controller_test.rb`: rewrite `index` tests to assert the shell renders, the KPI strip is present, both tab frames are present, and the Mine frame uses `loading="lazy"`
- [x] 7.2 Collapse the existing admin-vs-consultant tests for `index` into a single test (both roles see the same page)
- [x] 7.3 Add controller test for `team_panel`: returns success for a Consultant, renders all-team alerts and open proposals, renders empty states when nothing applies
- [x] 7.4 Add controller test for `mine_panel`: returns success, renders only the user's records, renders empty states when nothing applies
- [x] 7.5 Add a test asserting the Overdue tasks alert box appears on the Team tab when any consultant has an overdue open task, and disappears when the task is completed
- [x] 7.6 Add a test asserting Mine-tab alert boxes show only the user's records (filter respects `responsible_consultant_id` and collaborator assignments)
- [x] 7.7 Add an integration/system test asserting Mine-tab content is not present in the initial dashboard response (verifies lazy loading at the response level — no need for JS driver)

## 8. Verification

- [x] 8.1 Run `bin/ci` and confirm all tests, style, and security checks pass
- [x] 8.2 Manually verify in the browser: Team tab is default and visible, Mine tab loads on click, KPI strip stays visible across tab switches, empty states render calmly, no admin-only widgets visible to admin users
- [x] 8.3 Run `openspec validate dashboard-tabs --strict` and confirm no validation errors
