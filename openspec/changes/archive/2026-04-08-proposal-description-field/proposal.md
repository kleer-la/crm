## Why

Proposals currently have a `title` field mapped to the "Propuesta" CSV column on import, but no dedicated `description` field to capture the full proposal text. Adding a required `description` field ensures richer proposal content is captured and importable from the existing CSV format.

## What Changes

- Add a required `description` text field to the Proposal model
- Map the existing "Propuesta" CSV column to `description` (in addition to `title`) in the import parser
- Validate `description` as not null on the model
- Expose `description` in proposal forms, show pages, and index views
- Update the `duplicate` method to copy `description`

## Capabilities

### New Capabilities

- `proposal-description`: Required description field on Proposal records, populated from the "Propuesta" CSV column during import

### Modified Capabilities

- `proposals`: Proposal record management requirement gains a new required `description` field; CSV import mapping updated to populate it from "Propuesta"

## Impact

- **Model**: `Proposal` — new `description` column (text, not null), new validation, updated `duplicate`
- **Database**: migration to add `description` column with `null: false` and default empty string
- **CSV import**: `csv_import_parser_service.rb` — "Propuesta" maps to both `:title` and `:description`
- **Views**: proposals `_form`, `show`, `index` — display and edit `description`
- **Tests**: model validations, controller params, import service
