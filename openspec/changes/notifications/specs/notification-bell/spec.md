## ADDED Requirements

### Requirement: In-app notification bell
The system SHALL display an in-app notification bell in the top bar showing recent activity on records where the logged-in user is the responsible or collaborating consultant.

#### Scenario: New activity on user's record
- **WHEN** activity is logged on a record where the user is the responsible or collaborating consultant
- **THEN** a Notification record is created for that user and the bell shows the new entry

#### Scenario: Bell shows unread count
- **WHEN** a user has unread notifications
- **THEN** the notification bell displays a badge with the count of unread notifications

#### Scenario: No unread notifications
- **WHEN** a user has no unread notifications
- **THEN** the notification bell is displayed without a count badge

### Requirement: Notification bell shows last 90 days
The notification bell SHALL show entries from the last 90 days only; older entries are not displayed in the bell dropdown.

#### Scenario: Activity older than 90 days
- **WHEN** a notification is older than 90 days
- **THEN** it no longer appears in the notification bell dropdown

#### Scenario: Activity within 90 days
- **WHEN** a notification is within the last 90 days
- **THEN** it appears in the notification bell dropdown

### Requirement: Mark notifications as read
Users SHALL be able to mark individual notifications as read, or mark all as read.

#### Scenario: Mark single notification as read
- **WHEN** a user clicks on a notification in the bell dropdown
- **THEN** that notification is marked as read and the unread count decreases

#### Scenario: Mark all as read
- **WHEN** a user clicks "Mark all as read" in the bell dropdown
- **THEN** all unread notifications for that user are marked as read and the badge is removed

### Requirement: Notification links to source record
Each notification in the bell dropdown SHALL link to the record that generated the activity.

#### Scenario: Click notification to navigate
- **WHEN** a user clicks a notification entry
- **THEN** they are navigated to the show page of the record that generated the activity log entry
