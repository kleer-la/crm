## Why

The customer CSV spreadsheet contains two unmapped columns — `Tipo de cliente` and `Estrategia (KARE)` — that carry important CRM data: whether a row should become a Prospect or Customer (and at what status), and each account's strategic intent from the KARE framework. Separately, the proposal `Estado` (status) column raises a fatal parse error when it encounters unknown Spanish values, aborting the whole import. This change wires up all three gaps in one pass.

## What Changes

- **Customer type routing**: Map the `Tipo de cliente` column to determine the record type and status on import. Values indicating pre-sales accounts (`Potencial`, `Prospecto`) are flagged as "import as Prospect" — since contact data is unavailable in the customer CSV, those rows are skipped with an informative per-row error directing the admin to the Prospects import flow. Customer-type values map to a Customer `status` (`:active` or `:inactive`).
- **Customer intention field**: Add a new optional `intention` enum to the `Customer` model (`:keep`, `:attract`, `:recapture`, `:expand`) and map the `Estrategia (KARE)` column to it on import. Unknown or blank KARE values default to `nil` (nullable field).
- **Proposal status soft-warn**: Extend `STATUS_MAPPING` with additional Spanish synonyms and replace the hard-fail on unknown values with a row-level warning that surfaces the unrecognised string to the admin without aborting the whole import.

## Capabilities

### New Capabilities

_(none — all changes are to existing import behaviour)_

### Modified Capabilities

- `data-import`: Requirements change for (a) how customer rows are routed to Prospect vs Customer records and with which status, (b) the new `intention` field populated from `Estrategia (KARE)`, and (c) how unknown proposal status values are handled (warn instead of fatal error, with extended mapping).

## Impact

- `db/migrate/` — new migration adding `intention` integer column to `customers`
- `app/models/customer.rb` — add `intention` enum
- `app/services/csv_import_parser_service.rb` — `HEADER_MAPPINGS[:customer]`, new `CUSTOMER_TYPE_MAPPING`, `CUSTOMER_INTENTION_MAPPING`, extended `STATUS_MAPPING`, updated `clean_values!`
- `app/services/csv_import_execution_service.rb` — `import_customer` method to handle type routing and intention field
- `test/services/csv_import_parser_service_test.rb` — customer type and intention mapping tests
- `test/services/csv_import_execution_service_test.rb` — customer routing and intention field tests
