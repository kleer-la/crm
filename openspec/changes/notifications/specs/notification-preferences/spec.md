## ADDED Requirements

### Requirement: Per-user notification opt-out
Users SHALL be able to opt out of individual email notification types from their profile settings. Notifications SHALL default to enabled for all types.

#### Scenario: User opts out of task reminders
- **WHEN** a user disables task_due_reminder in their notification preferences
- **THEN** they no longer receive task due email notifications

#### Scenario: User opts out of proposal notifications
- **WHEN** a user disables proposal_status_change in their notification preferences
- **THEN** they no longer receive proposal status change emails

#### Scenario: Default preferences for new user
- **WHEN** a new user account is created and no NotificationPreference records exist for them
- **THEN** all notification types SHALL be treated as enabled by default

### Requirement: Notification preferences UI
The system SHALL provide a notification preferences page accessible from the user profile where users can toggle each notification type on or off.

#### Scenario: Access notification preferences
- **WHEN** a user navigates to their notification preferences page
- **THEN** they see a toggle for each notification type (task_due_reminder, proposal_status_change) with current state

#### Scenario: Toggle a notification preference
- **WHEN** a user toggles a notification type off and saves
- **THEN** a NotificationPreference record is created or updated with enabled: false for that type

#### Scenario: Re-enable a notification preference
- **WHEN** a user toggles a previously disabled notification type back on and saves
- **THEN** the NotificationPreference record is updated with enabled: true
