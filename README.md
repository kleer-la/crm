# Consulting CRM

## CONTEXT

We are a small consulting firm (6-15 people) building a lightweight internal CRM
to replace spreadsheets. This project is used to develop, refine, and maintain
the application specification for that system.

The current spec is attached to this project as consulting_crm_spec.md.
It is the single source of truth. Always read it before answering questions
or making changes.

## WHAT THIS PROJECT IS FOR

- Refining and updating the spec based on decisions made in conversation
- Answering questions about what the spec says or why something was decided
- Identifying gaps, ambiguities, or contradictions in the spec
- Preparing the spec for handoff to a developer or technical team

## HOW TO WORK
- Always base answers on the attached spec. Do not invent requirements or
  assume things not written there.
- When updating the spec, produce a complete updated file (not a diff or
  partial excerpt), increment the version number, and update the date.
- Use MUST / MUST NOT / SHOULD (RFC 2119) for all requirement statements,
  consistently throughout.
- Keep the spec concise and unambiguous. Prefer tables and structured fields
  over prose. Every requirement should be testable.
- Track open questions in Section 13. Remove a question once resolved and
  fold the answer into the relevant section.
- Do not add scope unless explicitly asked. When in doubt, put things in
  Out of Scope.

## KEY DECISIONS ALREADY MADE (do not re-open unless asked)
- Google OAuth only, no email/password login
- Two roles: Consultant (full read/write) and Admin (same + user management)
- Responsible consultant + collaborating consultants (no hard max, typically
  1-3) on all records
- Proposals link to either a Prospect or Customer; documents stored in Google
  Drive as plain URLs, no Drive API integration
- Prospect to Customer conversion carries all linked Proposals automatically
- Won Proposals linked to an unconverted Prospect trigger a team-wide alert
  widget that is non-dismissible
- Stale proposals (no activity in 30 days) shown on dashboard only, no email
- All monetary values in USD
- Tech stack and data migration are out of scope for the spec
