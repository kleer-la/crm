## Purpose
Deliver email notifications for task due dates and proposal status changes with opt-out support, plus an in-app notification bell for recent activity.

## Requirements

### Requirement: Email notification for task due in 1 day
The system SHALL send an email notification to the assigned consultant when a task is due in 1 day. The email SHALL be sent to the user's Google account email address.

#### Scenario: Task due tomorrow
- **WHEN** a task's due date is tomorrow and its status is Open or In Progress
- **THEN** the assigned consultant receives an email reminder

#### Scenario: Task already completed
- **WHEN** a task's due date is tomorrow but its status is Done or Cancelled
- **THEN** no email notification is sent

### Requirement: Email notification on Proposal status change
The system SHALL send an email notification to the responsible consultant and all collaborating consultants when a Proposal's status changes. Notification emails SHALL NOT include Google Drive document links or document content.

#### Scenario: Proposal status changes
- **WHEN** a Proposal's status changes from Draft to Sent
- **THEN** the responsible consultant and all collaborating consultants receive an email notification without any document links

### Requirement: Email notification opt-out
Users SHALL be able to opt out of individual email notification types from their profile settings.

#### Scenario: User opts out of task reminders
- **WHEN** a user disables task due reminders in their profile settings
- **THEN** they no longer receive task due email notifications

#### Scenario: User opts out of proposal notifications
- **WHEN** a user disables proposal status change notifications
- **THEN** they no longer receive proposal status change emails

### Requirement: In-app notification bell
The system SHALL display an in-app notification bell showing recent activity on records where the logged-in user is the responsible or collaborating consultant. The bell SHALL show entries from the last 90 days only; older entries remain accessible via the record's activity log.

#### Scenario: New activity on user's record
- **WHEN** activity is logged on a record where the user is the responsible or collaborating consultant
- **THEN** the notification bell shows the new entry

#### Scenario: Activity older than 90 days
- **WHEN** an activity entry is older than 90 days
- **THEN** it no longer appears in the notification bell but remains in the record's activity log

### Requirement: Stale proposals do not trigger email
Stale proposal alerts SHALL NOT trigger email notifications. They are surfaced on the dashboard only.

#### Scenario: Proposal becomes stale
- **WHEN** an open Proposal has no activity for 30 days
- **THEN** no email notification is sent; the stale alert appears on the dashboard only
