# Domain Glossary

## Prospect
A sales lead — a company being pursued as a potential client. Carries inline contact fields (`primary_contact_name`, `primary_contact_email`, `primary_contact_phone`) directly on the record. No separate Contact association. Has a lifecycle: new → contacted → qualified → converted or disqualified. Disqualification is reversible — a disqualified prospect may be re-qualified. Carries an independent `estimated_value` (rough opportunity-level guess, not tied to any specific Proposal's estimate).

## Customer
A paying or active client company. Has many Contacts (separate model with name, email, phone, role title, and a primary flag). Statuses: active, inactive, at-risk. Strategies: keep, attract, recapture, expand.

## Conversion
The process of turning a Prospect into a Customer. Creates a Customer record from the Prospect's company-level data, relinks all Proposals and Tasks, copies the `responsible_consultant`, and sets the Prospect to read-only. Independent of proposal status — a prospect may be converted with or without won proposals. **Must also create a Contact record from the Prospect's inline contact fields and copy collaborating consultants** (current gap — `ConvertProspectService` does not do this yet).

## Pending Conversion
A won Proposal whose linked Prospect has not yet been converted to a Customer. An informational nudge, not a workflow gate.

## Contact
A person associated with a Customer. Has name, email, phone, role title, and an optional primary flag (informational only — not enforced as a constraint). Belongs to a Customer.

## User
A person who uses the system. Has a role (pending, consultant, admin), an active flag, and a Google UID for authentication.

- **pending:** Signed up via Google OAuth, awaiting role assignment. Cannot access the application.
- **consultant:** Full CRUD access to all business records (flat team — no record-level scoping).
- **admin:** Consultant access plus user management, imports, and canned responses.

An admin can assign any role and toggle active/inactive freely. Deactivated users retain their relationships on records; other consultants can reassign themselves as responsible.

## Proposal
A sales proposal linked polymorphically to a Prospect or Customer. Has a lifecycle: draft → sent → under_review → won, lost, or cancelled. Carries an `estimated_value`. Tracks a single `current_document_url` directly on the record (no versioning — DocumentVersion model is deprecated). Proposals should never be deleted — restrict_with_error at the association level enforces this when tasks or document versions exist, but the intent is broader: proposals are permanent records.

## Task
A to-do item linked polymorphically to a Prospect, Customer, or Proposal. Has priority (low, medium, high), status (open, in-progress, done, cancelled), due date, and a single assignee. Conventionally assigned to someone on the parent record's team (responsible or collaborating consultant), but not enforced as a constraint.

## Activity Log
An append-only chronicle of system events and touchpoints (calls, emails, meetings, chats) linked polymorphically to any record. Immutable after creation.

## Conversation
A messaging thread on an external platform (WhatsApp, Instagram, Facebook). Belongs to the messaging context — separate from the sales pipeline. Can optionally link to a Prospect, Customer, or Proposal, but the link is incidental (not relinked during conversion).

## Consultant Assignment
A polymorphic join record linking collaborating consultants to Prospects, Customers, or Proposals. A user can only appear once per parent record.
