## MODIFIED Requirements

### Requirement: Customer record management
The system SHALL allow users to create and edit Customer records with: company name (required, unique across Prospects and Customers), industry/sector, country, contacts (at least one required), responsible consultant (required), collaborating consultants (multi-select), status (Active|Inactive|At Risk, required), total revenue to date (auto-calculated from Won proposals, read-only), date became a customer (auto-set on conversion, editable on manual creation), and last activity date (auto-updated).

#### Scenario: Create a Customer manually
- **WHEN** a user submits a new Customer form with all required fields including at least one contact
- **THEN** the system creates the record with date became a customer set to the provided date and saves the optional country when present

#### Scenario: Customer created via Prospect conversion
- **WHEN** a Prospect is converted to a Customer
- **THEN** the Customer record is pre-populated from the Prospect data, including country, with date became a customer set to today