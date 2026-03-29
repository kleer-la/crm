## Context

Proposals currently have a `title` field (string, not null) which is the primary identifier and maps to the "Propuesta" column in the CSV import. There is no dedicated `description` field. The CRM's CSV import for proposals uses a single "Propuesta" column to represent the proposal identity, which is currently sufficient but loses descriptive content that may exist in that column value.

## Goals / Non-Goals

**Goals:**
- Add a required `description` text field to the `proposals` table
- Populate `description` from the "Propuesta" CSV column during import (same source as `title`)
- Validate `description` as not null at the model level
- Display and edit `description` in UI forms and show pages
- Update `duplicate` to copy `description`

**Non-Goals:**
- Replacing or removing the `title` field — both fields coexist
- Adding a separate CSV column for description
- Full-text search indexing on `description` (can be added later)

## Decisions

### 1. Both `title` and `description` map to the "Propuesta" CSV column
**Decision:** During import, set `description` to the same value as `title` (from "Propuesta").

**Rationale:** The CSV format has a single "Propuesta" column. Having both fields default to the same value on import gives users a populated `description` to refine in the UI without breaking the existing `title` mapping or requiring a new CSV column.

**Alternative considered:** Map "Propuesta" to `description` only and auto-generate a short `title`. Rejected — `title` is used in `pg_search_scope`, activity logs, and displayed throughout the app; changing its source would be disruptive.

### 2. `description` is `NOT NULL` with a migration default
**Decision:** Add `description text, null: false, default: ""` in the migration, then remove the default after migration.

**Rationale:** Existing rows need a safe default to apply the constraint. An empty string is preferable to NULL for text fields used in display. The application-level validation (`presence: true`) ensures that new records via the UI/API always have a meaningful value.

**Alternative considered:** Allow null at DB level, enforce only in model validation. Rejected — the requirement explicitly states description can't be null, so it should be enforced at both layers.

### 3. In-place CSV parser extension — no new column in CSV
**Decision:** Update `HEADER_MAPPINGS[:proposal]` to add `"Propuesta" => :description` alongside the existing `"Propuesta" => :title`.

Since Ruby hashes can only have one value per key, the single key "Propuesta" maps to one field symbol. We handle this by populating `:description` in the `clean_values!` step using the already-mapped `:title` value, rather than adding a duplicate key.

**Rationale:** The `map_row` method iterates over the mapping hash; a duplicate key would silently overwrite. Deriving `:description` from `:title` after mapping is explicit and testable.

## Risks / Trade-offs

- **Existing records have empty description** → Acceptable; `description` defaults to `""` in the DB. Users can update records as needed. The empty string is valid at the DB level but the model `presence: true` validation only fires on save — existing records aren't re-validated unless updated.
- **Duplicate content from CSV** → `title` and `description` will be identical after import. Users are expected to enrich `description` over time. Not a blocker.

## Migration Plan

1. Generate migration: `add_column :proposals, :description, :text, null: false, default: ""`
2. Copy the title content to the description field during the migration
3. Deploy migration (zero-downtime — adding a column with a default is safe in PostgreSQL)
4. No rollback risk — column addition is non-destructive; rollback removes the column
