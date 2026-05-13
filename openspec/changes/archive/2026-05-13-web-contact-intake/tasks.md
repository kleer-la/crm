## 1. Intake user provisioning

- [x] 1.1 Generate a data-only migration `EnsureIntakeUserExists` that uses `User.find_or_create_by!(email: "info@kleer.la")` to set `name: "Intake"`, `role: :consultant`, `active: true`
- [x] 1.2 Confirm idempotency by running the migration twice locally against a database that already has the row
- [x] 1.3 Add a model test (or migration test) verifying that running the migration leaves exactly one user with email `info@kleer.la` regardless of starting state

## 2. IngestWebContactJob

- [x] 2.1 Create `app/jobs/ingest_web_contact_job.rb` extending `ApplicationJob` with an `INTAKE_EMAIL = "info@kleer.la"` constant and a `perform(contact_payload)` entry point
- [x] 2.2 Implement a private `resolve_linkable(company)` that mirrors `CsvImportExecutionService#find_linkable`: (1) `Customer.where("company_name ILIKE ?", company).first`, then `Prospect.where("company_name ILIKE ?", company).first`; (2) `Customer.search_by_name(company).first`, then `Prospect.search_by_name(company).first`; (3) returns nil if nothing matches
- [x] 2.3 Implement a private `create_prospect!(payload, intake_user)` that builds the Prospect with `source: :inbound`, `status: :new_prospect`, `responsible_consultant: intake_user`, `date_added: Date.current`, `last_activity_date: Date.current`, and the payload's name/email/company; let `RecordInvalid` propagate
- [x] 2.4 Implement a private `create_draft_proposal!(linkable, payload, intake_user)` that creates a `:draft` Proposal with title `"Inbound web lead — <company>"`, a generic templated description, notes set to `payload["context"]`, and `responsible_consultant: intake_user`
- [x] 2.5 Implement a private `log_inbound_touchpoint!(linkable, payload)` that appends an ActivityLog touchpoint via the `Loggable` concern on the linkable, with content "Inbound web message: <payload.message>" (handle blank message with a placeholder)
- [x] 2.6 Wire `perform` to: load the Intake user via `User.find_by!(email: INTAKE_EMAIL)`, resolve or create the linkable, create the draft Proposal, log the touchpoint — all inside a single `ActiveRecord::Base.transaction`
- [x] 2.7 Add job tests covering: exact Customer match, exact Prospect match, fuzzy Customer match, fuzzy Prospect match, no match (new Prospect creation), email-collision raises, blank message still logs touchpoint, missing Intake user raises `RecordNotFound`
- [x] 2.8 Verify all created records (Prospect, Proposal, ActivityLog) are owned by / attached to the right entities in each test using FactoryBot

## 3. Controller rewrite

- [x] 3.1 Rewrite `app/controllers/api/v1/contacts_controller.rb` to parse the body as JSON, validate that `contact` is present and that `name`, `email`, `company` are non-blank
- [x] 3.2 On valid shape: `IngestWebContactJob.perform_later(contact_payload)` and `render status: :accepted, json: { message: "Contact accepted" }`
- [x] 3.3 On invalid JSON: rescue `JSON::ParserError` and render `400` with a brief error body
- [x] 3.4 On missing/blank required fields: render `400` with a body listing the missing fields
- [x] 3.5 Remove the `Rails.logger.debug data.inspect` left over from the spike
- [x] 3.6 Add controller request specs covering: valid payload returns 202 and enqueues the job exactly once; missing token returns 401 (skipped in test env); malformed JSON returns 400; missing `contact` returns 400; blank `name`/`email`/`message` returns 400
- [x] 3.7 Confirm that no test triggers Prospect/Proposal creation through the controller — all creation logic should live in the job and be exercised by job tests

## 4. Documentation

- [x] 4.1 Add a short section to the project's CONTEXT/README describing the endpoint, the payload shape, the 202 contract, the Intake user, and where failures show up (Solid Queue dashboard)
- [x] 4.2 Add a note to the OpenSpec capability spec folder so future readers can locate the contract with the marketing site
- [x] 4.3 Reference `CsvImportExecutionService#find_linkable` in a comment on `IngestWebContactJob#resolve_linkable` to flag the duplicate logic and future extraction opportunity

## 5. Verification

- [x] 5.1 Run `bin/ci` and ensure all tests, style, and security checks pass
- [x] 5.2 Manually exercise the endpoint in development with `curl` for: new company (creates Prospect+Proposal), known company (attaches to existing), known company that is a Customer (attaches to Customer), email-collision case (job fails visibly)
- [x] 5.3 Confirm in the Rails console that the Intake user is the responsible consultant on every record created end-to-end
