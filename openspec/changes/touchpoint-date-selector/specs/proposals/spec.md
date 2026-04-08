## ADDED Requirements

### Requirement: Proposal last activity date tracking
The system SHALL maintain a last_activity_date on each Proposal reflecting when the most recent client-facing event occurred. The field SHALL be updated when a touchpoint is logged against the proposal (using the touchpoint's occurred_at date) or when the proposal's status changes (using the current date). Internal events (consultant reassignment, document link changes, proposal creation) SHALL NOT update last_activity_date.

#### Scenario: Touchpoint logged on proposal updates last_activity_date
- **WHEN** a user logs a touchpoint on a Proposal with an occurred_at date
- **THEN** the Proposal's last_activity_date is updated to that occurred_at date

#### Scenario: Backdated touchpoint sets last_activity_date to past date
- **WHEN** a user logs a touchpoint on a Proposal with a past occurred_at date
- **THEN** the Proposal's last_activity_date is updated to that past date

#### Scenario: Status change updates last_activity_date
- **WHEN** a Proposal's status is changed
- **THEN** the Proposal's last_activity_date is updated to today's date

#### Scenario: Consultant reassignment does not update last_activity_date
- **WHEN** the responsible consultant on a Proposal is changed
- **THEN** the Proposal's last_activity_date is not updated

### Requirement: Stale proposal detection uses occurred_at
The system SHALL consider a Proposal stale when no touchpoint with an occurred_at date within the last 30 days exists for it. Touchpoints logged today with a past occurred_at date SHALL count as activity for the occurred_at date.

#### Scenario: Proposal with a recent backdated touchpoint is not stale
- **WHEN** a user logs a touchpoint on a Proposal with an occurred_at date 10 days ago
- **THEN** the Proposal is not considered stale

#### Scenario: Proposal with no touchpoints in 30 days is stale
- **WHEN** a Proposal has no touchpoints with occurred_at within the last 30 days
- **THEN** the Proposal is flagged as stale
