## MODIFIED Requirements

### Requirement: Manual touchpoint logging
The system SHALL allow users to log manual touchpoints on Prospect, Customer, and Proposal records. Touchpoints require a type selection (Call|Email|Meeting|Note), a non-empty description, and a date indicating when the interaction occurred (defaults to today).

#### Scenario: Log a touchpoint with type, description, and default date
- **WHEN** a user logs a touchpoint with type "Call" and a description without changing the date
- **THEN** the system creates an activity log entry with the type, description, user, and occurred_at set to today

#### Scenario: Log a touchpoint with a past date
- **WHEN** a user logs a touchpoint and selects a date in the past
- **THEN** the system creates an activity log entry with occurred_at set to the selected past date

#### Scenario: Log a touchpoint without description
- **WHEN** a user attempts to log a touchpoint without a description
- **THEN** the system rejects the entry and requires a description

### Requirement: Chronological activity log display
The system SHALL display all activity log entries on a record's detail page sorted by occurred_at in descending order. Timestamps SHALL be displayed as absolute dates (e.g. "Apr 01, 2026").

#### Scenario: View activity log on a record with backdated touchpoints
- **WHEN** a user opens a Prospect, Customer, or Proposal detail page that has backdated touchpoints
- **THEN** all activity log entries are displayed sorted by occurred_at descending, with absolute dates shown
