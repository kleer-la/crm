## Purpose
Track and display an immutable, chronological record of all system events and manual touchpoints on Prospect, Customer, and Proposal records.

## Requirements

### Requirement: Automatic system event logging
The system SHALL automatically create immutable activity log entries for system events: status changes, record creation, assignment changes, document link updates, and conversion events. Each entry SHALL record: timestamp, user, entry type, and content/description.

#### Scenario: Status change logged
- **WHEN** a user changes the status of a Prospect, Customer, or Proposal
- **THEN** the system automatically creates an activity log entry recording the change

#### Scenario: Record creation logged
- **WHEN** a new Prospect, Customer, or Proposal is created
- **THEN** the system automatically creates an activity log entry recording the creation

#### Scenario: Assignment change logged
- **WHEN** the responsible consultant or collaborating consultants are changed on a record
- **THEN** the system automatically creates an activity log entry recording the change

### Requirement: Manual touchpoint logging
The system SHALL allow users to log manual touchpoints on Prospect, Customer, and Proposal records. Touchpoints require a type selection (Call|Email|Meeting|Chat|Other), a non-empty description, and a date indicating when the interaction occurred (defaults to today). The occurred_at date is immutable once saved.

#### Scenario: Log a touchpoint with type, description, and default date
- **WHEN** a user logs a touchpoint with type "Call" and a description without changing the date
- **THEN** the system creates an activity log entry with the type, description, user, and occurred_at set to today

#### Scenario: Log a touchpoint with a past date
- **WHEN** a user logs a touchpoint and selects a date in the past
- **THEN** the system creates an activity log entry with occurred_at set to the selected past date

#### Scenario: Log a touchpoint without description
- **WHEN** a user attempts to log a touchpoint without a description
- **THEN** the system rejects the entry and requires a description

### Requirement: Activity log immutability
Activity log entries SHALL be immutable once created. No user or admin SHALL be able to edit or delete them.

#### Scenario: Attempt to edit an activity log entry
- **WHEN** any user attempts to edit an existing activity log entry
- **THEN** the system prevents the modification

#### Scenario: Attempt to delete an activity log entry
- **WHEN** any user attempts to delete an activity log entry
- **THEN** the system prevents the deletion

### Requirement: Chronological activity log display
The system SHALL display all activity log entries on a record's detail page sorted by occurred_at in descending order (newest first). Timestamps SHALL be displayed as absolute dates (e.g. "Apr 01, 2026").

#### Scenario: View activity log on a record with backdated touchpoints
- **WHEN** a user opens a Prospect, Customer, or Proposal detail page that has backdated touchpoints
- **THEN** all activity log entries are displayed sorted by occurred_at descending, with absolute dates shown
