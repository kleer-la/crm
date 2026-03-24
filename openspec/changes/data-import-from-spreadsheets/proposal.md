## Why

The team needs to seed the CRM with existing business data currently tracked in spreadsheets. Without a bulk import capability, consultants would need to manually enter hundreds of customers and proposals one by one — a tedious, error-prone process that blocks CRM adoption.

## What Changes

- Add a one-time data import feature accessible to admin users
- Support CSV file uploads for three record types: users (consultants), customers, and proposals
- Use fixed column layouts matching the existing spreadsheets (Spanish headers)
- Map spreadsheet "Estado" values to CRM proposal statuses (e.g., Ganado→won, Perdido→lost)
- Validate imported data against model rules, relaxing contact requirements for customers (contacts will be added later)
- Extract contact info from proposal rows (Contacto column) to populate Customer contacts
- Show a preview with error details so admins can fix their CSV and re-upload
- Re-import workflow: wipe existing data (via rails console), fix CSV, re-import — no duplicate detection needed

## Capabilities

### New Capabilities
- `data-import`: One-time bulk CSV import for users, customers, and proposals with fixed templates, status mapping, validation, preview, and error reporting

### Modified Capabilities
<!-- No existing spec requirements are changing — imports use existing model validations as-is -->

## Impact

- **New service layer**: Import parsing, validation, and execution services
- **Controllers**: New `ImportsController` with admin-only access
- **Views**: Simple upload page with record type selector, preview/errors display, and confirmation
- **Dependencies**: Ruby's built-in `csv` library (no new gems needed)
- **Existing models**: No schema changes — imports create records through existing model layer, with relaxed contact validation during import
