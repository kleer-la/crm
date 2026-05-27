## 1. Fix ConvertProspectService

- [x] 1.1 Add Contact creation inside the conversion transaction: create a Contact on the new Customer from `@prospect.primary_contact_name`, `@prospect.primary_contact_email`, `@prospect.primary_contact_phone`, marked as primary
- [x] 1.2 Copy collaborating consultants: query `@prospect.consultant_assignments` and create matching `ConsultantAssignment` records for the new Customer
- [x] 1.3 Update `ConvertProspectService` tests — add scenarios for: contact created from inline fields, consultant copy, missing collaborating consultants

## 2. Remove final_value

- [x] 2.1 Generate a migration to remove the `final_value` column from proposals table
- [x] 2.2 Remove `final_value` from `CsvImportParserService` header mapping and `MONETARY_FIELDS`
- [x] 2.3 Remove `final_value` assignment from `CsvImportExecutionService`
- [x] 2.4 Update CSV import parser tests to remove `final_value` assertions
- [x] 2.5 Update CSV import execution tests to remove `final_value` from expectations
- [x] 2.6 Update `openspec/specs/data-import/spec.md` to remove `final_value` from header mapping

## 3. Add Proposals section to Customer show page

- [x] 3.1 Add inline proposals section to `customers/show.html.erb` (following the same pattern as `prospects/show.html.erb`): iterate `@customer.proposals.order(date_asked: :desc)`, showing title (linked), status badge, estimated value, expected close date
- [x] 3.2 Add "New proposal" button linking to `new_proposal_path(linkable_type: "Customer", linkable_id: @customer.id)`
- [x] 3.3 Update Customer show page integration tests to verify proposals section renders

## 4. Update specs and verify

- [x] 4.1 Update `openspec/specs/customers/spec.md`: modify revenue calc requirement to use `estimated_value` and add proposals section requirement
- [x] 4.2 Update `openspec/specs/prospects/spec.md`: modify conversion requirement to include Contact creation and consultant copy
- [x] 4.3 Run `bin/ci` and fix any failures
