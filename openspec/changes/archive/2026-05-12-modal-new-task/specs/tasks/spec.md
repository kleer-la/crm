## MODIFIED Requirements

### Requirement: Tasks section on entity show pages supports in-place refresh
The tasks section displayed on customer, prospect, and proposal show pages SHALL be wrapped in a Turbo Frame with a predictable DOM ID (`tasks_<type>_<id>`) so it can be replaced in-place by Turbo Stream responses.

#### Scenario: Tasks section refreshes after modal creation
- **WHEN** a task is successfully created via the modal
- **THEN** the tasks section on the originating show page is replaced in-place showing the updated task list including the new task
