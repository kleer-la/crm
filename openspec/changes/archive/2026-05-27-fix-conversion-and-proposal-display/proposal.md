## Why

Several gaps and inconsistencies in the domain model were identified during a domain-grilling session. The conversion service omits contact and consultant data, the `final_value` field is unused, and Customer detail pages lack a dedicated proposals listing that Prospects already have.

## What Changes

- **ConvertProspectService** now creates a Contact from the Prospect's inline fields and copies collaborating consultants to the new Customer
- **Proposal `final_value`** column removed from schema and all references
- **Customer detail page** gains a dedicated Proposals section (matching the pattern on the Prospect show page)
- **Proposal `last_activity_date`** confirmed to update on status change to `sent` (already spec'd and implemented; verified)

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `prospects`: Conversion requirement updated — Contact creation and collaborating consultant copy added to the conversion flow
- `customers`: Revenue calculation corrected to `estimated_value` (was `final_value`); dedicated proposals list added to detail page

## Impact

| Area | Impact |
|---|---|
| `app/services/convert_prospect_service.rb` | Added Contact creation + consultant copy logic |
| `app/views/customers/show.html.erb` | New Proposals section inline |
| `db/migrate/` | Migration to remove `final_value` from proposals |
| `app/models/proposal.rb` | Remove `final_value` references |
| Existing specs | Updated to reflect corrected conversions and revenue calc |
