## Purpose
Manage Proposal records through their lifecycle including status workflow with win or loss reasons, document link management with version history, and duplication.

## Requirements

### Requirement: Proposal record management
The system SHALL allow users to create and edit Proposal records with: title (required), description (required), linked company (Prospect or Customer reference, required), responsible consultant (required), collaborating consultants (multi-select), status (Draft|Sent|Under Review|Won|Lost|Cancelled, required), estimated value (USD), date created (auto-set), date sent (auto-set when status moves to Sent, editable), expected close date, actual close date (auto-set on Won/Lost/Cancelled, editable), win/loss reason (required for Won/Lost), notes, current document link (URL), and document version history.

#### Scenario: Create a Proposal from a Customer record
- **WHEN** a user creates a Proposal from a Customer's detail page
- **THEN** the Proposal is linked to that Customer with date created set to today

#### Scenario: Create a Proposal from the Proposals list
- **WHEN** a user creates a Proposal directly from the Proposals list view
- **THEN** the user must select a Prospect or Customer to link it to

### Requirement: Proposal status workflow with win/loss reasons
The system SHALL require a non-empty win/loss reason when setting status to Won or Lost.

#### Scenario: Mark Proposal as Won with reason
- **WHEN** a user sets a Proposal's status to Won and provides a reason
- **THEN** the system saves the status, records the reason, sets actual close date to today, and recalculates the linked Customer's revenue (based on estimated_value)

#### Scenario: Mark Proposal as Won without reason
- **WHEN** a user sets a Proposal's status to Won without providing a reason
- **THEN** the system rejects the save and requires a reason

#### Scenario: Mark Proposal as Lost with reason
- **WHEN** a user sets a Proposal's status to Lost and provides a reason
- **THEN** the system saves the status, records the reason, and sets actual close date to today

### Requirement: Won Proposal linked to unconverted Prospect triggers alert
The system SHALL create a pending-conversion alert in the team alert widget when a Proposal is marked Won and the linked Prospect has not been converted to a Customer.

#### Scenario: Won Proposal with unconverted Prospect
- **WHEN** a Proposal linked to a Prospect is marked as Won
- **THEN** the user is prompted to convert the Prospect; if skipped, a pending-conversion alert appears in the team alert widget

#### Scenario: Prospect converted after Won Proposal
- **WHEN** a Prospect with a pending-conversion alert is converted to a Customer
- **THEN** the pending-conversion alert is resolved and disappears from the widget

### Requirement: Proposal linked to Disqualified Prospect cannot be Won
The system SHALL prevent moving a Proposal to Won status if it is linked to a Disqualified Prospect.

#### Scenario: Attempt to Win a Proposal linked to Disqualified Prospect
- **WHEN** a user attempts to set a Proposal to Won and the linked Prospect is Disqualified
- **THEN** the system rejects the change and instructs the user to change the Prospect's status first

### Requirement: Document link management
The system SHALL allow users to set or replace the current Google Drive document link (validated as a well-formed URL). When replacing an existing link, the system SHALL prompt the user to optionally archive the previous link.

#### Scenario: Set document link on Proposal with no existing link
- **WHEN** a user sets the current document link on a Proposal that has no existing link
- **THEN** the system validates the URL and saves it

#### Scenario: Replace existing document link
- **WHEN** a user replaces the current document link and a previous link exists
- **THEN** the system prompts the user to optionally archive the old link before saving the new one

#### Scenario: Invalid URL submitted
- **WHEN** a user submits a malformed URL as the document link
- **THEN** the system rejects the save and displays a validation error

### Requirement: Document version history
The system SHALL allow users to archive the current document link to the version history with a label, date, and the archiving user's name. Version history entries SHALL be immutable.

#### Scenario: Archive a document version
- **WHEN** a user archives the current document link with a label
- **THEN** the entry is saved to the version history with the label, current date, and the user's name

#### Scenario: Attempt to edit a version history entry
- **WHEN** any user attempts to modify a version history entry
- **THEN** the system prevents the modification

### Requirement: Duplicate a Proposal
The system SHALL allow duplicating a Proposal, creating a new Draft copying all fields except status, dates, and document links.

#### Scenario: Duplicate a Proposal
- **WHEN** a user duplicates an existing Proposal
- **THEN** a new Proposal is created in Draft status with the same title, linked company, consultants, estimated value, and notes, but with fresh dates and no document links

### Requirement: CSV import populates Proposal description from Propuesta column
The system SHALL populate the `description` field on imported Proposal records using the value from the "Propuesta" CSV column, in addition to the existing `title` field.

#### Scenario: Import a Proposal CSV with a Propuesta column
- **WHEN** a user imports a proposals CSV containing a "Propuesta" column
- **THEN** each imported Proposal has both its `title` and `description` set to the value of that column

#### Scenario: Import a Proposal CSV missing the Propuesta column
- **WHEN** a user imports a proposals CSV without the required "Propuesta" header
- **THEN** the system rejects the import with a missing required headers error

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
