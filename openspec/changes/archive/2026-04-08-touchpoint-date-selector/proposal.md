## Why

Consultants frequently log touchpoints after the fact — sometimes days or weeks later — meaning the recorded timestamp reflects when the entry was created, not when the interaction occurred. This makes proposal activity timelines inaccurate and the stale-proposal detection unreliable.

## What Changes

- Add `occurred_at` datetime column to `activity_logs`, backfilled from `created_at` for existing rows
- Add a date picker to the touchpoint form, defaulting to today, so consultants can specify when the interaction actually happened
- Sort activity timelines by `occurred_at` (not `created_at`) and display absolute dates
- Add `last_activity_date` column to `proposals`, updated when a touchpoint is logged or a status change occurs
- Update the `stale` scope on `Proposal` to use `occurred_at` instead of `created_at`

## Capabilities

### New Capabilities
- `touchpoint-occurred-at`: Date field on touchpoint creation capturing when the interaction happened, with timeline sorting and display updated to reflect it

### Modified Capabilities
- `activity-log`: `occurred_at` field added; timelines sort and display by occurred_at
- `proposals`: New `last_activity_date` column tracking meaningful client events (touchpoints and status changes)

## Impact

- **Schema**: New `occurred_at` column on `activity_logs`; new `last_activity_date` column on `proposals`; backfill migration for both
- **Models**: `ActivityLog` — `occurred_at` set at creation; `Loggable` concern updated to pass occurred_at; `Proposal` — `last_activity_date` updated on touchpoint log and status change; stale scope updated
- **Controller**: `TouchpointsController#create` accepts `occurred_at` param
- **Views**: `_touchpoint_form` adds date picker; `_activity_timeline` and `customers/_history_timeline` sort and display by `occurred_at`
- **No new dependencies**
