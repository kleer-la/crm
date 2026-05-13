## Context

The marketing site at kleer.la submits a JSON contact payload to a private endpoint when a visitor fills in a "contact us" form. A spike has already wired the transport: the route (`POST /api/v1/contact`), Bearer-token auth (`Api::ApiController` via `WEBHOOK_TOKEN`), Kamal secret, and a stub controller that parses, logs, and returns `200`. The shape is fixed by the marketing site:

```json
{
  "contact": {
    "name":    "Ana García",
    "email":   "ana@example.com",
    "company": "Acme S.A.",
    "message": "Quisiera info sobre fechas...",
    "context": "https://kleer.la/cursos/scrum"
  }
}
```

The CRM side has all the moving parts we need:

- `Prospect` (company_name unique, primary_contact_email unique, `source` enum including `:inbound`, polymorphic `proposals`, polymorphic `activity_logs` via `Loggable`).
- `Customer` (same `pg_search_scope :search_by_name, against: :company_name` for fuzzy matching).
- `Proposal` (polymorphic `linkable`, defaults to `:draft`).
- `ActivityLog` (append-only, accessed via `Loggable#log_touchpoint`-style helpers used elsewhere in the codebase).
- A precedent for the resolve-or-create ladder: [app/services/csv_import_execution_service.rb:183-213](app/services/csv_import_execution_service.rb#L183-L213) does *exactly* this match-then-fallback dance for CSV row → linkable.

What is missing is the glue: a job that runs the ladder, an owner user for auto-created records, and a controller that hands off instead of doing the work inline.

## Goals / Non-Goals

**Goals:**

- Convert every well-formed inbound submission into a Prospect (new or existing) plus a draft Proposal, owned by a known Intake user, with the visitor's message preserved as an immutable touchpoint.
- Make the HTTP endpoint cheap and reliable: validate shape, enqueue, return `202`. Never let CRM-side issues (validation, dedup collisions, DB hiccups) reach the marketing site.
- Reuse the existing fuzzy company-match ladder from CSV import so behaviour is consistent across both ingest paths.
- Keep the data model unchanged. No new tables, no new columns. The Intake user is a seed row, not a schema feature.

**Non-Goals:**

- Human merge/dedup UI. Duplicate Prospects from inbound submissions are accepted as a known v1 cost.
- Enrichment: no scraping of the `context` URL, no LinkedIn lookups, no GeoIP.
- Notifications: no Slack/email when a lead lands. Triage happens via the existing pipeline UI.
- Rate limiting, CAPTCHA, or content filtering — the marketing site is responsible for spam prevention upstream.
- Mapping `context` URL to a specific consultant or service line. The Intake user owns everything.
- Email-based dedup: two submissions with the same email but different company names produce two records. We pay this cost knowingly.

## Decisions

### D1. Async via Solid Queue, sync at the HTTP boundary

The controller validates only the **shape** of the payload (must be JSON, must include `contact` with at least `name`, `email`, `company`) and enqueues `IngestWebContactJob`, returning `202 Accepted`.

**Why:** the marketing site does not care whether the CRM had a uniqueness collision; it cares whether its POST reached an intake pipeline. Validation, fuzzy matching, and record creation all have failure modes (uniqueness clashes, DB errors, future enrichment timeouts) that should not bubble out as 4xx/5xx to the public site. Pushing work into Solid Queue gives us free retries and a visible failure surface (the job dashboard) without coupling availability of the CRM to the marketing site's request.

**Alternative considered:** do the work inline in the controller and return 201/422. Rejected because (a) it couples external availability to internal data quality, and (b) it forecloses on planned future work (enrichment, notifications) that genuinely belongs out-of-band.

### D2. Reuse the import's fuzzy match ladder, do not extract it yet

Mirror the steps from [app/services/csv_import_execution_service.rb:183-213](app/services/csv_import_execution_service.rb#L183-L213):

1. Exact `company_name ILIKE ?` against `Customer`, then `Prospect`.
2. `Customer.search_by_name(company)` (pg_search trigram), then `Prospect.search_by_name(company)`.
3. Fallback: create a new `Prospect`.

**Why:** the import was written deliberately to tolerate the kinds of variation we see in inbound names ("UTE" vs "UTE UY", "Acme" vs "Acme S.A."). Re-deriving the heuristic in a second place would be a missed opportunity for consistency.

**Why not extract to a shared service yet:** doing so requires reconciling step 3 (import creates a Customer with status `:active` and a CSV-row-derived consultant; web intake creates a Prospect with `source: :inbound` and the Intake user). Those divergences are real enough that a premature abstraction will leak parameters. We duplicate the match logic now, accept the cost, and flag a follow-up to extract `LinkableMatcher` once a third caller appears.

### D3. Match by company_name only; tolerate email duplicates on the cold path

We do not use `primary_contact_email` as a match key. If `company` fuzzy-matches an existing Prospect/Customer, we attach to it regardless of who the human is — the message body and touchpoint preserve the actual sender.

**Why:** company is a stronger "same opportunity" signal than email at the org level. The same buyer often submits from different addresses; different people from one company frequently both reach out. We choose to merge on org and keep the human-level disambiguation in the touchpoint trail.

**Cold-path consequence:** when no company match is found and we attempt to create a new Prospect, `primary_contact_email` is still unique on the Prospect table *and* uniqueness-checked against `Contact.email` on the customer side. If a collision exists, Prospect creation raises `RecordInvalid`. The job lets it fail; Solid Queue retries (then dead-letters) and a human cleans up.

**Alternative considered:** match by `email OR company_name`. Rejected because a single human (often a consultant working with multiple clients) submitting from two companies would falsely merge two unrelated opportunities.

### D4. Intake user is a seeded `User`, provisioned via an idempotent data migration

The Intake user is a normal `User` row: `email: "info@kleer.la"`, `name: "Intake"`, `role: :consultant`, `active: true`, `google_uid: nil`. No new column, no `role: :intake` enum value. A data-only Rails migration uses `User.find_or_create_by!(email: "info@kleer.la") { ... }` so it can run repeatedly and across environments.

**Why a data migration rather than `db/seeds.rb`:** seeds are not part of automatic deploys in this app's setup. A migration is the only mechanism we already trust to run on every environment after deploy.

**Why role `:consultant`:** the `User#role` enum is `pending: 0, consultant: 1, admin: 2`. Intake needs to own records (which any consultant can) but should not have admin privileges. Adding a new enum value would force schema/code changes for a one-off — not warranted for v1.

**Why a known email rather than a flag column:** the team explicitly chose this. It is the simplest correct option for a singleton role, and reassigning ownership later is a one-line `User.find_by(email: ...)` change away. A column-based marker is the right move only if/when "Intake" splits into multiple users (per-channel intake), and that is a future change.

### D5. Lookup helper, not configuration

Job code calls `User.find_by!(email: "info@kleer.la")` directly. The email is a constant in the job class (`INTAKE_EMAIL = "info@kleer.la"`) so it is easy to find by grep and rename in one place. We do not add a Rails credential, an env var, or a singleton settings row.

**Why:** all three alternatives add indirection that buys nothing while the Intake user is a single, stable, known address. If the rule changes (e.g., per-environment intake emails), promoting the constant to a credential is a five-minute follow-up.

### D6. Use the linkable's `description`, `notes`, and timeline as designed

- `Proposal.title`: `"Inbound web lead — <company>"` — searchable, scannable in pipeline lists.
- `Proposal.description`: a short generic phrase (e.g. `"Lead captured from the marketing site. See activity log for the original message."`). Required by the model (`presence: true`); we deliberately do not crowd it with the user's raw input.
- `Proposal.notes`: the `context` URL from the payload (page + button id). Pure metadata, useful for analytics later.
- `ActivityLog` touchpoint on the **linkable** (the Prospect or Customer, not the Proposal): `"Inbound web message: <payload.message>"`. This is where the human content lives, and where consultants will look when triaging.

**Why split message and metadata this way:** the Proposal is a planning surface; the timeline is a history surface. Visitor messages are events, not properties of the proposal — placing them on the timeline matches how a consultant scans the prospect page.

## Risks / Trade-offs

- **[Risk] Duplicate Prospects accumulate from inbound traffic.** Fuzzy match has a 0.3 trigram threshold (per `Customer.search_by_name` config), which is permissive but imperfect. A small fraction of inbound submissions will spawn a duplicate Prospect that a human must merge.
  → **Mitigation:** explicitly out of scope to fix in v1. A future "merge prospects" feature is queued. The Intake user owning all auto-created records makes them easy to filter for periodic cleanup.

- **[Risk] Email uniqueness collision raises on the cold path.** A first-time submitter whose email already lives on an unrelated Prospect or Customer Contact will cause Prospect creation to fail.
  → **Mitigation:** the job lets the exception propagate, Solid Queue retries N times then dead-letters, and the failure shows up in the job dashboard with the full payload for manual handling. We do not silently swallow.

- **[Risk] The Intake user is a load-bearing seed.** If the data migration is rolled back or the row is deleted in production, the job will raise on every inbound message.
  → **Mitigation:** the migration is idempotent (`find_or_create_by!`), and the job uses `find_by!` so the failure is loud rather than silent (an unowned Prospect would be much worse). A one-line README/CONTEXT note documents the seed.

- **[Risk] Polymorphic Proposal on Customer means random web visitors can spawn draft Proposals on real customers.** A misdirected submission ("Hi I'd like info" to a company that's already a customer) creates a draft proposal there.
  → **Trade-off accepted:** draft proposals are harmless until a consultant promotes them; the Intake user owns the draft until triaged; and the alternative (always create a new Prospect for inbound, even when the company is already a customer) creates orphan records that don't belong in the prospect pipeline. Surfacing inbound activity on the existing Customer is the right call.

- **[Risk] No rate limiting.** The endpoint is authenticated by a shared `WEBHOOK_TOKEN`. If the token leaks, an attacker can flood the queue.
  → **Mitigation:** out of scope; rotate the token if leaked. Future hardening (Rack::Attack, per-IP throttling) is a separate change.

- **[Trade-off] Validation responses are uniform `202`s.** The marketing site cannot tell from the HTTP response whether a submission actually produced a Prospect — only that it was queued. This is intentional (decoupling) but means failures are only visible internally.
  → **Mitigation:** rely on the job dashboard and CRM-side visibility (the pipeline view). The marketing site does not need this signal today.
