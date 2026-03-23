## ADDED Requirements

### Requirement: Consistent flash message display
The application SHALL display flash messages with consistent styling: success/notice in green, alert/error in red. Flash messages SHALL auto-dismiss after 5 seconds.

#### Scenario: Success flash message
- **WHEN** a controller sets a flash[:notice] or flash[:success] message
- **THEN** a green-styled flash message is displayed at the top of the page and auto-dismisses after 5 seconds

#### Scenario: Error flash message
- **WHEN** a controller sets a flash[:alert] or flash[:error] message
- **THEN** a red-styled flash message is displayed at the top of the page and auto-dismisses after 5 seconds

#### Scenario: Manual dismiss
- **WHEN** a user clicks the dismiss button on a flash message
- **THEN** the flash message is immediately removed

### Requirement: Form error summary block
All forms SHALL display a summary of validation errors at the top of the form when submission fails.

#### Scenario: Form submitted with errors
- **WHEN** a form is submitted and validation fails
- **THEN** a red-bordered summary block at the top of the form lists all error messages

#### Scenario: Form submitted successfully
- **WHEN** a form is submitted and validation passes
- **THEN** no error summary block is displayed

### Requirement: Inline field error messages
Each form field with a validation error SHALL display the error message below the field input.

#### Scenario: Field with validation error
- **WHEN** a form is submitted and a specific field has a validation error
- **THEN** the error message is displayed in red text below that field's input and the field border is highlighted in red

#### Scenario: Field without error
- **WHEN** a form is submitted and a specific field passes validation
- **THEN** no error message is displayed below that field
