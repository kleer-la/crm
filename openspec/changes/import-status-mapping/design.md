## Context

The customer CSV spreadsheet has always contained two columns not wired into the import pipeline: `Tipo de cliente` (account lifecycle stage) and `Estrategia (KARE)` (strategic intent). A third gap exists on the proposal side: `CsvImportParserService` raises a fatal `ParseError` on any unknown `Estado` value, aborting the entire import file.

This change wires up all three in one pass. The Customer model needs a new `intention` column; the parser needs two new mapping tables for customer rows; and the proposal path needs its error handling changed from hard-fail to soft-warn.

## Goals / Non-Goals

**Goals:**
- Map `Tipo de cliente` to import routing (Prospect vs Customer) and Customer `status`.
- Add `intention` enum to `Customer` and populate it from `Estrategia (KARE)` on import.
- Extend the proposal `STATUS_MAPPING` with known synonyms and replace hard-fail on unknown values with a row-level warning.
- Surface unrecognised values (customer type, KARE strategy, proposal status) to the admin in the import result without aborting the run.

**Non-Goals:**
- Dynamic or UI-configurable mapping tables.
- Creating Prospect records from the customer CSV (contact data is unavailable — see Decision 2).
- Changing the six canonical `Proposal` statuses or the three `Customer` statuses.
- Parsing additional customer CSV columns beyond the two new ones.

## Decisions

### Decision 1: Two new constants for customer mapping

**Chosen**: Add `CUSTOMER_TYPE_MAPPING` and `CUSTOMER_INTENTION_MAPPING` as frozen hashes in `CsvImportParserService`, parallel to the existing `STATUS_MAPPING`.

```ruby
CUSTOMER_TYPE_MAPPING = {
  "Potencial"                        => :prospect,
  "Prospecto"                        => :prospect,
  "Cliente activo"                   => :active,
  "Nuevo facturado"                  => :active,
  "Cliente inactivo por recuperar"   => :inactive,
  "Cliente recuperado"               => :active,
  "No contesta"                      => :inactive,
  "Descartar"                        => :inactive
}.freeze

CUSTOMER_INTENTION_MAPPING = {
  "Mantener"       => :keep,
  "Captar o atraer" => :attract,
  "Recuperar"      => :recapture,
  "Expandir"       => :expand
}.freeze
```

**Rationale**: Keeps the mapping logic visible and reviewable at the constant level, consistent with how `STATUS_MAPPING` is handled for proposals.

### Decision 2: Prospect-type rows from the customer CSV are skipped with a row error

**Chosen**: When `Tipo de cliente` maps to `:prospect`, the execution service logs a per-row error — e.g. `"Row 3: 'Potencial' accounts must be imported via the Prospects CSV (contact data required)"` — and skips creation.

**Rationale**: The customer CSV does not include `primary_contact_name` or `primary_contact_email`, both of which are mandatory on `Prospect`. Creating a Prospect with fabricated placeholder data would produce corrupt records; bypassing validations (`save(validate: false)`) violates the domain rule that each Prospect must have a primary contact. Surfacing the skip as a named, actionable error is the safest path for a small-team admin.

**Alternative considered**: Default contact fields to blank/placeholder strings. Rejected because it produces invalid data that could silently propagate.

### Decision 3: `intention` is a nullable enum on `Customer`

**Chosen**: Add `intention` as an integer-backed enum with `nil` as the default (column `null: true`). Values: `keep: 0`, `attract: 1`, `recapture: 2`, `expand: 3`. Blank or unrecognised KARE values produce `nil` with no warning (optional field).

**Rationale**: Not all customers have a KARE strategy assigned; forcing presence would break existing records. Unknown KARE strings silently default to `nil` rather than warning, because the field is optional and an unknown value is indistinguishable from "not yet assigned".

**Alternative considered**: Warn on unknown KARE strings (same as proposal status). Rejected because the field is optional — there's nothing actionable for the admin.

### Decision 4: Soft-warn for unknown proposal `Estado` values (unchanged from initial proposal)

**Chosen**: Return `nil` for status and add the raw value to `row[:warnings]`. Unknown values do not abort the import; row validation fails in the execution service, producing a row error.

### Decision 5: `Tipo de cliente` column added to `HEADER_MAPPINGS[:customer]`

**Chosen**: Map `"Tipo de cliente"` → `:customer_type_raw` and `"Estrategia (KARE)"` → `:intention_raw`. `clean_values!` processes both into their final fields.

**Rationale**: Consistent with how `:status_raw` and `:contact_raw` are handled for proposals.

## Risks / Trade-offs

- **Prospect-type rows silently skipped from bulk import** → Mitigation: Each skipped row produces a named error in the result; the admin sees exactly which rows need the Prospects CSV import.
- **New `intention` column migration on `customers` table** → Mitigation: Column is nullable with no default requirement; zero-downtime addition, existing rows get `nil`.
- **`CUSTOMER_TYPE_MAPPING` unknown values** → Design choice: unrecognised `Tipo de cliente` strings log a row-level warning (same pattern as proposal status), not a hard fail.

