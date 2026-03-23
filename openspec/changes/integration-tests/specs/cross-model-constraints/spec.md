## ADDED Requirements

### Requirement: Company name uniqueness across Prospects and Customers
A company_name SHALL be unique across both Prospects and Customers. Creating a Prospect with a company_name that matches an existing Customer (or vice versa) SHALL be rejected.

#### Scenario: Prospect with duplicate Customer company name
- **WHEN** a user creates a Prospect with a company_name that already exists as a Customer
- **THEN** the creation is rejected with a validation error

#### Scenario: Customer with duplicate Prospect company name
- **WHEN** a Prospect is converted to a Customer and another Prospect already has the same company_name as an existing Customer
- **THEN** the conversion is rejected with a validation error

### Requirement: Email uniqueness across Prospect contacts and Customer contacts
Primary contact email on Prospects SHALL be unique across Prospect primary_contact_email fields and Customer Contact email fields.

#### Scenario: Prospect with duplicate Customer contact email
- **WHEN** a user creates a Prospect with a primary_contact_email that matches an existing Customer Contact's email
- **THEN** the creation is rejected with a validation error

#### Scenario: Customer contact with duplicate Prospect email
- **WHEN** a user adds a Contact to a Customer with an email that matches an existing Prospect's primary_contact_email
- **THEN** the creation is rejected with a validation error

### Requirement: Converted Prospect is read-only
After a Prospect is converted to a Customer, the Prospect record SHALL be read-only. Updates to the converted Prospect SHALL be rejected.

#### Scenario: Edit converted Prospect
- **WHEN** a user attempts to update a Prospect that has been converted to a Customer
- **THEN** the update is rejected

#### Scenario: View converted Prospect
- **WHEN** a user views a converted Prospect
- **THEN** the Prospect details are displayed with a link to the converted Customer

### Requirement: Proposals re-linked after conversion
When a Prospect is converted to a Customer, all Proposals linked to that Prospect SHALL be re-linked to the new Customer.

#### Scenario: Proposals transferred on conversion
- **WHEN** a Prospect with linked Proposals is converted to a Customer
- **THEN** all Proposals previously linked to the Prospect are now linked to the new Customer
