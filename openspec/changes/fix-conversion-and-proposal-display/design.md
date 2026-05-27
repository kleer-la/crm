## Context

The `ConvertProspectService` copies company-level data to a new Customer but omits the Prospect's inline contact fields and collaborating consultants. The Customer show page lacks a dedicated proposals section (the Prospect show page already has one). The `final_value` column on proposals is unused.

## Goals / Non-Goals

**Goals:**

- ConvertProspectService creates a Contact from Prospect's primary_contact_name/email/phone
- ConvertProspectService copies collaborating consultants to the new Customer
- Remove `final_value` column from proposals table and all model/view references
- Add a dedicated Proposals section to Customer show page (following the pattern from Prospects show)

**Non-Goals:**

- Not redesigning the timeline on Customer page (proposals section is additive)
- Not changing the stale proposal or last_activity_date logic (already correct per spec)
- Not versioning or archiving proposals (DocumentVersion is deprecated)

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Contact creation timing | Inside the existing transaction in `ConvertProspectService#call` | Atomicity — conversion either fully succeeds or rolls back; follows existing pattern of in-transaction operations |
| Collaborating consultant copy | Query Prospect's `consultant_assignments` and create matching assignments on Customer | Straightforward; `ConsultantAssignment` already supports polymorphic `assignable` |
| Primary flag on created Contact | New Contact is marked as primary | The prospect was the single point of contact; aligns with Customer's `new` action which builds a primary contact |
| `final_value` removal | Migration to drop column; remove from model, views, forms, and specs | Dead code — no migration of data needed since field is never populated |
| Proposals section on Customer page | Inline render (same pattern as Prospects show), ordered by date_asked desc | Simple, no new partial needed; matches existing convention |

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| If Prospect has no name/email (shouldn't happen due to validation), Contact creation could fail inside transaction, rolling back the entire conversion | Validations already prevent this; add a defensive `save!` with clear error message |
| Removing `final_value` could break external consumers (API, imports) | Check controllers and CSV import for references; no API exists currently |

## Migration Plan

1. Add Contact creation + consultant copy to `ConvertProspectService`
2. Add migration to remove `final_value` from proposals
3. Update Customer show view with proposals section
4. Update specs
5. Run `bin/ci` to verify
