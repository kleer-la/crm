## MODIFIED Requirements

### Requirement: Proposal record management
The system SHALL allow users to create and edit Proposal records with: title (required), description (required), linked company (Prospect or Customer reference, required), responsible consultant (required), collaborating consultants (multi-select), status (Draft|Sent|Under Review|Won|Lost|Cancelled, required), estimated value (USD), date created (auto-set), date sent (auto-set when status moves to Sent, editable), expected close date, actual close date (auto-set on Won/Lost/Cancelled, editable), win/loss reason (required for Won/Lost), notes, current document link (URL), and document version history.

#### Scenario: Create a Proposal from a Customer record
- **WHEN** a user creates a Proposal from a Customer's detail page
- **THEN** the Proposal is linked to that Customer with date created set to today

#### Scenario: Create a Proposal from the Proposals list
- **WHEN** a user creates a Proposal directly from the Proposals list view
- **THEN** the user must select a Prospect or Customer to link it to

## ADDED Requirements

### Requirement: CSV import populates Proposal description from Propuesta column
The system SHALL populate the `description` field on imported Proposal records using the value from the "Propuesta" CSV column, in addition to the existing `title` field.

#### Scenario: Import a Proposal CSV with a Propuesta column
- **WHEN** a user imports a proposals CSV containing a "Propuesta" column
- **THEN** each imported Proposal has both its `title` and `description` set to the value of that column

#### Scenario: Import a Proposal CSV missing the Propuesta column
- **WHEN** a user imports a proposals CSV without the required "Propuesta" header
- **THEN** the system rejects the import with a missing required headers error
