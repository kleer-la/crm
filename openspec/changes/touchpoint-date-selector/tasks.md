## 1. Database Migration

- [x] 1.1 Generate migration to add `occurred_at datetime` (nullable) to `activity_logs`, backfill from `created_at`, then add `NOT NULL` constraint
- [x] 1.2 Generate migration to add `last_activity_date date` (nullable) to `proposals`, backfill from MAX activity_log `created_at` per proposal (falling back to `proposals.created_at`)
- [x] 1.3 Run migrations and verify schema

## 2. ActivityLog Model

- [x] 2.1 Add `occurred_at` to `ActivityLog` — validate presence; set default to `Time.current` in `before_validation` for system events
- [x] 2.2 Update `update_parent_last_activity_date` callback: for Proposals, update `last_activity_date` with `occurred_at.to_date` only for touchpoints; skip system events (those are handled by the Proposal model)
- [x] 2.3 Update FactoryBot factory for `activity_log` to include `occurred_at`
- [x] 2.4 Write model tests: occurred_at defaults, validation, last_activity_date update for prospect/customer (unchanged), touchpoint on proposal updates last_activity_date with occurred_at, system event on proposal does not update last_activity_date

## 3. Loggable Concern

- [x] 3.1 Update `log_touchpoint` to accept an `occurred_at:` keyword argument (defaults to `Time.current`) and pass it to `activity_logs.create!`
- [x] 3.2 Update `log_system_event` to set `occurred_at: Time.current` explicitly

## 4. Proposal Model

- [x] 4.1 Add `last_activity_date` to `Proposal` — no validation (nullable)
- [x] 4.2 Update `log_status_change` to call `update_column(:last_activity_date, Date.current)` after logging the system event
- [x] 4.3 Update `stale` scope to use `occurred_at` instead of `created_at`
- [x] 4.4 Write model tests: last_activity_date set on status change, not set on consultant change or document link change; stale scope uses occurred_at

## 5. Controller

- [x] 5.1 Update `TouchpointsController#create` to pass `occurred_at: params[:occurred_at]` to `log_touchpoint` (parse as date, fall back to `Time.current` if blank)
- [x] 5.2 Write controller test: touchpoint with past occurred_at date is persisted correctly

## 6. Form

- [x] 6.1 Add date picker field (`occurred_at`) to `shared/_touchpoint_form.html.erb`, defaulting to today, required
- [x] 6.2 Label: "Date" with sentence case; no asterisk (required by default per UI conventions)

## 7. Timeline Display

- [x] 7.1 Update `shared/_activity_timeline.html.erb`: change caller sort from `created_at: :desc` to `occurred_at: :desc`; display `log.occurred_at.strftime("%b %d, %Y")` instead of `time_ago_in_words(log.created_at)`
- [x] 7.2 Update `customers/_history_timeline.html.erb`: use `log.occurred_at` as the sort date for activity log entries; display `log.occurred_at.strftime("%b %d, %Y")` in the activity log row

## 8. Tests & CI

- [x] 8.1 Write integration test: log backdated touchpoint on a proposal, verify timeline order and last_activity_date
- [x] 8.2 Run `bin/ci` and fix any failures
