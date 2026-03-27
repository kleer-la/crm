## Purpose
Import CRM data from fixed-format CSV spreadsheets, including users, customers, and proposals, with validation, preview, and deterministic field mapping.

## Requirements

### Requirement: Customer import maps company country
The system SHALL map the customer import spreadsheet column `País/es` to the optional `country` field on imported Customer records and SHALL continue to ignore `País facturador`.

#### Scenario: Import customer with country value
- **WHEN** an admin imports a customer row where `País/es` contains a value
- **THEN** the created Customer stores that value in `country`

#### Scenario: Import customer with blank country
- **WHEN** an admin imports a customer row where `País/es` is blank
- **THEN** the created Customer has no country value

#### Scenario: Billing country remains ignored
- **WHEN** an admin imports a customer row where `País facturador` contains a value
- **THEN** that value does not create or modify any CRM field