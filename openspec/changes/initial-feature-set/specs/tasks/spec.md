## ADDED Requirements

### Requirement: Task record management
The system SHALL allow users to create Tasks linked to a Prospect, Customer, or Proposal with: title (required), linked record (required), assigned to (required), due date (required, cannot be past on creation), priority (Low|Medium|High, required), status (Open|In Progress|Done|Cancelled, required), cancellation reason (required when Cancelled), and notes.

#### Scenario: Create a task with valid due date
- **WHEN** a user creates a task with a due date of today or in the future
- **THEN** the system saves the task with status Open

#### Scenario: Create a task with past due date
- **WHEN** a user creates a task with a due date in the past
- **THEN** the system rejects the save and requires a valid due date

### Requirement: Mark task as Done
The system SHALL allow marking a task as Done, automatically recording a completion timestamp.

#### Scenario: Complete a task
- **WHEN** a user marks a task as Done
- **THEN** the system sets the status to Done and records the completion timestamp

### Requirement: Cancel a task with reason
The system SHALL require a non-empty cancellation reason when setting a task's status to Cancelled.

#### Scenario: Cancel with reason
- **WHEN** a user cancels a task and provides a reason
- **THEN** the system saves the status and records the reason

#### Scenario: Cancel without reason
- **WHEN** a user cancels a task without providing a reason
- **THEN** the system rejects the save and requires a reason

### Requirement: Overdue task flagging
The system SHALL visually flag overdue tasks (due date < today, status Open or In Progress) in all task list views.

#### Scenario: Overdue task displayed in list
- **WHEN** a task has a due date before today and status is Open or In Progress
- **THEN** the task is visually highlighted as overdue in all list views

#### Scenario: Non-overdue task displayed in list
- **WHEN** a task has a due date of today or later
- **THEN** the task is displayed normally without overdue highlighting

### Requirement: Reassign a task
The system SHALL allow users to change the assigned consultant on a task.

#### Scenario: Reassign a task
- **WHEN** a user changes the assigned consultant on a task
- **THEN** the system updates the assignment and creates an activity log entry on the linked record
