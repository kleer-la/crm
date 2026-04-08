## Context

The CRM currently has no bulk data entry mechanism. The team has existing business data in two Spanish-language spreadsheets (customers and proposals) that needs to be migrated. This is a one-time import tool — it may take a few tries to get clean data in, but won't be used regularly after that.

The spreadsheet columns use Spanish headers and don't map 1:1 to CRM fields. Status values need translation (e.g., "Ganado"→won). Contact data for customers only exists in the proposals sheet (Contacto column), not the customers sheet. Customers will be imported without contacts initially; proposal import will populate contacts via the Contacto field.

## Goals / Non-Goals

**Goals:**
- Import users (consultants/admins) with name and email so they can be referenced as responsible consultants
- Import customers from the customers/prospects spreadsheet (all rows as Customers)
- Import proposals from the proposals spreadsheet, linking to existing Customers/Prospects
- Extract contacts from proposal Contacto column and attach to linked Customers
- Map Spanish status values to CRM proposal statuses
- Match Responsable names to existing CRM users
- Re-import workflow: admin wipes data via rails console, fixes CSV, re-imports
- Show clear error feedback so the admin can fix and re-upload

**Non-Goals:**
- Prospect import — no prospects in the current spreadsheet
- Column mapping UI — fixed templates matching existing spreadsheets
- Import history / persistent Import model — stateless, in-memory processing
- Background jobs — data is small enough for synchronous processing
- Duplicate detection or upsert logic — wipe-and-reimport is the strategy
- Excel (.xlsx) support — CSV export is fine
- Importing ignored columns (País, KARE strategy, Probabilidad, etc.)

## Decisions

### 1. Stateless request flow, no Import model

**Decision**: The import is processed entirely within a single request. No persistent Import record. CSV is parsed in memory, validated, and committed or rejected.

**Why**: One-time tool. Persisting import metadata adds complexity with no payoff.

### 2. Fixed Spanish-header templates

**Decision**: The parser expects the exact column headers from the existing spreadsheets. The admin exports their Google Sheet/Excel as CSV and uploads directly — no renaming needed.

**Why**: Zero friction for the user. The column names are known and fixed.

### 3. Two services: parser + executor

**Decision**:
- `CsvImportParserService` — reads CSV, validates headers, cleans values (monetary, dates, whitespace), returns normalized row hashes with mapped field names
- `CsvImportExecutionService` — validates rows against models, creates records, returns results

**Why**: Preview needs parsing without execution. Keeps each step testable.

### 4. Status mapping table

**Decision**: Hard-coded mapping from Spanish Estado values to CRM enum values:
- BUN, Entender, Presupuestar → draft
- Entregada/WIP → sent
- Confirmado → under_review
- Ganado → won
- Perdido, No por ahora, No contesta → lost
- Declinamos → cancelled

**Why**: Finite, known set of values. A future labels feature may add richer classification later.

### 5. Relaxed contact validation for customer import

**Decision**: Customer import skips the `must_have_at_least_one_contact` validation. Customers are created without contacts. Contacts are populated later when proposals are imported (from the Contacto column).

**Why**: The customers spreadsheet has no contact data. The proposals spreadsheet has contact info per proposal. Import order: customers first, then proposals.

**Implementation**: The execution service creates customers using `save(validate: false)` only for the contact validation, or uses a dedicated import context flag. All other validations (company_name presence/uniqueness, etc.) are still enforced.

### 6. Contact extraction from Contacto column

**Decision**: During proposal import, parse the Contacto field (format: "Name \<email\>") and find-or-create a Contact on the linked Customer. If only a name is present (no email), create with name only. If the proposal links to a Prospect, ignore Contacto.

**Why**: This is the only source of contact data. Find-or-create prevents duplicates when multiple proposals reference the same contact.

### 7. Consultant matching by name with fuzzy fallback

**Decision**: Match Responsable/Responsables to User records. Try exact match on `name` first, then partial match (ILIKE with the CSV value). If no match, assign the importing admin and log a warning.

**Why**: The spreadsheet uses short names ("Andrés J", "Pablo Lis") that may not exactly match CRM user names. Partial matching handles this. Falling back to admin prevents import failures for name mismatches.

### 8. User import with OAuth email-linking

**Decision**: Users are imported with name, email, and role (defaulting to consultant). They are created without a `google_uid`. The OAuth login flow in `SessionsController#create` is updated to fall back to email matching when no `google_uid` match is found — if a User with the same email exists, the `google_uid` is set on that user, linking the accounts.

**Why**: Users must exist before customers/proposals can reference them as `responsible_consultant`. Importing by email allows the OAuth flow to link accounts on first login without manual intervention.

**Implementation**: In `SessionsController#create`, after `User.find_or_initialize_by(google_uid: auth.uid)` returns a new record, check `User.find_by(email: auth.info.email)` before creating. If found, set `google_uid` on the existing user. Users with duplicate emails are skipped during import (preserving existing users).

### 9. Import order: users first, then customers, then proposals

**Decision**: The admin must import in order: 1) Users, 2) Customers, 3) Proposals. Users must exist for consultant matching. Customers must exist for proposal linkage.

**Why**: Each record type depends on the previous. The UI makes this order clear.

### 10. Synchronous processing

**Decision**: All imports run synchronously. No background jobs.

**Why**: Expected volume is hundreds of rows. Creating records through Active Record with callbacks takes seconds, not minutes.

## Risks / Trade-offs

**[Risk] Responsable name doesn't match any User** → Falls back to importing admin. Warning shown in results so admin can reassign manually.

**[Risk] Contacto format varies** → Parser handles "Name \<email\>" and plain name. Malformed entries are logged as warnings but don't block the row.

**[Risk] Customer created without contacts** → Acceptable: the `must_have_at_least_one_contact` validation only runs on update, not create. Proposal import will populate contacts. Admin can also add contacts manually.

**[Trade-off] Ignored columns** → Several columns (País, KARE, Probabilidad, Clasificación, Tipo de Servicio, etc.) are dropped. A future labels feature could capture some of this richness.

**[Trade-off] Wipe-and-reimport strategy** → Re-importing requires manually clearing data first (e.g., `Customer.destroy_all` via rails console). Simple and appropriate for a one-time migration tool. The UI warns if existing records are detected.
