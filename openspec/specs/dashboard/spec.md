## Purpose
Provide a personal home screen with open tasks, proposals, prospects, recent activity, key metrics, stale proposal alerts, team alerts, and admin-only team-wide views.

## Requirements

### Requirement: Personal dashboard
The system SHALL display a personal dashboard as the home screen showing: my open tasks (sorted by due date, overdue first), my open proposals (grouped by status), my active prospects, recent activity on my records, and key metrics (my total pipeline value, proposals sent this month, proposals won this month). "My" records means records where the user is the responsible or a collaborating consultant.

#### Scenario: View personal dashboard
- **WHEN** a logged-in user navigates to the dashboard
- **THEN** they see their open tasks, proposals, prospects, recent activity, and personal metrics

#### Scenario: Overdue tasks appear first
- **WHEN** the user has overdue open tasks
- **THEN** overdue tasks are sorted to the top of the task list

### Requirement: Stale proposal alerts on personal dashboard
The system SHALL display alerts for the user's open proposals that have had no activity logged in the last 30 calendar days. A proposal is stale if no activity log entry has been recorded against it in the past 30 days and its status is not Won, Lost, or Cancelled. These alerts are dashboard-only and SHALL NOT trigger email notifications.

#### Scenario: Stale proposal displayed
- **WHEN** the user has an open Proposal with no activity in the last 30 days
- **THEN** a stale proposal alert appears on their personal dashboard

#### Scenario: Activity logged resolves stale alert
- **WHEN** activity is logged on a stale Proposal
- **THEN** the stale alert disappears from the dashboard

### Requirement: Team alert widget
The system SHALL display a team alert widget visible to all logged-in users showing: pending-conversion alerts (Won Proposal linked to unconverted Prospect) and stale proposal alerts (team-wide, open Proposals with no activity in 30 days). Alerts SHALL link directly to the relevant record. Alerts SHALL disappear automatically when the underlying condition is resolved. Alerts SHALL NOT be manually dismissible.

#### Scenario: Pending conversion alert displayed
- **WHEN** a Proposal is marked Won and the linked Prospect has not been converted
- **THEN** a pending-conversion alert appears in the team alert widget for all users

#### Scenario: Pending conversion alert resolved
- **WHEN** the Prospect is converted to a Customer
- **THEN** the pending-conversion alert disappears from the widget

#### Scenario: Alert links to record
- **WHEN** a user clicks an alert in the team widget
- **THEN** the system navigates to the relevant record's detail page

#### Scenario: Alert cannot be dismissed manually
- **WHEN** a user attempts to dismiss an alert in the team widget
- **THEN** the system does not allow manual dismissal

### Requirement: Admin dashboard
The system SHALL display additional admin-only dashboard content showing: team-wide versions of all personal metrics and all overdue open tasks across the team.

#### Scenario: Admin views admin dashboard
- **WHEN** an Admin navigates to the dashboard
- **THEN** they see the personal dashboard content plus team-wide metrics and all overdue tasks across the team

#### Scenario: Consultant cannot see admin metrics
- **WHEN** a Consultant navigates to the dashboard
- **THEN** they see only the personal dashboard content, not team-wide admin metrics

### Requirement: Dashboard metrics from live data
All dashboard metrics SHALL be calculated from live data with no stale caching.

#### Scenario: Metrics reflect current state
- **WHEN** a user views the dashboard after a Proposal status change
- **THEN** all metrics reflect the updated state immediately
