## ADDED Requirements

### Requirement: Touchpoint date selection
The system SHALL allow users to specify the date a touchpoint interaction occurred when logging a touchpoint. The date field SHALL default to today and accept any past or present date. The occurred_at date SHALL be immutable once the touchpoint is saved.

#### Scenario: Log touchpoint with today's date (default)
- **WHEN** a user logs a touchpoint without changing the date field
- **THEN** the system records the touchpoint with occurred_at set to today's date

#### Scenario: Log touchpoint with a past date
- **WHEN** a user logs a touchpoint and selects a date in the past
- **THEN** the system records the touchpoint with occurred_at set to the selected date

#### Scenario: Log touchpoint without a date
- **WHEN** a user attempts to log a touchpoint without specifying a date
- **THEN** the system rejects the entry and requires a date
