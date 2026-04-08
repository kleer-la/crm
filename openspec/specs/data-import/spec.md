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

### Requirement: Customer import routes rows to Customer or Prospect based on Tipo de cliente
The system SHALL read the `Tipo de cliente` column from the customer CSV and use its value to determine whether to create a Customer record (with the appropriate status) or skip the row with an actionable error.

The full mapping is:

| `Tipo de cliente` value             | Action                             |
|-------------------------------------|------------------------------------|
| `Potencial`                         | Skip — log prospect-required error |
| `Prospecto`                         | Skip — log prospect-required error |
| `Cliente activo`                    | Create Customer, status: `:active` |
| `Nuevo facturado`                   | Create Customer, status: `:active` |
| `Cliente inactivo por recuperar`    | Create Customer, status: `:inactive` |
| `Cliente recuperado`                | Create Customer, status: `:active` |
| `No contesta`                       | Create Customer, status: `:inactive` |
| `Descartar`                         | Create Customer, status: `:inactive` |

#### Scenario: Customer-type row uses mapped status
- **WHEN** an admin imports a customer CSV row where `Tipo de cliente` is `"Cliente activo"`
- **THEN** the created Customer has `status` equal to `:active`

#### Scenario: Inactive-type row uses inactive status
- **WHEN** an admin imports a customer CSV row where `Tipo de cliente` is `"No contesta"`
- **THEN** the created Customer has `status` equal to `:inactive`

#### Scenario: Prospect-type row is skipped with informative error
- **WHEN** an admin imports a customer CSV row where `Tipo de cliente` is `"Potencial"` or `"Prospecto"`
- **THEN** no record is created
- **AND** the import result includes a row-level error for that row number indicating that prospect-type records must be imported via the Prospects CSV import flow

#### Scenario: Unknown Tipo de cliente produces warning and nil status
- **WHEN** an admin imports a customer CSV row where `Tipo de cliente` contains a value not in the mapping
- **THEN** no record is created
- **AND** the import result includes a row-level warning identifying the unrecognised value

#### Scenario: Blank Tipo de cliente defaults to active
- **WHEN** an admin imports a customer CSV row where `Tipo de cliente` is blank
- **THEN** the created Customer has `status` equal to `:active` (existing default behaviour preserved)

### Requirement: Customer import maps Estrategia (KARE) to intention
The system SHALL read the `Estrategia (KARE)` column from the customer CSV and map it to the Customer `intention` field as follows:

| `Estrategia (KARE)` value | Customer `intention` |
|---------------------------|----------------------|
| `Mantener`                | `:keep`              |
| `Captar o atraer`         | `:attract`           |
| `Recuperar`               | `:recapture`         |
| `Expandir`                | `:expand`            |
| blank or unrecognised     | `nil`                |

#### Scenario: Import customer with keep strategy
- **WHEN** an admin imports a customer CSV row where `Estrategia (KARE)` is `"Mantener"`
- **THEN** the created Customer has `intention` equal to `:keep`

#### Scenario: Import customer with attract strategy
- **WHEN** an admin imports a customer CSV row where `Estrategia (KARE)` is `"Captar o atraer"`
- **THEN** the created Customer has `intention` equal to `:attract`

#### Scenario: Import customer with recapture strategy
- **WHEN** an admin imports a customer CSV row where `Estrategia (KARE)` is `"Recuperar"`
- **THEN** the created Customer has `intention` equal to `:recapture`

#### Scenario: Import customer with expand strategy
- **WHEN** an admin imports a customer CSV row where `Estrategia (KARE)` is `"Expandir"`
- **THEN** the created Customer has `intention` equal to `:expand`

#### Scenario: Blank KARE strategy leaves intention nil
- **WHEN** an admin imports a customer CSV row where `Estrategia (KARE)` is blank
- **THEN** the created Customer has `intention` equal to `nil`

#### Scenario: Unknown KARE strategy leaves intention nil
- **WHEN** an admin imports a customer CSV row where `Estrategia (KARE)` contains an unrecognised value
- **THEN** the created Customer has `intention` equal to `nil`
- **AND** no warning is added to the import result for this field (it is optional)

### Requirement: Proposal import maps extended Spanish status synonyms
The system SHALL map all of the following Spanish `Estado` values to the corresponding `Proposal` status on import, in addition to the existing mappings.

| Spanish value   | System status  |
|-----------------|----------------|
| `En espera`     | `under_review` |
| `Revisión`      | `under_review` |
| `Aprobado`      | `won`          |
| `Rechazado`     | `lost`         |
| `Cancelado`     | `cancelled`    |

#### Scenario: Import proposal with synonym "En espera"
- **WHEN** an admin imports a proposal CSV row where `Estado` is `"En espera"`
- **THEN** the parsed row has `status` equal to `"under_review"`

#### Scenario: Import proposal with synonym "Revisión"
- **WHEN** an admin imports a proposal CSV row where `Estado` is `"Revisión"`
- **THEN** the parsed row has `status` equal to `"under_review"`

#### Scenario: Import proposal with synonym "Aprobado"
- **WHEN** an admin imports a proposal CSV row where `Estado` is `"Aprobado"`
- **THEN** the parsed row has `status` equal to `"won"`

#### Scenario: Import proposal with synonym "Rechazado"
- **WHEN** an admin imports a proposal CSV row where `Estado` is `"Rechazado"`
- **THEN** the parsed row has `status` equal to `"lost"`

#### Scenario: Import proposal with synonym "Cancelado"
- **WHEN** an admin imports a proposal CSV row where `Estado` is `"Cancelado"`
- **THEN** the parsed row has `status` equal to `"cancelled"`

### Requirement: Proposal import warns on unknown status instead of failing
The system SHALL NOT raise a fatal error when a proposal CSV row contains an unrecognised `Estado` value. Instead it SHALL set the parsed row's `status` to `nil` and add a human-readable warning string to the row's `:warnings` array describing the unrecognised value.

**Note**: This requirement supersedes "Proposal import raises error for unknown status value". The previous hard-fail behaviour aborted entire imports when any single row had an unrecognised status. The new behaviour allows valid rows to be imported while still surfacing the problematic value to the admin.

#### Scenario: Unknown status yields nil and warning
- **WHEN** an admin imports a proposal CSV row where `Estado` contains a value not in the status mapping (e.g., `"Nuevo"`)
- **THEN** the parsed row has `status` equal to `nil`
- **AND** the parsed row's `:warnings` array includes a message identifying the unrecognised value (e.g., `"Unknown status 'Nuevo'"`)
- **AND** the import does not abort for other rows in the same file

#### Scenario: Row with nil status is reported as an error during execution
- **WHEN** the execution service processes a parsed proposal row that has `status` of `nil`
- **THEN** the row is not persisted to the database
- **AND** the import result's error list includes an entry for that row number indicating the status is blank

#### Scenario: Blank status still yields nil with no warning
- **WHEN** an admin imports a proposal CSV row where `Estado` is blank
- **THEN** the parsed row has `status` equal to `nil`
- **AND** the parsed row has no entries in `:warnings`

### Requirement: Admin-only access to imports
The import feature SHALL be accessible only to users with the admin role.

#### Scenario: Admin accesses import page
- **WHEN** an admin user navigates to the imports section
- **THEN** the system SHALL display the import interface with options for users, customers, and proposals

#### Scenario: Non-admin denied access
- **WHEN** a consultant user attempts to access the imports section
- **THEN** the system SHALL redirect them with an unauthorized error

### Requirement: CSV file upload with fixed Spanish-header templates
The system SHALL accept CSV file uploads matching the predefined Spanish-language column layouts for each record type.

#### Scenario: Valid customer CSV upload
- **WHEN** an admin uploads a CSV with headers: País facturador, País/es, Sector, Responsables, CLIENTE, Tipo de cliente, Estrategia (KARE), Último contacto, Próximo Contacto, Log contacto, Resumen del cliente
- **THEN** the system SHALL parse the file and proceed to validation/preview

#### Scenario: Valid proposal CSV upload
- **WHEN** an admin uploads a CSV with headers: Estado, Fecha del pedido, Cliente, Responsable, Equipo preventa, Contacto, Propuesta, Origen de la oportunidad, Tipo de Servicio, Probabilidad de Venta, $ Oportunidad, Clasificación, Fecha Últ. Contacto, Fecha último ping, Prox Contacto, Valor factura, Fecha de factura, País que Factura, Enlace Propuesta, Comentarios
- **THEN** the system SHALL parse the file and proceed to validation/preview

#### Scenario: CSV with missing required headers
- **WHEN** an admin uploads a CSV that is missing required headers (CLIENTE for customers; Propuesta, Cliente for proposals)
- **THEN** the system SHALL display an error listing the missing headers

#### Scenario: Invalid file type rejected
- **WHEN** an admin uploads a non-CSV file
- **THEN** the system SHALL reject the upload with an error message indicating only CSV files are accepted

#### Scenario: Empty CSV rejected
- **WHEN** an admin uploads a CSV file with no data rows
- **THEN** the system SHALL reject the upload with an error message

### Requirement: User CSV column mapping
The system SHALL import users (consultants/admins) from a simple CSV with name and email columns.

#### Scenario: Valid user CSV upload
- **WHEN** an admin uploads a CSV with headers: name, email, role
- **THEN** the system SHALL parse the file and proceed to validation/preview

#### Scenario: User field mapping
- **WHEN** a user CSV is parsed
- **THEN** the system SHALL map columns as follows:
  - name → name (required)
  - email → email (required)
  - role → role (optional, defaults to "consultant"; accepted values: consultant, admin)

#### Scenario: User created without Google OAuth
- **WHEN** a user is created via import
- **THEN** the system SHALL create the User with the given name, email, and role, without a google_uid. The OAuth login flow SHALL be updated to fall back to email matching when no google_uid match is found, linking the Google account to the imported user on first login.

#### Scenario: User with existing email skipped
- **WHEN** a user CSV row has an email that matches an existing User
- **THEN** the system SHALL skip that row (preserving the existing user) and note it in the results

### Requirement: Import order enforcement
The system SHALL guide the admin to import in the correct order: users first, then customers, then proposals.

#### Scenario: Import order guidance
- **WHEN** an admin visits the import page
- **THEN** the system SHALL display the recommended import order: 1) Users, 2) Customers, 3) Proposals

### Requirement: Customer CSV column mapping
The system SHALL map customer CSV columns to CRM fields using fixed rules.

#### Scenario: Customer field mapping
- **WHEN** a customer CSV is parsed
- **THEN** the system SHALL map columns as follows:
  - CLIENTE → company_name (required)
  - Sector → industry
  - Responsables → responsible_consultant (match User by name)
  - Último contacto → last_activity_date
  - Resumen del cliente → notes
  - All other columns (País facturador, País/es, Tipo de cliente, Estrategia (KARE), Próximo Contacto, Log contacto) → handled by dedicated requirements or ignored

#### Scenario: All customers imported as active (base default)
- **WHEN** a customer CSV is imported with no Tipo de cliente value
- **THEN** the system SHALL create the record as Customer with status "active" and date_became_customer set to today

#### Scenario: Customer contact requirement relaxed
- **WHEN** a customer is created via import without contact data
- **THEN** the system SHALL skip the contact validation and create the Customer without any Contact records

### Requirement: Proposal CSV column mapping
The system SHALL map proposal CSV columns to CRM fields using fixed rules.

#### Scenario: Proposal field mapping
- **WHEN** a proposal CSV is parsed
- **THEN** the system SHALL map columns as follows:
  - Propuesta → title and description (required)
  - Cliente → linkable_company_name (required, match to existing Customer or Prospect)
  - Responsable → responsible_consultant (match User by name)
  - Estado → status (mapped per status mapping table)
  - $ Oportunidad → estimated_value (strip $ and commas)
  - Enlace Propuesta → current_document_url
  - Comentarios → notes
  - Fecha del pedido → date_sent (parse YYYY/MM/DD)
  - Valor factura → final_value (strip $ and commas)
  - Fecha de factura → actual_close_date (parse YYYY/MM/DD)
  - Contacto → create or find Contact on the linked Customer (parse "Name <email>" format)
  - All other columns → ignored

### Requirement: Proposal status mapping
The system SHALL map Spanish status values to CRM proposal statuses.

#### Scenario: Status value mapping
- **WHEN** a proposal CSV row has an Estado value
- **THEN** the system SHALL map it as follows:
  - BUN → draft; Entender → draft; Presupuestar → draft
  - Entregada/WIP → sent
  - Confirmado → under_review; En espera → under_review; Revisión → under_review
  - Ganado → won; Aprobado → won
  - Perdido → lost; No por ahora → lost; No contesta → lost; Rechazado → lost
  - Declinamos → cancelled; Cancelado → cancelled

### Requirement: Contact extraction from proposals
The system SHALL extract contact information from the proposal Contacto column and associate it with the linked Customer.

#### Scenario: Contact with name and email
- **WHEN** a proposal row has Contacto in "Name <email>" format
- **THEN** the system SHALL find or create a Contact on the linked Customer with the parsed name and email

#### Scenario: Contact with name only
- **WHEN** a proposal row has Contacto with just a name (no email)
- **THEN** the system SHALL find or create a Contact on the linked Customer with the name and no email

#### Scenario: Contact on non-Customer linkable
- **WHEN** a proposal is linked to a Prospect
- **THEN** the system SHALL ignore the Contacto column

### Requirement: Responsible consultant matching
The system SHALL match the Responsable/Responsables column to existing CRM users.

#### Scenario: Exact name match
- **WHEN** a CSV row has a Responsable value that matches an existing User's name
- **THEN** the system SHALL assign that User as responsible_consultant

#### Scenario: Partial name match
- **WHEN** a CSV row has a Responsable value that partially matches a User's name
- **THEN** the system SHALL assign the best matching User

#### Scenario: No match found
- **WHEN** a CSV row has a Responsable value that does not match any User
- **THEN** the system SHALL assign the importing admin as responsible_consultant and note the unmatched name in the error log

### Requirement: Import preview with validation
The system SHALL validate all rows and display a preview before committing the import.

#### Scenario: Preview with valid rows
- **WHEN** an admin uploads a valid CSV
- **THEN** the system SHALL display a preview showing the number of records to be created and a summary

#### Scenario: Preview with validation errors
- **WHEN** a CSV contains rows that fail validation
- **THEN** the system SHALL display each error with the row number and specific failure, and allow the admin to proceed with valid rows only or cancel

#### Scenario: Existing data warning
- **WHEN** an admin starts an import and there are existing Customer or Proposal records in the database
- **THEN** the system SHALL display a warning that existing records should be cleared before importing and allow the admin to proceed or cancel

### Requirement: Import results display
The system SHALL display the outcome of each import attempt.

#### Scenario: Results after import
- **WHEN** an import completes
- **THEN** the system SHALL display the count of records created and failed

#### Scenario: Error details viewable
- **WHEN** an import has errors
- **THEN** the system SHALL display row numbers and failure reasons so the admin can correct the CSV and re-upload

### Requirement: Monetary value handling
The system SHALL correctly parse monetary values from CSV data.

#### Scenario: Various currency formats accepted
- **WHEN** a CSV contains monetary entries like "$2,500", "2500", "$1,234.56"
- **THEN** the system SHALL strip currency symbols and commas and store as decimal(12,2)

#### Scenario: Invalid monetary value rejected
- **WHEN** a CSV contains a non-numeric monetary value like "TBD"
- **THEN** the system SHALL flag the row with a validation error

### Requirement: Date parsing
The system SHALL parse dates in YYYY/MM/DD format from CSV data.

#### Scenario: Valid date parsed
- **WHEN** a CSV contains a date value like "2024/03/11"
- **THEN** the system SHALL parse it correctly as March 11, 2024

#### Scenario: Empty date accepted
- **WHEN** a CSV contains an empty date field
- **THEN** the system SHALL treat it as nil

#### Scenario: Invalid date flagged
- **WHEN** a CSV contains an unparseable date value
- **THEN** the system SHALL flag the row with a validation error
