## Why

Marketing-site visitors who fill in a contact form are currently lost to consultants — there is no automated path from a web submission into the CRM. A spike has wired an authenticated `POST /api/v1/contact` endpoint that accepts the payload, but it only logs and discards it. We need to turn inbound submissions into actionable records (a Prospect with a draft Proposal) so consultants can triage and follow up from the existing pipeline UI, without manual data entry.

## What Changes

- Promote the existing `Api::V1::ContactsController#create` from a logging stub to a real ingest endpoint that enqueues a background job and returns **202 Accepted**.
- Introduce `IngestWebContactJob` (Solid Queue) that:
  - Resolves the incoming `company` against existing Customers/Prospects using the same exact-then-fuzzy match ladder already used by the CSV import (`CsvImportExecutionService#find_linkable`).
  - On match: attaches a new draft Proposal to the matched Customer or Prospect.
  - On miss: creates a new Prospect (`source: :inbound`, `status: :new_prospect`) plus a draft Proposal.
  - Always appends an ActivityLog touchpoint capturing the visitor's free-text message on the resolved linkable.
- Provision a singleton **Intake user** (`info@kleer.la`, role `:consultant`) via an idempotent data migration. This user owns every auto-created Prospect and Proposal until a human triages it.
- Failure handling is delegated entirely to the job: validation errors, uniqueness collisions, and downstream errors surface as job retries/failures. The HTTP endpoint never returns 4xx for valid-shaped payloads.

Non-goals (deferred to future changes):

- Human merge/dedup UI for duplicate Prospects or cross-record matches.
- Enrichment (e.g. scraping company web context from the submitted URL).
- Notifications (Slack/email to the Intake watcher when a lead lands).
- Rate limiting or spam filtering on the public endpoint.
- Mapping the `context` URL to a service catalog or specific consultant.

## Capabilities

### New Capabilities

- `web-contact-intake`: Accept authenticated inbound contact submissions from the marketing site and turn them into a Prospect (or attach to an existing linkable) plus a draft Proposal and a touchpoint, owned by the Intake user.

### Modified Capabilities

<!-- None. Prospect, Proposal, and ActivityLog requirements are unchanged — this change consumes those capabilities rather than reshaping them. -->

## Impact

- **New code**: `app/jobs/ingest_web_contact_job.rb`, an idempotent data migration creating the Intake user, request + job tests.
- **Modified code**: `app/controllers/api/v1/contacts_controller.rb` (rewritten from spike), CONTEXT/README note documenting the endpoint and its async contract.
- **Already plumbed (no change)**: routes (`POST /api/v1/contact`), `Api::ApiController` token auth via `WEBHOOK_TOKEN`, `.env.template`, `.kamal/secrets`.
- **Operational**: the Intake user becomes a load-bearing seed record — production must run the data migration before the endpoint becomes useful. Solid Queue retries are the only failure surface; failed jobs need to be visible to operators.
- **External contract**: the marketing site must continue sending the existing `{ contact: { name, email, company, message, context } }` payload with the `WEBHOOK_TOKEN` Bearer header. Response semantics shift from `200 OK` to `202 Accepted`.
