## ADDED Requirements

### Requirement: Email notification for task due in 1 day
The system SHALL send an email notification to the assigned consultant when a task is due in 1 day. The email SHALL be sent to the user's Google account email address.

#### Scenario: Task due tomorrow with open status
- **WHEN** a task's due date is tomorrow and its status is Open or In Progress
- **THEN** the assigned consultant receives an email reminder with the task title, due date, and a link to the task

#### Scenario: Task already completed
- **WHEN** a task's due date is tomorrow but its status is Done or Cancelled
- **THEN** no email notification is sent

#### Scenario: User opted out of task reminders
- **WHEN** a task's due date is tomorrow and the assigned consultant has disabled task_due_reminder notifications
- **THEN** no email notification is sent

### Requirement: Email notification on Proposal status change
The system SHALL send an email notification to the responsible consultant and all collaborating consultants when a Proposal's status changes. Notification emails SHALL NOT include Google Drive document links or document content.

#### Scenario: Proposal status changes
- **WHEN** a Proposal's status changes (e.g., Draft to Sent, Sent to Under Review, etc.)
- **THEN** the responsible consultant and all collaborating consultants receive an email notification with the proposal title, old status, new status, and a link to the proposal

#### Scenario: Collaborating consultant opted out
- **WHEN** a Proposal's status changes and a collaborating consultant has disabled proposal_status_change notifications
- **THEN** that consultant does not receive the email, but other eligible consultants still do

#### Scenario: No document links in email
- **WHEN** a Proposal status change email is sent
- **THEN** the email SHALL NOT contain any document URLs or document content

### Requirement: Stale proposals do not trigger email
Stale proposal alerts SHALL NOT trigger email notifications. They are surfaced on the dashboard only.

#### Scenario: Proposal becomes stale
- **WHEN** an open Proposal has no activity for 30 days
- **THEN** no email notification is sent; the stale alert appears on the dashboard only

### Requirement: Task reminder job runs daily
The system SHALL run a background job daily that identifies all tasks due the next day and sends reminder emails.

#### Scenario: Daily job execution
- **WHEN** the daily task reminder job runs
- **THEN** it identifies all tasks with due_date equal to tomorrow, status Open or In Progress, and sends one email per eligible task to the assigned consultant

#### Scenario: No tasks due tomorrow
- **WHEN** the daily task reminder job runs and no tasks are due tomorrow
- **THEN** no emails are sent and the job completes successfully
