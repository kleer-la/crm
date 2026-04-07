## Purpose
Provide reusable quick reply templates for conversations and automatic disconnection of idle conversations.

## Requirements

### Requirement: Manage canned responses
Admins SHALL be able to create, edit, reorder, and delete canned responses. Each canned response has a name, content, and display position. System canned responses (identified by a key) cannot be created via the UI.

#### Scenario: Create a canned response
- **WHEN** an admin submits the new canned response form with a name and content
- **THEN** the system creates the canned response and redirects to the index with a success notice

#### Scenario: Create with missing fields
- **WHEN** an admin submits the form without a name or content
- **THEN** the system re-renders the form with validation errors

#### Scenario: Edit a canned response
- **WHEN** an admin updates an existing canned response
- **THEN** the system saves the changes and redirects to the index

#### Scenario: Delete a canned response
- **WHEN** an admin deletes a canned response
- **THEN** the system removes it and redirects to the index

### Requirement: Quick replies in reply composer
The reply composer SHALL display a "Quick replies" button when canned responses exist. Clicking the button shows a dropdown of available canned responses ordered by position. Selecting a canned response fills the message textarea with its content.

#### Scenario: Select a quick reply
- **WHEN** a user clicks a canned response from the dropdown
- **THEN** the textarea is filled with the canned response content, the dropdown closes, and the textarea is focused

#### Scenario: No canned responses
- **WHEN** no canned responses exist in the database
- **THEN** the quick replies button is not shown

#### Scenario: Close dropdown on outside click
- **WHEN** the quick replies dropdown is open and the user clicks outside of it
- **THEN** the dropdown closes

### Requirement: Clear message after send
The reply composer SHALL clear the message input and file attachment after a successful message submission, preventing accidental double-sends.

#### Scenario: Successful message send
- **WHEN** a user sends a message (via button or Enter key) and the server responds successfully
- **THEN** the textarea is cleared, resized to default height, and any file preview is removed

### Requirement: Auto-disconnect idle conversations
The system SHALL run a recurring background job that sends an auto-disconnect message to open conversations with no recent activity. The disconnect message content is sourced from the canned response with key "auto_disconnect".

#### Scenario: Auto-disconnect triggered
- **WHEN** the auto-disconnect job runs and finds open conversations past the idle threshold
- **THEN** it sends the auto-disconnect message as an outbound message in each idle conversation
