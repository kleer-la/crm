## Context

Touchpoints are logged by consultants to record client interactions (calls, emails, meetings, notes). Currently the only timestamp on `ActivityLog` is `created_at`, which reflects when the record was inserted — not when the interaction happened. Consultants routinely log touchpoints days or weeks after the fact, resulting in inaccurate timelines and a broken stale-proposal detection scope.

`ActivityLog` is immutable after creation (`before_update` raises, `before_destroy` throws abort), which is a deliberate constraint. The new `occurred_at` field fits cleanly within this model: it is set once at creation and never changed.

Proposals currently have no `last_activity_date` column, meaning the `respond_to?` guard in the `Loggable` concern silently skips them. This is the most actively tracked model, so the column is overdue.

## Goals / Non-Goals

**Goals:**
- Allow consultants to specify the date an interaction occurred when logging a touchpoint
- Sort and display activity timelines by `occurred_at`
- Track `last_activity_date` on proposals, updated by touchpoints and status changes
- Update the `stale` scope on `Proposal` to use `occurred_at`

**Non-Goals:**
- Allowing edit of `occurred_at` after creation (immutability is preserved)
- Adding `occurred_at` to system events (they happen at log time by definition)
- Changing `last_activity_date` semantics on Prospects or Customers (those remain wall-clock)
- Validating that `occurred_at` is not in the future (trust consultants on this)

## Decisions

### 1. `occurred_at` on `ActivityLog`, not a separate table

Storing the date directly on the log row keeps queries simple and consistent with how `created_at` is used today. No join overhead, no extra model.

*Alternatives considered:* A separate `touchpoint_metadata` table — rejected as over-engineering for a single date field.

### 2. `occurred_at` defaults to `Time.current` for system events

System events (status changes, consultant changes, document updates) happen exactly when logged, so they auto-populate `occurred_at = Time.current` without any user input. Only touchpoints expose the date picker.

*Rationale:* Keeps the field semantically consistent — `occurred_at` always means "when this event happened" — without requiring UI changes to system-generated logs.

### 3. `last_activity_date` on Proposals uses `occurred_at`; Prospects/Customers keep `Time.current`

For Proposals, `last_activity_date` tracks "when were we last in contact with the client" — `occurred_at` is the right signal. For Prospects and Customers, the existing callback uses `Time.current` (wall clock) which serves its purpose of "when did we last log anything here." These are different operational needs; conflating them would break pipeline health signals.

### 4. Only touchpoints and status changes update `last_activity_date` on Proposals

Internal housekeeping events (consultant reassignment, document URL changes, proposal creation) do not represent client-facing activity and should not reset the staleness clock. This is implemented by:
- Having the `ActivityLog` callback update `last_activity_date` on Proposals only for touchpoints (using `occurred_at`)
- Having `Proposal#log_status_change` update `last_activity_date` directly with `Date.current`

### 5. Backfill `occurred_at` from `created_at`

Existing rows get `occurred_at = created_at`. This is accurate enough — old records were logged at the time they happened. The column is made `NOT NULL` after backfill.

### 6. Timeline display uses absolute date for `occurred_at`

`time_ago_in_words` is dropped for touchpoint timestamps in favour of `strftime("%b %d, %Y")`. Relative time becomes confusing when a backdated entry reads "14 days ago" even though it was logged just now. Absolute dates are unambiguous.

The customer history timeline mixes proposals, tasks, and activity logs sorted by date. It will use `occurred_at` for activity log entries and retain `created_at` for proposals and tasks (those don't have `occurred_at`).

## Risks / Trade-offs

- **Stale scope uses `occurred_at` after change** — A backdated touchpoint (occurred 25 days ago, logged today) will correctly mark a proposal as not-stale. This is the desired behaviour but is a semantic change from the current "logged in last 30 days" check. → Low risk; the new behaviour is strictly more correct.
- **`last_activity_date` backfill for proposals** — New column, so all existing proposals start with `NULL`. A backfill from the latest touchpoint `occurred_at` per proposal would be ideal but is complex. Instead, backfill from `MAX(activity_logs.created_at)` per proposal, falling back to `proposals.created_at`. Nullable column, so proposals with no logs stay NULL gracefully.

## Migration Plan

1. Add `occurred_at datetime` (nullable) to `activity_logs`
2. `UPDATE activity_logs SET occurred_at = created_at`
3. Add `NOT NULL` constraint to `occurred_at`
4. Add `last_activity_date date` (nullable) to `proposals`
5. Backfill: `UPDATE proposals SET last_activity_date = (SELECT DATE(MAX(al.created_at)) FROM activity_logs al WHERE al.loggable_type = 'Proposal' AND al.loggable_id = proposals.id)`

Rollback: remove both columns. No data loss risk; `occurred_at` mirrors `created_at` for old rows.
