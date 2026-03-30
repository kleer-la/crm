## Purpose
Define the required description field on Proposal records, capturing detailed proposal content distinct from the short title identifier.

## Requirements

### Requirement: Proposal description field
The system SHALL require a non-empty `description` text field on every Proposal record. The description provides a detailed explanation of the proposal content, distinct from the short `title` identifier.

#### Scenario: Create a Proposal with a description
- **WHEN** a user creates a Proposal and provides a description
- **THEN** the system saves the description and associates it with the Proposal

#### Scenario: Attempt to create a Proposal without a description
- **WHEN** a user submits a new Proposal form with an empty description
- **THEN** the system rejects the save and displays a validation error requiring description

#### Scenario: Edit a Proposal's description
- **WHEN** a user updates the description of an existing Proposal and saves
- **THEN** the system persists the new description value

#### Scenario: Duplicate a Proposal copies the description
- **WHEN** a user duplicates an existing Proposal
- **THEN** the resulting draft Proposal has the same description as the original
