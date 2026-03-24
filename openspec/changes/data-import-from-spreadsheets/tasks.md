## 1. CSV Import Parser Service

- [x] 1.1 Create CsvImportParserService that accepts CSV content (string) and record_type (:user, :customer, or :proposal). Validates that required headers are present. Returns { headers:, rows: [] } with rows as hashes keyed by CRM field names.
- [x] 1.2 Define header-to-field mappings. User: name→name, email→email, role→role. Customer: CLIENTE→company_name, Sector→industry, Responsables→responsible_consultant_name, Último contacto→last_activity_date. Proposal: Propuesta→title, Cliente→linkable_company_name, Responsable→responsible_consultant_name, Estado→status_raw, $ Oportunidad→estimated_value, Enlace Propuesta→current_document_url, Comentarios→notes, Fecha del pedido→date_sent, Valor factura→final_value, Fecha de factura→actual_close_date, Contacto→contact_raw.
- [x] 1.3 Add value cleaning: strip whitespace, parse monetary values (strip $ and commas), parse dates (YYYY/MM/DD format), map Estado values to CRM statuses (BUN/Entender/Presupuestar→draft, Entregada/WIP→sent, Confirmado→under_review, Ganado→won, Perdido/No por ahora/No contesta→lost, Declinamos→cancelled).
- [x] 1.4 Add Contacto parsing: extract name and email from "Name <email>" format. Handle name-only (no angle brackets).
- [x] 1.5 Write tests: valid user CSV, valid customer CSV, valid proposal CSV, missing required headers, empty file, monetary cleanup, date parsing, status mapping, Contacto parsing edge cases, UTF-8 BOM handling.
- [x] 1.6 Run bin/ci to verify.

## 2. CSV Import Execution Service

- [x] 2.1 Create CsvImportExecutionService that accepts parsed rows, record_type, and the importing user. Returns { created_count:, skipped_count:, error_count:, errors: [{ row:, messages: }] }.
- [x] 2.2 Implement user import: create User with name, email, and role (default consultant). Skip rows where email matches an existing User (count as skipped, not error). No google_uid set — linked on first OAuth login.
- [x] 2.3 Implement consultant matching: match responsible_consultant_name to User by exact name first, then ILIKE partial match. Fall back to importing admin if no match, log warning.
- [x] 2.4 Implement customer import: create Customer with status "active", date_became_customer = today, matched responsible_consultant. Skip contact validation (customers sheet has no contact data). Log ActivityLog entry.
- [x] 2.5 Implement proposal import: match linkable_company_name to Customer first, then Prospect (case-insensitive). Map status. Set responsible_consultant. Skip unmatched linkables with error. Set win_loss_reason to "Imported" for won/lost proposals. Log ActivityLog entry.
- [x] 2.6 Implement contact extraction during proposal import: when linked to a Customer, find-or-create Contact from parsed Contacto data (name + email). Mark as primary if it's the customer's first contact. Skip for Prospect linkables.
- [x] 2.7 Write tests: user creation with email-duplicate skip, customer creation, proposal creation with linkable matching, consultant matching (exact, partial, fallback), contact extraction and find-or-create, validation error collection, ActivityLog entries.
- [x] 2.8 Run bin/ci to verify.

## 3. OAuth Email-Linking Fallback

- [x] 3.1 Update SessionsController#create to fall back to email matching when no google_uid match is found: after `User.find_or_initialize_by(google_uid: auth.uid)` returns a new record, check `User.find_by(email: auth.info.email)`. If found, set google_uid and update name/avatar on the existing user instead of creating a new one.
- [x] 3.2 Write tests: OAuth login links to existing imported user (no google_uid) by email; OAuth login still creates new user when no email match; existing OAuth flow unchanged for users with google_uid.
- [x] 3.3 Run bin/ci to verify.

## 4. Controller, Routes, and Views

- [x] 4.1 Create ImportsController with admin-only access. Actions: new (upload form with record type selector), preview (parse CSV + show validation results), create (execute confirmed import + show results).
- [x] 4.2 Add routes: resources :imports, only: [:new, :create] with a collection POST for preview.
- [x] 4.3 Create new import view: record type selector (users/customers/proposals), file upload input, note about import order (1. users, 2. customers, 3. proposals), submit button.
- [x] 4.4 Create preview view: summary of valid/error counts, warning if existing records detected (suggesting wipe via console before import), error details table (row number, field, error), confirm button to proceed with valid rows, cancel to go back. Use Turbo Frame for the preview step.
- [x] 4.5 Create results view: counts of created, skipped, and failed records. Error details if any. Link to re-import.
- [x] 4.6 Add navigation link to imports in the admin section of the sidebar/nav.
- [x] 4.7 Write controller tests: admin access, non-admin rejection, valid upload flow for all three types, invalid file type, missing headers, preview with errors, successful import.
- [x] 4.8 Run bin/ci to verify.

## 5. Integration Tests

- [ ] 5.1 Write integration test for full user import flow: upload CSV → preview → confirm → verify User records created, existing emails skipped.
- [ ] 5.2 Write integration test for full customer import flow: upload CSV → preview → confirm → verify Customer records created in database without contacts.
- [ ] 5.3 Write integration test for full proposal import flow: upload CSV → preview → confirm → verify Proposal records linked to existing Customers, contacts created from Contacto column.
- [ ] 5.4 Write integration test for error scenarios: unmatched proposal linkables, invalid status values, unmatched consultant names, existing data warning display.
- [ ] 5.5 Run bin/ci for final verification.
