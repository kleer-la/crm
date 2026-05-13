# Web Contact Intake — External Contract

The marketing site at kleer.la submits contact form data to `POST /api/v1/contact`.

- **Auth:** Bearer token via `WEBHOOK_TOKEN` env var
- **Payload:** `{ contact: { name, email, company, message?, context? } }`
- **Success:** `202 Accepted` — job enqueued, not yet processed
- **Failure (client):** `400 Bad Request` — malformed JSON or missing required fields
- **Processing:** `IngestWebContactJob` resolves company via exact/fuzzy match ladder, creates or attaches to Prospect/Customer, creates a draft Proposal, and logs a touchpoint. All records owned by intake user `info@kleer.la`.
- **Failures (server):** Retries via Solid Queue; dead-lettered jobs visible in the job dashboard.

See `app/jobs/ingest_web_contact_job.rb` and `app/controllers/api/v1/contacts_controller.rb` for implementation details.
