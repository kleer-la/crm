## Why

The current stale proposal alert fires on any activity log entry, including automated system events (status changes, document link updates). This means a proposal can appear "active" even when no human contact has actually occurred, causing the alert to miss genuinely neglected proposals.

## What Changes

- Refine the `Proposal.stale` scope to count only `touchpoint` activity log entries (call, email, meeting, note) — not system-generated entries
- Add a `STALE_DAYS = 30` constant to the `Proposal` model to make the threshold explicit and easy to adjust
- Update dashboard wording from "no activity in 30+ days" to "no contact in 30+ days" to accurately reflect what is being measured

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `dashboard`: The stale proposal alert requirement changes — a proposal is now stale when no **touchpoint** (human contact) has been logged in 30 days, not just any activity log entry

## Impact

- **`app/models/proposal.rb`**: `stale` scope updated; `STALE_DAYS` constant added
- **`app/views/dashboard/index.html.erb`**: Two alert messages updated (team alerts section + personal stale proposals section)
- **Tests**: Stale scope tests updated to reflect touchpoint-only logic
- No schema changes, no new controller variables, no new routes
