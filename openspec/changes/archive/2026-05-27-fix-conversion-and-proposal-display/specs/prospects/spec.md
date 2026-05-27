## MODIFIED Requirements

### Requirement: Convert Prospect to Customer

The system SHALL allow converting a Prospect to a Customer. Conversion creates a new Customer record pre-populated from the Prospect's data, including country, re-links all associated Proposals to the new Customer, creates a Contact from the Prospect's primary contact fields, copies all collaborating consultants to the new Customer, marks the Prospect as Converted and read-only, and stores a reference to the resulting Customer.

#### Scenario: Successful conversion with contact and consultant copy
- **WHEN** a user converts a Prospect with status New, Contacted, or Qualified that has a primary contact name, email, and collaborating consultants assigned
- **THEN** a Customer record is created with the Prospect's data, a Contact is created from the Prospect's primary contact name/email/phone (marked primary), collaborating consultants are copied to the Customer, all linked Proposals are re-linked to the Customer, and the Prospect becomes read-only with a link to the Customer

#### Scenario: Successful conversion without collaborating consultants
- **WHEN** a user converts a Prospect that has no collaborating consultants assigned
- **THEN** the Customer is created with only the responsible consultant and no collaborating consultants

#### Scenario: Convert a Disqualified Prospect
- **WHEN** a user attempts to convert a Prospect with status Disqualified
- **THEN** the system prevents the conversion and requires the status to be changed first

#### Scenario: Edit a converted Prospect
- **WHEN** a user attempts to edit a Prospect that has been converted
- **THEN** the system prevents the edit and the record remains read-only
