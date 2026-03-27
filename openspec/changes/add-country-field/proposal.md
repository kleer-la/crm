## Why

The CRM currently drops the spreadsheet's `País/es` information and provides no place to store a company's base country on either Prospects or Customers. That makes imported records less complete and forces the team to keep referring back to the spreadsheet for a basic piece of account context.

## What Changes

- Add an optional `country` field to Prospect records
- Add an optional `country` field to Customer records
- Pre-populate `Customer.country` from `Prospect.country` during prospect conversion
- Expose the country field in Prospect and Customer create/edit flows and detail views
- Map the customer import spreadsheet column `País/es` to `country`
- Continue ignoring the spreadsheet column `País facturador`

## Capabilities

### New Capabilities
- `data-import`: Customer import supports mapping the spreadsheet `País/es` column into the CRM country field while continuing to ignore `País facturador`

### Modified Capabilities
- `customers`: Customer records support an optional country field, including values created manually and values inherited from prospect conversion
- `prospects`: Prospect records support an optional country field and preserve it when converting a Prospect into a Customer

## Impact

- **Schema**: Add nullable `country` columns to `customers` and `prospects`
- **Controllers and views**: Update Prospect and Customer forms, strong params, and detail pages to capture and display country
- **Services**: Update prospect conversion and CSV import parsing/execution to carry the new field through record lifecycle flows
- **Testing**: Add or update model, controller, service, and import tests covering manual entry, conversion, and spreadsheet mapping