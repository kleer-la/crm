## ADDED Requirements

### Requirement: Modal task creation from entity show pages
The system SHALL open a centered modal dialog when the user clicks "New task" on a customer, prospect, or proposal show page. The modal SHALL lazy-load the task form via a Turbo Frame request to `/tasks/new` with the entity's `linkable_type` and `linkable_id` pre-set.

#### Scenario: Open modal from customer show page
- **WHEN** a user clicks "New task" on a customer show page
- **THEN** the system opens a centered modal dialog containing the task creation form pre-linked to that customer

#### Scenario: Open modal from prospect show page
- **WHEN** a user clicks "New task" on a prospect show page
- **THEN** the system opens a centered modal dialog containing the task creation form pre-linked to that prospect

#### Scenario: Open modal from proposal show page
- **WHEN** a user clicks "New task" on a proposal show page
- **THEN** the system opens a centered modal dialog containing the task creation form pre-linked to that proposal

### Requirement: Task form inside modal hides linkable selector
The system SHALL hide the "Linked to" type/record selectors when `linkable_type` and `linkable_id` are pre-set, since the entity is already known.

#### Scenario: Linkable pre-set from show page
- **WHEN** the task form is opened from an entity show page
- **THEN** the form does not display the linkable type or linkable record selectors

### Requirement: Successful task creation closes modal and refreshes tasks list
The system SHALL, upon successful task creation from the modal, close the modal and update the tasks section on the originating show page in-place without a full page reload.

#### Scenario: Task created successfully from modal
- **WHEN** a user submits a valid task form from the modal
- **THEN** the modal closes and the tasks section on the show page updates to include the new task

### Requirement: Validation errors re-render form inside modal
The system SHALL re-render the task form inside the modal when validation fails, displaying error messages without navigating away.

#### Scenario: Task form submitted with validation errors
- **WHEN** a user submits the task form with missing or invalid fields
- **THEN** the modal remains open and displays validation error messages inline

### Requirement: Modal dismissal
The system SHALL allow the user to dismiss the modal without creating a task by pressing ESC or clicking the backdrop outside the dialog content.

#### Scenario: Dismiss modal with ESC key
- **WHEN** a user presses ESC while the modal is open
- **THEN** the modal closes and no task is created

#### Scenario: Dismiss modal by clicking backdrop
- **WHEN** a user clicks outside the dialog content area while the modal is open
- **THEN** the modal closes and no task is created

### Requirement: Tasks/index unaffected
The system SHALL keep the "New task" button on the tasks index page as a full-page navigation to `/tasks/new`, unaffected by this change.

#### Scenario: New task from tasks index
- **WHEN** a user clicks "New task" on the tasks index page
- **THEN** the system navigates to the full-page task creation form
