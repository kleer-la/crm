## ADDED Requirements

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
  - Resumen del cliente → notes (stored in a notes-like field or ignored)
  - All other columns (País facturador, País/es, Tipo de cliente, Estrategia (KARE), Próximo Contacto, Log contacto) → ignored

#### Scenario: All customers imported as active
- **WHEN** a customer CSV is imported
- **THEN** the system SHALL create all records as Customer with status "active" and date_became_customer set to today

#### Scenario: Customer contact requirement relaxed
- **WHEN** a customer is created via import without contact data
- **THEN** the system SHALL skip the contact validation and create the Customer without any Contact records

### Requirement: Proposal CSV column mapping
The system SHALL map proposal CSV columns to CRM fields using fixed rules.

#### Scenario: Proposal field mapping
- **WHEN** a proposal CSV is parsed
- **THEN** the system SHALL map columns as follows:
  - Propuesta → title (required)
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
  - All other columns (Equipo preventa, Origen de la oportunidad, Tipo de Servicio, Probabilidad de Venta, Clasificación, Fecha Últ. Contacto, Fecha último ping, Prox Contacto, País que Factura) → ignored

### Requirement: Proposal status mapping
The system SHALL map Spanish status values to CRM proposal statuses.

#### Scenario: Status value mapping
- **WHEN** a proposal CSV row has an Estado value
- **THEN** the system SHALL map it as follows:
  - BUN → draft
  - Entender → draft
  - Presupuestar → draft
  - Entregada/WIP → sent
  - Confirmado → under_review
  - Ganado → won
  - Perdido → lost
  - No por ahora → lost
  - Declinamos → cancelled
  - No contesta → lost

#### Scenario: Unknown status value
- **WHEN** a proposal CSV row has an Estado value not in the mapping
- **THEN** the system SHALL flag the row with a validation error

### Requirement: Contact extraction from proposals
The system SHALL extract contact information from the proposal Contacto column and associate it with the linked Customer.

#### Scenario: Contact with name and email
- **WHEN** a proposal row has Contacto in "Name <email>" format (e.g., "Lucila Sasías <lsasias@ute.com.uy>")
- **THEN** the system SHALL find or create a Contact on the linked Customer with the parsed name and email

#### Scenario: Contact with name only
- **WHEN** a proposal row has Contacto with just a name (no email)
- **THEN** the system SHALL find or create a Contact on the linked Customer with the name and no email

#### Scenario: Contact on non-Customer linkable
- **WHEN** a proposal is linked to a Prospect (not a Customer)
- **THEN** the system SHALL ignore the Contacto column (Prospects use inline contact fields)

### Requirement: Responsible consultant matching
The system SHALL match the Responsable/Responsables column to existing CRM users.

#### Scenario: Exact name match
- **WHEN** a CSV row has a Responsable value that matches an existing User's name
- **THEN** the system SHALL assign that User as responsible_consultant

#### Scenario: Partial name match
- **WHEN** a CSV row has a Responsable value that partially matches a User's name (e.g., "Andrés J" matches "Andrés Juárez")
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
- **THEN** the system SHALL display a warning that existing records should be cleared before importing (e.g., via rails console) and allow the admin to proceed or cancel

### Requirement: Import results display
The system SHALL display the outcome of each import attempt.

#### Scenario: Results after import
- **WHEN** an import completes
- **THEN** the system SHALL display the count of records created and failed (validation errors)

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
