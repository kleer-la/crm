## ADDED Requirements

### Requirement: Prospect record management
The system SHALL allow users to create and edit Prospect records with the following fields: company name (required, unique across Prospects and Customers), primary contact name (required), primary contact email (required, unique across Prospects and Customers), primary contact phone, industry/sector, source (Referral|Inbound|Outbound|Event|Other), responsible consultant (required), collaborating consultants (multi-select), status (New|Contacted|Qualified|Disqualified, required), estimated potential value (USD), date added (auto-set), and last activity date (auto-updated).

#### Scenario: Create a new Prospect
- **WHEN** a user submits a new Prospect form with all required fields
- **THEN** the system creates the record with date added set to today and last activity date set to today

#### Scenario: Duplicate company name
- **WHEN** a user creates or edits a Prospect with a company name that already exists on another Prospect or Customer
- **THEN** the system rejects the save and displays a uniqueness error

#### Scenario: Duplicate primary contact email
- **WHEN** a user creates or edits a Prospect with an email that already exists on another Prospect or Customer contact
- **THEN** the system rejects the save and displays a uniqueness error

### Requirement: Disqualify a Prospect
The system SHALL require a non-empty disqualification reason when setting a Prospect's status to Disqualified.

#### Scenario: Disqualify with reason
- **WHEN** a user sets a Prospect's status to Disqualified and provides a reason
- **THEN** the system saves the status change and records the reason

#### Scenario: Disqualify without reason
- **WHEN** a user sets a Prospect's status to Disqualified without providing a reason
- **THEN** the system rejects the save and requires a reason

### Requirement: Convert Prospect to Customer
The system SHALL allow converting a Prospect to a Customer. Conversion creates a new Customer record pre-populated from the Prospect's data, re-links all associated Proposals to the new Customer, marks the Prospect as Converted and read-only, and stores a reference to the resulting Customer.

#### Scenario: Successful conversion
- **WHEN** a user converts a Prospect with status New, Contacted, or Qualified
- **THEN** a Customer record is created with the Prospect's data, all linked Proposals are re-linked to the Customer, and the Prospect becomes read-only with a link to the Customer

#### Scenario: Convert a Disqualified Prospect
- **WHEN** a user attempts to convert a Prospect with status Disqualified
- **THEN** the system prevents the conversion and requires the status to be changed first

#### Scenario: Edit a converted Prospect
- **WHEN** a user attempts to edit a Prospect that has been converted
- **THEN** the system prevents the edit and the record remains read-only

### Requirement: Log touchpoints on Prospects
The system SHALL allow users to log touchpoints (Call, Email, Meeting, Note) on a Prospect record, which updates the last activity date.

#### Scenario: Log a touchpoint
- **WHEN** a user logs a touchpoint with a type and description on a Prospect
- **THEN** the system creates an activity log entry and updates the Prospect's last activity date

### Requirement: Reassign Prospect consultants
The system SHALL allow users to change the responsible consultant or add/remove collaborating consultants on a Prospect.

#### Scenario: Reassign responsible consultant
- **WHEN** a user changes the responsible consultant on a Prospect
- **THEN** the system updates the assignment and creates an activity log entry
