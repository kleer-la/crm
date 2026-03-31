## 1. Proposal model

- [x] 1.1 Add `STALE_DAYS = 30` constant to `Proposal` model
- [x] 1.2 Refine `stale` scope to filter on `entry_type: :touchpoint` and use `STALE_DAYS` constant

## 2. Dashboard view

- [x] 2.1 Update team alert message from "no activity in 30+ days" to "no contact in 30+ days"
- [x] 2.2 Update personal stale proposals heading from "no activity in 30+ days" to "no contact in 30+ days"

## 3. Tests

- [x] 3.1 Update existing `stale` scope model tests: system-event-only proposals should appear stale; touchpoint-logged proposals should not
- [x] 3.2 Add model test: proposal with only system events in last 30 days is included in `stale` scope
- [x] 3.3 Add model test: proposal with a touchpoint in last 30 days is excluded from `stale` scope
- [x] 3.4 Run `bin/ci` and confirm all tests, style, and security checks pass
