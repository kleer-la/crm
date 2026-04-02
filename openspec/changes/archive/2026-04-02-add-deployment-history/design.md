## Context

The CRM has no deployment tracking. Team members can't tell what version is running or when it was last deployed. A similar feature exists in the Central (cenped) app — this adapts that pattern to CRM's stack (Tailwind, PostgreSQL, all-user access).

## Goals / Non-Goals

**Goals:**
- Automatically record each deployment with git metadata
- Show deployment history to all authenticated users
- Display last deploy date in sidebar footer

**Non-Goals:**
- Rollback functionality
- Deploy triggering from the UI
- Notifications on deploy
- Environment comparison (prod vs QA side-by-side)

## Decisions

### 1. Capture mechanism: Kamal build script + env var
Same pattern as Central: `scripts/generate_build_info.sh` collects git metadata, outputs JSON, set as `BUILD_INFO` Kamal secret. Rails initializer parses and records on boot.

**Why over webhook/CI callback**: Zero external dependencies. Works with any Kamal deploy. No API tokens needed. Proven in Central.

### 2. Route under `/system` namespace
`/system/deployments` — clearly technical, not domain. Leaves room for future system pages (jobs, health).

**Why not `/admin`**: Deployment info is useful for all team members, not admin-only.

### 3. Record on boot via initializer
`config/initializers/record_deployment.rb` runs `Deployment.record_from_build_info` only in server processes (not console/rake). Uses `deployed_at` uniqueness to prevent duplicates across multiple server restarts.

**Why not Kamal post-deploy hook**: Hook runs on the deployer's machine, not the server. Would need an API endpoint + auth. Initializer is simpler.

### 4. Master-detail UI pattern
Single page with detail card (top) + paginated table (bottom). Clicking a row updates the detail card via query param `?id=X`. Matches Central's proven pattern.

### 5. Sidebar footer for last deploy
Compact "Deployed: YYYY-MM-DD HH:MM" text at sidebar bottom, linking to `/system/deployments`. Fetched via `Deployment.recent.first`. Gracefully hidden when no deployments exist.

## Risks / Trade-offs

- **[First deploy bootstrapping]** → First deploy won't have `BUILD_INFO` set yet (need to add secret first, then deploy). First recorded deployment will be the second deploy. Acceptable tradeoff — no migration needed.
- **[N+1 on sidebar]** → Sidebar loads latest deployment on every page. → Single query, cached by fragment caching. Negligible cost.
- **[Clock skew]** → `deployed_at` comes from deployer's machine clock. → Acceptable for internal tool.
