## Purpose
Manage Customer records including contact management, auto-calculated revenue from Won proposals, and full history of linked Proposals, Tasks, and activity.

## Requirements

### Requirement: Customer record management
The system SHALL allow users to create and edit Customer records with: company name (required, unique across Prospects and Customers), industry/sector, contacts (at least one required), responsible consultant (required), collaborating consultants (multi-select), status (Active|Inactive|At Risk, required), total revenue to date (auto-calculated from Won proposals, read-only), date became a customer (auto-set on conversion, editable on manual creation), and last activity date (auto-updated).

#### Scenario: Create a Customer manually
- **WHEN** a user submits a new Customer form with all required fields including at least one contact
- **THEN** the system creates the record with date became a customer set to the provided date

#### Scenario: Customer created via Prospect conversion
- **WHEN** a Prospect is converted to a Customer
- **THEN** the Customer record is pre-populated from the Prospect data with date became a customer set to today

### Requirement: Contact management
Each Customer SHALL have a list of contacts with fields: name, email, phone, role/title, and primary flag. Exactly one contact MUST be flagged as primary at all times.

#### Scenario: Add a contact
- **WHEN** a user adds a new contact to a Customer
- **THEN** the contact is saved and if it is the only contact, it is automatically flagged as primary

#### Scenario: Remove the last contact
- **WHEN** a user attempts to remove the only remaining contact on a Customer
- **THEN** the system prevents the deletion

#### Scenario: Change primary contact
- **WHEN** a user flags a different contact as primary
- **THEN** the previous primary flag is removed and exactly one contact remains primary

### Requirement: Auto-calculated total revenue
The system SHALL automatically calculate total revenue to date as the sum of final values from all Won proposals linked to the Customer. This field SHALL be read-only.

#### Scenario: Proposal marked as Won
- **WHEN** a Proposal linked to a Customer is marked as Won with a final value
- **THEN** the Customer's total revenue to date is recalculated to include the new amount

#### Scenario: Won Proposal status changed
- **WHEN** a Won Proposal's status is changed away from Won
- **THEN** the Customer's total revenue to date is recalculated to exclude that amount

### Requirement: Customer full history view
The system SHALL display all linked Proposals, Tasks, and activity log entries for a Customer in a single chronological timeline on the detail page.

#### Scenario: View Customer history
- **WHEN** a user opens a Customer detail page
- **THEN** all related Proposals, Tasks, and activity entries are displayed in chronological order

### Requirement: Log touchpoints on Customers
The system SHALL allow users to log touchpoints (Call, Email, Meeting, Note) on a Customer record, updating the last activity date.

#### Scenario: Log a touchpoint on a Customer
- **WHEN** a user logs a touchpoint with a type and description on a Customer
- **THEN** the system creates an activity log entry and updates the Customer's last activity date
