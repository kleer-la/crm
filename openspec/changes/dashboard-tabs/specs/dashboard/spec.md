## ADDED Requirements

### Requirement: Tabbed dashboard view
The system SHALL present the dashboard as two tabs: **Team** and **Mine**. Team SHALL be the default tab on every visit (no per-user memory of last-active tab). Mine SHALL be lazy-loaded — its content SHALL NOT be queried or rendered on first paint and SHALL be loaded only when the user activates the Mine tab. Both tabs SHALL be visible to every authenticated user regardless of role.

#### Scenario: Team tab is the default
- **WHEN** any authenticated user navigates to the dashboard
- **THEN** the Team tab is active and its content is visible

#### Scenario: Mine tab content is not loaded until activated
- **WHEN** the user first lands on the dashboard
- **THEN** the Mine tab's data queries do not execute and its content is not in the response body

#### Scenario: Mine tab loads on activation
- **WHEN** the user clicks the Mine tab for the first time in a session
- **THEN** the Mine tab's content is fetched and rendered

#### Scenario: Switching back to a loaded tab is instant
- **WHEN** the user switches between tabs after both have been loaded
- **THEN** no additional requests are made and the previously loaded content is shown immediately

#### Scenario: Both tabs visible to consultants
- **WHEN** a Consultant navigates to the dashboard
- **THEN** both the Team and Mine tabs are visible and selectable

#### Scenario: Both tabs visible to admins
- **WHEN** an Admin navigates to the dashboard
- **THEN** the Admin sees the same two tabs and the same content as a Consultant — no admin-specific dashboard widgets, metrics, or sections

### Requirement: Always-visible team KPI strip
The system SHALL display a team-wide KPI strip above the tab navigation that remains visible regardless of the active tab. The strip SHALL show three metrics computed from live data across the entire team: total team pipeline value (sum of `estimated_value` across all open Proposals), total team Proposals sent this month, and total team Proposals won this month.

#### Scenario: KPI strip visible on Team tab
- **WHEN** the user views the dashboard with the Team tab active
- **THEN** the team KPI strip is visible above the tab navigation

#### Scenario: KPI strip visible on Mine tab
- **WHEN** the user switches to the Mine tab
- **THEN** the team KPI strip remains visible above the tab navigation

#### Scenario: KPI strip reflects live data
- **WHEN** a Proposal status changes and the user reloads the dashboard
- **THEN** the KPI strip values reflect the updated state immediately

### Requirement: Team open proposals widget
The Team tab SHALL display a browse list of all open Proposals across the team, showing for each proposal the title, the linked Prospect or Customer name, the responsible consultant, and the estimated value. The list SHALL not be paginated (the team handles a small enough number of open proposals that a single list is appropriate).

#### Scenario: Team open proposals listed
- **WHEN** the user views the Team tab and there are open Proposals
- **THEN** every open Proposal across the team is listed in the Team open proposals widget

#### Scenario: Closed proposals excluded
- **WHEN** a Proposal has status Won, Lost, or Cancelled
- **THEN** it does not appear in the Team open proposals widget

#### Scenario: Empty state
- **WHEN** there are no open Proposals across the team
- **THEN** the widget displays a calm empty state instead of being absent

### Requirement: Overdue tasks team alert
The Team tab SHALL display an "Overdue tasks" alert box listing every Task across the team whose `due_date` is in the past and whose status is open or in-progress. Each entry SHALL link to the task and show the assignee. The alert box SHALL be non-dismissible. The alert box SHALL NOT be rendered when there are no overdue tasks.

#### Scenario: Overdue task displayed
- **WHEN** any team member has an open or in-progress Task whose `due_date` is before the current date
- **THEN** the task appears in the Overdue tasks alert box on the Team tab

#### Scenario: Completed task removed
- **WHEN** an overdue Task is marked completed
- **THEN** the task no longer appears in the Overdue tasks alert box

#### Scenario: Due date moved to future
- **WHEN** an overdue Task's due_date is updated to a future date
- **THEN** the task no longer appears in the Overdue tasks alert box

#### Scenario: Cannot dismiss overdue task alerts
- **WHEN** a user attempts to dismiss the Overdue tasks alert box or any task within it
- **THEN** the system does not provide a dismissal control and the alert remains until each underlying task is resolved

#### Scenario: Empty state
- **WHEN** there are no overdue tasks across the team
- **THEN** the Overdue tasks alert box is not rendered

## MODIFIED Requirements

### Requirement: Personal dashboard
The system SHALL display a **Mine** tab on the dashboard showing the user's personal worklist: my open tasks (sorted by due date, overdue first), my open proposals (grouped by status), my active prospects, and recent activity on my records. "My" records means records where the user is the responsible or a collaborating consultant. The Mine tab SHALL NOT display team-wide content.

#### Scenario: View personal dashboard
- **WHEN** a logged-in user activates the Mine tab
- **THEN** they see their open tasks, open proposals, active prospects, and recent activity on their records

#### Scenario: Overdue tasks appear first
- **WHEN** the user has overdue open tasks
- **THEN** overdue tasks are sorted to the top of the Mine tab task list

#### Scenario: Personal data only on Mine
- **WHEN** the user activates the Mine tab
- **THEN** the worklists show only records where the user is responsible or a collaborating consultant

### Requirement: Stale proposal alerts on personal dashboard
The Mine tab SHALL display an alert box listing the user's open proposals that have had no **touchpoint** (call, email, meeting, or note) logged in the last 30 calendar days. A proposal is stale if no touchpoint activity log entry has been recorded against it in the past 30 days and its status is not Won, Lost, or Cancelled. System-generated activity log entries (status changes, document link updates, consultant changes) SHALL NOT count toward staleness resolution. These alerts are dashboard-only and SHALL NOT trigger email notifications. The alert box SHALL NOT be rendered when the user has no stale proposals.

#### Scenario: Stale proposal displayed
- **WHEN** the user has an open Proposal with no touchpoint logged in the last 30 days
- **THEN** a stale proposal alert appears in the Mine tab's stale-proposals alert box

#### Scenario: System event does not resolve stale alert
- **WHEN** only a system-generated activity log entry (e.g. status change) is recorded on a stale Proposal
- **THEN** the stale alert remains on the Mine tab

#### Scenario: Touchpoint resolves stale alert
- **WHEN** a touchpoint (call, email, meeting, or note) is logged on a stale Proposal
- **THEN** the stale alert disappears from the Mine tab

#### Scenario: Empty state
- **WHEN** the user has no stale proposals
- **THEN** the stale-proposals alert box is not rendered on the Mine tab

### Requirement: Team alert widget
The Team tab SHALL display per-type alert boxes visible to all authenticated users: a pending-conversion alert box (Won Proposals linked to unconverted Prospects) and a stale proposal alert box (team-wide, open Proposals with no **touchpoint** in 30 days). Each alert box SHALL be rendered only when it has at least one alert. Alerts SHALL link directly to the relevant record. Alerts SHALL disappear automatically when the underlying condition is resolved. Alerts SHALL NOT be manually dismissible. Mine-tab variants of these alert boxes SHALL show only the user's records (where the user is responsible or a collaborating consultant).

#### Scenario: Pending conversion alert displayed on Team tab
- **WHEN** a Proposal is marked Won and the linked Prospect has not been converted
- **THEN** a pending-conversion alert appears in the Team tab's pending-conversion alert box for all users

#### Scenario: Pending conversion alert resolved
- **WHEN** the Prospect is converted to a Customer
- **THEN** the pending-conversion alert disappears from the Team tab

#### Scenario: Team stale proposal alert displayed
- **WHEN** an open Proposal has had no touchpoint logged in the last 30 days
- **THEN** a stale proposal alert appears in the Team tab's stale-proposals alert box for all users

#### Scenario: System event does not resolve team stale alert
- **WHEN** only a system-generated activity log entry is recorded on a stale Proposal
- **THEN** the team stale alert remains on the Team tab

#### Scenario: Alert links to record
- **WHEN** a user clicks an alert in the Team tab
- **THEN** the system navigates to the relevant record's detail page

#### Scenario: Alert cannot be dismissed manually
- **WHEN** a user attempts to dismiss an alert on the Team tab
- **THEN** the system does not provide a dismissal control

#### Scenario: Mine-tab pending conversions show only my records
- **WHEN** the user activates the Mine tab
- **THEN** the pending-conversion alert box on Mine shows only Won Proposals where the user is responsible or a collaborating consultant on the linked Prospect

#### Scenario: Mine-tab stale proposals show only my records
- **WHEN** the user activates the Mine tab
- **THEN** the stale-proposals alert box on Mine shows only stale Proposals where the user is responsible or a collaborating consultant

#### Scenario: Empty alert box not rendered
- **WHEN** an alert category has no current alerts
- **THEN** that alert box is not rendered (Team or Mine)

## REMOVED Requirements

### Requirement: Admin dashboard
**Reason**: The team operates as a flat organization. Admins do not have privileged CRM access — the Admin role only governs user-management responsibilities (creating, deactivating, and assigning roles to users). The dashboard SHALL NOT differentiate between Admin and Consultant. All dashboard widgets, metrics, and alert boxes are visible to every authenticated user.

**Migration**: The team-wide metrics formerly visible only to admins are now in the always-visible team KPI strip (visible to every user). The "all overdue tasks across the team" widget formerly visible only to admins is now the Overdue tasks team alert box on the Team tab (visible to every user).
