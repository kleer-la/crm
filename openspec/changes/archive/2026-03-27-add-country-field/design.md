## Context

Customer and Prospect records currently have no field for storing a company's base country. The customer import pipeline already parses the spreadsheet used by the team, but it explicitly ignores both `País/es` and `País facturador`, so that information is lost during import. The Prospect-to-Customer conversion flow also copies fields explicitly rather than generically, which means any new shared attribute must be added deliberately to avoid being dropped during conversion.

## Goals / Non-Goals

**Goals:**
- Store an optional country value on both Prospects and Customers
- Preserve the country value when converting a Prospect into a Customer
- Import the spreadsheet column `País/es` into the new country field for Customers
- Surface the field in the existing manual entry and detail-view flows

**Non-Goals:**
- Modeling `País facturador` separately
- Normalizing countries into a reference table or ISO code set
- Adding country-based filtering, sorting, or reporting in this change
- Changing proposal, task, or contact schemas
- Adding Prospect import support to the spreadsheet workflow

## Decisions

### 1. Use a nullable `country` string column on both models

**Decision:** Add a nullable `country` column to both `prospects` and `customers`.

**Why:** The value is optional, single-valued, and conceptually belongs directly to each record. A plain string matches the existing data model style used for fields such as `industry` and keeps the change small.

**Alternatives considered:**
- **Normalized countries table**: Rejected because there is no existing reference-data pattern in the app and no current need for referential integrity.
- **Enum or ISO code only**: Rejected because the source data is spreadsheet text and the team has not asked for strict normalization.

### 2. Keep country as free-text rather than validated reference data

**Decision:** Treat `country` as optional free text in forms, conversion, and import.

**Why:** This minimizes implementation cost and avoids introducing validation rules that may reject legacy spreadsheet values. It also keeps manual editing straightforward.

**Alternatives considered:**
- **Whitelist validation against country names**: Rejected because it increases friction and creates data-cleanup work that is not required for the current use case.

### 3. Propagate country explicitly during prospect conversion

**Decision:** Update the conversion service to pass `Prospect.country` into the created Customer.

**Why:** The conversion service currently whitelists copied attributes, so explicit propagation avoids silent data loss.

**Alternatives considered:**
- **Generic attribute copying between models**: Rejected because the current conversion flow is intentionally explicit and changing that pattern would broaden scope unnecessarily.

### 4. Map only `País/es` during customer import and continue ignoring `País facturador`

**Decision:** Extend the customer import mapping so `País/es` becomes `country`, while `País facturador` remains ignored.

**Why:** The business rule is now clear: only the company's base country matters for this change. Preserving the existing ignore behavior for `País facturador` avoids introducing an unused field.

**Alternatives considered:**
- **Store both spreadsheet columns in separate fields**: Rejected because the user explicitly chose to discard billing country.

### 5. Expose country on forms and detail views, but not on index filters in this change

**Decision:** Add the field to Prospect and Customer create/edit flows and show pages, without expanding list tables, sort fields, or filters.

**Why:** The immediate need is capture and visibility. Filtering/reporting can be added later if country becomes an operational dimension.

## Risks / Trade-offs

- **[Risk] Inconsistent country names** → Mitigation: accept free-text values for now and defer normalization until there is a concrete reporting or filtering need.
- **[Risk] Country could be missed in one lifecycle path** → Mitigation: cover manual create/update, prospect conversion, and customer import with focused controller and service tests.
- **[Trade-off] Country will not be filterable immediately** → Mitigation: keep the schema and naming simple so filters can be added later without reworking the data model.

## Migration Plan

1. Add nullable `country` columns to `prospects` and `customers`.
2. Deploy the schema and application changes together.
3. Existing records remain valid with `country = NULL` until edited or re-imported.
4. Rollback can remove the UI and service usage first; schema rollback is straightforward because the field is additive and optional.

## Open Questions

None at this time.