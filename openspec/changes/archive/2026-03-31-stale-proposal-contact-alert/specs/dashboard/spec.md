## MODIFIED Requirements

### Requirement: Stale proposal alerts on personal dashboard
The system SHALL display alerts for the user's open proposals that have had no **touchpoint** (call, email, meeting, or note) logged in the last 30 calendar days. A proposal is stale if no touchpoint activity log entry has been recorded against it in the past 30 days and its status is not Won, Lost, or Cancelled. System-generated activity log entries (status changes, document link updates, consultant changes) SHALL NOT count toward staleness resolution. These alerts are dashboard-only and SHALL NOT trigger email notifications.

#### Scenario: Stale proposal displayed
- **WHEN** the user has an open Proposal with no touchpoint logged in the last 30 days
- **THEN** a stale proposal alert appears on their personal dashboard

#### Scenario: System event does not resolve stale alert
- **WHEN** only a system-generated activity log entry (e.g. status change) is recorded on a stale Proposal
- **THEN** the stale alert remains on the dashboard

#### Scenario: Touchpoint resolves stale alert
- **WHEN** a touchpoint (call, email, meeting, or note) is logged on a stale Proposal
- **THEN** the stale alert disappears from the dashboard

### Requirement: Team alert widget
The system SHALL display a team alert widget visible to all logged-in users showing: pending-conversion alerts (Won Proposal linked to unconverted Prospect) and stale proposal alerts (team-wide, open Proposals with no **touchpoint** in 30 days). Alerts SHALL link directly to the relevant record. Alerts SHALL disappear automatically when the underlying condition is resolved. Alerts SHALL NOT be manually dismissible.

#### Scenario: Pending conversion alert displayed
- **WHEN** a Proposal is marked Won and the linked Prospect has not been converted
- **THEN** a pending-conversion alert appears in the team alert widget for all users

#### Scenario: Pending conversion alert resolved
- **WHEN** the Prospect is converted to a Customer
- **THEN** the pending-conversion alert disappears from the widget

#### Scenario: Team stale proposal alert displayed
- **WHEN** an open Proposal has had no touchpoint logged in the last 30 days
- **THEN** a stale proposal alert appears in the team alert widget for all users

#### Scenario: System event does not resolve team stale alert
- **WHEN** only a system-generated activity log entry is recorded on a stale Proposal
- **THEN** the team stale alert remains in the widget

#### Scenario: Alert links to record
- **WHEN** a user clicks an alert in the team widget
- **THEN** the system navigates to the relevant record's detail page

#### Scenario: Alert cannot be dismissed manually
- **WHEN** a user attempts to dismiss an alert in the team widget
- **THEN** the system does not allow manual dismissal
