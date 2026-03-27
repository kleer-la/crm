## 1. Database — Add intention Column to Customers

- [x] 1.1 Generate migration: `add_column :customers, :intention, :integer` (null: true, no default)
- [x] 1.2 Run `bin/rails db:migrate` and verify `db/schema.rb` reflects the new column
- [x] 1.3 Add `intention` enum to `Customer` model: `enum :intention, { keep: 0, attract: 1, recapture: 2, expand: 3 }`
- [x] 1.4 Add model test asserting the four intention enum values are valid and `nil` is permitted

## 2. Parser — Customer Type and Intention Mapping

- [x] 2.1 Add `"Tipo de cliente"` → `:customer_type_raw` and `"Estrategia (KARE)"` → `:intention_raw` to `HEADER_MAPPINGS[:customer]` in `CsvImportParserService`
- [x] 2.2 Add `CUSTOMER_TYPE_MAPPING` constant with the eight Spanish → symbol entries (`:prospect` or Customer status symbol)
- [x] 2.3 Add `CUSTOMER_INTENTION_MAPPING` constant mapping the four KARE values to intention symbols
- [x] 2.4 Update `clean_values!` to process `:customer_type_raw` into `:customer_type` and `:intention_raw` into `:intention` using the new constants; unknown KARE strings silently become `nil`; unknown customer type strings add a warning to `row[:warnings]`
- [x] 2.5 Ensure blank `Tipo de cliente` leaves `:customer_type` as `nil` (execution service will default to `:active`)

## 3. Parser — Proposal Status Soft-Warn

- [x] 3.1 Add `"En espera"`, `"Revisión"`, `"Aprobado"`, `"Rechazado"`, and `"Cancelado"` entries to `STATUS_MAPPING`
- [x] 3.2 Update `map_status` to return `nil` (instead of raising `ParseError`) for unknown values and append a warning to `row[:warnings]`
- [x] 3.3 Ensure `clean_values!` initialises `row[:warnings]` as an empty array before the status mapping step

## 4. Execution Service — Customer Routing

- [x] 4.1 In `import_customer`, read `row[:customer_type]`:
  - If `:prospect` → call `log_error` with an actionable message and return (skip creation)
  - If a Customer status symbol (`:active`, `:inactive`) → pass it to `Customer.create!` as `status:`
  - If `nil` (blank `Tipo de cliente`) → keep the existing default of `:active`
- [x] 4.2 Pass `intention: row[:intention]` to `Customer.create!` (nil is valid)
- [x] 4.3 For rows with an unknown customer type (warning set), call `log_error` and skip creation

## 5. Tests — Parser Service

- [x] 5.1 Add tests for each `CUSTOMER_TYPE_MAPPING` entry verifying correct `:customer_type` output
- [x] 5.2 Add test: blank `Tipo de cliente` → `:customer_type` is `nil`
- [x] 5.3 Add test: unknown `Tipo de cliente` → `:customer_type` is `nil` and `row[:warnings]` contains the unrecognised value
- [x] 5.4 Add tests for each `CUSTOMER_INTENTION_MAPPING` entry verifying correct `:intention` output
- [x] 5.5 Add test: blank `Estrategia (KARE)` → `:intention` is `nil`, no warning
- [x] 5.6 Add test: unknown `Estrategia (KARE)` → `:intention` is `nil`, no warning
- [x] 5.7 Add tests for each new proposal `STATUS_MAPPING` synonym (`En espera`, `Revisión`, `Aprobado`, `Rechazado`, `Cancelado`)
- [x] 5.8 Update the existing "raises error for unknown status value" test to assert `nil` status + warning instead of `ParseError`
- [x] 5.9 Add test: blank `Estado` → `nil` status, no warning
- [x] 5.10 Add test: one unknown-status row + one valid row → both parsed, no abort

## 6. Tests — Execution Service

- [x] 6.1 Add test: customer row with `customer_type: :prospect` → skipped, error message in result
- [x] 6.2 Add test: customer row with `customer_type: :inactive` → Customer created with `status: :inactive`
- [x] 6.3 Add test: customer row with `customer_type: :active` → Customer created with `status: :active`
- [x] 6.4 Add test: customer row with `intention: :keep` → Customer created with `intention: :keep`
- [x] 6.5 Add test: customer row with `intention: nil` → Customer created with `intention: nil`
- [x] 6.6 Add test: proposal row with `status: nil` → not persisted, row number in error list

## 7. Verify & CI

- [x] 7.1 Run `bin/ci` and confirm all tests, Rubocop, Brakeman, and bundler-audit checks pass

