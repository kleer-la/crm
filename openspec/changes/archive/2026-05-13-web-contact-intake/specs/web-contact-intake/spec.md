## ADDED Requirements

### Requirement: Authenticated inbound contact endpoint
The system SHALL expose `POST /api/v1/contact` to accept JSON contact submissions from the marketing site. The endpoint SHALL require Bearer-token authentication using the `WEBHOOK_TOKEN` environment variable in non-development environments. The endpoint SHALL validate that the request body is JSON containing a `contact` object with non-blank `name`, `email`, and `message` fields. On a well-formed payload the endpoint SHALL enqueue an `IngestWebContactJob` carrying the payload and respond with HTTP `202 Accepted`. The endpoint SHALL NOT perform record creation, validation, or fuzzy matching in the request cycle.

#### Scenario: Valid submission is accepted and enqueued
- **WHEN** a request with a valid `WEBHOOK_TOKEN` Bearer header and a payload containing non-blank `contact.name`, `contact.email`, and `contact.message` is received
- **THEN** the system enqueues an `IngestWebContactJob` with the payload and responds with `202 Accepted`

#### Scenario: Missing or invalid token
- **WHEN** a request is received without a Bearer token, or with a token that does not match `WEBHOOK_TOKEN`
- **THEN** the system responds with `401 Unauthorized` and does not enqueue a job

#### Scenario: Malformed JSON body
- **WHEN** a request is received whose body cannot be parsed as JSON
- **THEN** the system responds with `400 Bad Request` and does not enqueue a job

#### Scenario: Missing required contact fields
- **WHEN** a request is received whose payload is missing `contact`, or whose `contact` object has a blank `name`, `email`, or `message`
- **THEN** the system responds with `400 Bad Request` and does not enqueue a job

### Requirement: Intake user provisioning
The system SHALL provision a singleton "Intake" user with email `info@kleer.la`, name `Intake`, role `consultant`, and `active: true`. Provisioning SHALL run as part of database migrations and SHALL be idempotent so re-runs do not raise. The Intake user SHALL own all Prospects and Proposals auto-created by web contact intake until a human reassigns them.

#### Scenario: Migration creates the Intake user on a fresh database
- **WHEN** the data migration runs against a database without an existing `info@kleer.la` user
- **THEN** a `User` record is created with email `info@kleer.la`, name `Intake`, role `consultant`, and `active: true`

#### Scenario: Migration is safe to re-run
- **WHEN** the data migration runs against a database that already contains a user with email `info@kleer.la`
- **THEN** the migration completes without error and does not duplicate the user or modify its existing attributes

### Requirement: Resolve linkable by company name
`IngestWebContactJob` SHALL resolve the submitted `company` to an existing linkable record using a three-step ladder, in order: (1) exact case-insensitive match (`ILIKE`) against `Customer.company_name`, then `Prospect.company_name`; (2) trigram fuzzy match via `Customer.search_by_name(company)`, then `Prospect.search_by_name(company)`; (3) when no match is found, create a new Prospect. The job SHALL use the first match found and SHALL NOT continue evaluating later steps once a match is established.

#### Scenario: Exact match against an existing Customer
- **WHEN** a submission's `company` exactly matches (case-insensitively) the `company_name` of an existing Customer
- **THEN** the job resolves the linkable to that Customer without creating a new Prospect

#### Scenario: Exact match against an existing Prospect
- **WHEN** a submission's `company` exactly matches (case-insensitively) the `company_name` of an existing Prospect and no Customer matches
- **THEN** the job resolves the linkable to that Prospect

#### Scenario: Fuzzy match against an existing linkable
- **WHEN** a submission's `company` has no exact match but trigram-matches an existing Customer or Prospect via `search_by_name`
- **THEN** the job resolves the linkable to the first such match, preferring Customer over Prospect

#### Scenario: No match falls through to Prospect creation
- **WHEN** a submission's `company` has neither exact nor fuzzy match against any Customer or Prospect
- **THEN** the job proceeds to create a new Prospect (see "Create new Prospect on no match")

### Requirement: Create new Prospect on no match
When the resolve step finds no matching Customer or Prospect, `IngestWebContactJob` SHALL create a new `Prospect` with `company_name` from `contact.company`, `primary_contact_name` from `contact.name`, `primary_contact_email` from `contact.email`, `source: :inbound`, `status: :new_prospect`, `responsible_consultant` set to the Intake user, `date_added` and `last_activity_date` set to today's date. Email is not used as a match key; if the new Prospect violates `primary_contact_email` uniqueness against existing Prospects or Customer contacts, the job SHALL fail and rely on Solid Queue retries / dead-lettering.

#### Scenario: Successful Prospect creation
- **WHEN** the resolve step returns no match for a submission whose email is not in use elsewhere
- **THEN** a new Prospect is created with `source: :inbound`, `status: :new_prospect`, `responsible_consultant` = Intake user, today's date_added and last_activity_date, and the payload's name/email/company

#### Scenario: Email collision raises a job failure
- **WHEN** the resolve step returns no match but the submission's email already belongs to an existing Prospect or Customer contact
- **THEN** the job raises `ActiveRecord::RecordInvalid`, the failure surfaces in Solid Queue's failed-job dashboard, and no Prospect or Proposal is created for that submission

### Requirement: Create draft Proposal on resolved linkable
For every successful ingest, `IngestWebContactJob` SHALL create a `Proposal` linked polymorphically to the resolved Customer or Prospect with `status: :draft`, `responsible_consultant` set to the Intake user, `title` set to `"Inbound web lead — <company>"`, a generic non-empty `description`, and `notes` set to the `contact.context` value from the payload (or blank when context is absent).

#### Scenario: Draft Proposal attached to matched Customer
- **WHEN** the linkable resolves to an existing Customer
- **THEN** a new draft Proposal is created with `linkable` = that Customer, owned by the Intake user, title containing the company name, notes set to the payload context, and the Customer's existing proposals are otherwise unchanged

#### Scenario: Draft Proposal attached to matched Prospect
- **WHEN** the linkable resolves to an existing Prospect
- **THEN** a new draft Proposal is created with `linkable` = that Prospect, owned by the Intake user, title containing the company name, and notes set to the payload context

#### Scenario: Draft Proposal attached to newly created Prospect
- **WHEN** the linkable resolves by creating a new Prospect
- **THEN** a new draft Proposal is created with `linkable` = that Prospect, owned by the Intake user, title containing the company name, and notes set to the payload context

### Requirement: Log inbound message as a touchpoint
For every successful ingest, `IngestWebContactJob` SHALL append an `ActivityLog` entry on the **resolved linkable** (Customer or Prospect) capturing the submitter's free-text `contact.message`. The entry SHALL be a touchpoint-type log whose content includes the raw message text. The entry SHALL NOT be created on the Proposal.

#### Scenario: Message becomes a touchpoint on the linkable
- **WHEN** a submission is processed successfully (whether the linkable was matched or newly created)
- **THEN** an ActivityLog entry is appended to the linkable that records "Inbound web message" together with the payload's `message` text

#### Scenario: Touchpoint is recorded even when message is blank
- **WHEN** a submission is processed successfully but `contact.message` is blank or omitted
- **THEN** an ActivityLog entry is still appended to the linkable indicating an inbound web contact occurred, with empty or placeholder message content

### Requirement: Asynchronous failure handling
`IngestWebContactJob` SHALL NOT swallow exceptions arising from validation, uniqueness collisions, or downstream failures. Such exceptions SHALL propagate to Solid Queue so that the job is retried and ultimately surfaced as a failed job for operator visibility. The HTTP endpoint SHALL NOT change its `202 Accepted` response based on job outcomes.

#### Scenario: Validation error inside the job
- **WHEN** the job raises `ActiveRecord::RecordInvalid` while creating a Prospect or Proposal
- **THEN** Solid Queue retries the job according to its configured policy and, upon final failure, the job is visible in the failed-job dashboard with the original payload
