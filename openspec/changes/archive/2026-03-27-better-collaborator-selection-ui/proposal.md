## Why

The current collaborating consultants field is a plain checkbox list — it works but is visually noisy and doesn't scale as the team grows. A searchable, pill-based multi-select provides a cleaner, faster experience for assigning collaborators across Proposals, Customers, and Prospects.

## What Changes

- Replace the `shared/_consultant_multi_select` checkbox list with a Stimulus-powered searchable multi-select component
- Selected consultants appear as removable pills; a type-to-filter dropdown shows available options
- No backend changes required — the hidden `collaborating_consultant_ids[]` inputs remain the same
- Shared component used in all three forms (proposals, customers, prospects)

## Capabilities

### New Capabilities

- `collaborator-select-ui`: Searchable, pill-based multi-select widget for choosing collaborating consultants; replaces the checkbox list in all forms that use `shared/_consultant_multi_select`

### Modified Capabilities

<!-- No spec-level requirement changes — existing specs already describe collaborating consultants as a multi-select. This change only improves the UI implementation. -->

## Impact

- `app/views/shared/_consultant_multi_select.html.erb` — rewritten to use new component
- New Stimulus controller: `app/javascript/controllers/multi_select_controller.js`
- All three forms (proposals, customers, prospects) pick up the change automatically via the shared partial
- No model, controller, or database changes
