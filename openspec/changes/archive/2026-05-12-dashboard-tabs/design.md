## Context

The current `DashboardController#index` loads all data (personal + team alerts + admin metrics) in a single action and renders it into one long view ([dashboard_controller.rb:1-78](app/controllers/dashboard_controller.rb#L1-L78), [index.html.erb](app/views/dashboard/index.html.erb)). This produces ~10 queries on every dashboard hit including queries for content the user never looks at, and bakes in an admin/consultant distinction that no longer matches the org structure.

This change introduces a tabbed structure where each tab is rendered by its own controller action behind a Turbo Frame. The Mine tab uses `loading="lazy"` so its queries only run when the user clicks into it. Tab switching is handled by a small Stimulus controller — no full-page reloads.

## Goals / Non-Goals

**Goals:**
- Same shared view of pipeline health for every consultant (no admin gating on the dashboard).
- First paint does only the work needed for the default (Team) tab.
- Per-type alert boxes replace today's mixed alert column, making each alert category individually scannable.
- KPI strip stays visible regardless of active tab so team headline numbers are always available.
- Test surface area shrinks: collapse the admin/consultant distinction in dashboard tests.

**Non-Goals:**
- No per-user dashboard customization or widget reordering.
- No per-tab URL state (no `/dashboard/team` and `/dashboard/mine` user-facing URLs — internal panel actions are used by Turbo Frames only).
- No per-user "last visited tab" memory — Team is always the default.
- No alert dismissal, snooze, or read-state tracking.
- No caching layer — live data preserved per existing spec.
- No changes to the underlying alert resolution logic (touchpoint-based staleness, conversion detection, overdue task detection).

## Decisions

### Decision 1: Tab loading via Turbo Frames with `loading="lazy"`, not full URL routing

The shell template renders two `<turbo-frame>` elements: the Team frame has an immediate `src` (eager) and the Mine frame uses `loading="lazy"` with a `src` pointing to its panel action. Turbo defers the lazy frame's request until the frame becomes visible.

Tab switching is a Stimulus controller toggling `hidden` on the two frame containers and `aria-selected` on the tab buttons. Clicking the Mine tab makes the frame visible, which causes Turbo to fire the request the first time. Subsequent clicks are instant (frame already loaded).

**Alternatives considered:**
- *Full pages with separate routes (`/dashboard/team`, `/dashboard/mine`)*: Forces a full page reload when switching tabs, loses the always-visible KPI strip without re-rendering it, and adds unwanted URL state since the user explicitly does not want per-tab bookmarking.
- *Single action loading both, hidden via CSS*: Defeats the lazy-load goal — both queries always run.
- *Stimulus + fetch + manual DOM swap*: Reinvents what Turbo Frames give us for free.

### Decision 2: Two new controller actions `#team_panel` and `#mine_panel`

Each panel action loads only the data its tab needs. `#index` only loads the KPI strip data and renders the shell. Method-level extraction keeps each action small and tests targeted at one panel at a time.

Routes:
```ruby
get "dashboard", to: "dashboard#index"
get "dashboard/team_panel", to: "dashboard#team_panel"
get "dashboard/mine_panel", to: "dashboard#mine_panel"
```

Panel actions render frame-only responses (no layout) — the views are wrapped in `<turbo-frame id="dashboard-team">` / `<turbo-frame id="dashboard-mine">`.

**Alternatives considered:**
- *One `#panel` action with a `tab` param*: Slightly less code but worse for routing, testing clarity, and discoverability. Two named actions are cheaper to reason about.

### Decision 3: Overdue tasks become a team alert box, not a generic widget

Today's admin-only "all overdue tasks" widget ([dashboard_controller.rb:76](app/controllers/dashboard_controller.rb#L76)) is removed. In the new design it becomes an alert-style box on the Team tab — same visual treatment as pending conversions and stale proposals. Rationale: in a flat org, an overdue task on any consultant's record is the team's signal that something is slipping; it should look and feel like the other slip-detection alerts, not like a generic browse list.

Like the other team alerts, it is non-dismissible — it disappears when the underlying task is completed, cancelled, or its due date is moved into the future.

### Decision 4: Per-type alert boxes instead of a mixed alert column

Today, alerts of different types are stacked together in a single column ([index.html.erb:24-50](app/views/dashboard/index.html.erb#L24-L50)). The new layout dedicates one box per alert type (pending conversions, stale proposals, overdue tasks). Each box is shown only when it has at least one alert — empty boxes are not rendered. This makes scanning each category independent and avoids interleaving by chronology or arrival order.

### Decision 5: KPI strip outside the tab frames

The KPI strip lives in the `#index` shell template, above the tabs. It renders three team-wide metrics computed in `#index`. This costs three lightweight aggregate queries on every shell load but matches the "always visible" requirement and avoids duplicating the strip into both panel templates.

**Alternatives considered:**
- *Strip inside each panel*: Either duplicates the data load or makes the strip vanish briefly during lazy loading of the Mine tab. Not worth it.

### Decision 6: Remove all admin gating on the dashboard

The `current_user.admin?` branches in the controller and view are deleted, not refactored or hidden behind a feature flag. The flat-org policy is the project's actual stance, not a transitional state.

The `User#admin?` method itself is **not** touched — admins still have privileges elsewhere (user management). Only the dashboard's use of admin gating is removed.

## Risks / Trade-offs

- **[Risk] Lazy frame request 404s or errors silently** → Mitigation: panel actions are tested with controller tests that assert success, including for users with no records (empty-state). Turbo Frames surface broken responses in the frame body.
- **[Risk] Stimulus tab controller and Turbo Frame `loading="lazy"` interact unexpectedly** → Mitigation: integration test that asserts the Mine frame is initially hidden and not requested, then becomes visible and triggers the request after a tab click. Use Capybara with a JS driver if needed; otherwise a system test.
- **[Risk] Empty Team tab on a brand-new instance feels broken** → Mitigation: each empty alert/widget renders a calm "Nothing here" empty state; the Team tab is never fully blank because at least the open-proposals widget exists.
- **[Trade-off] Three KPI queries on every shell load** → Accepted: small team, the queries are simple aggregates, no caching is allowed by spec, and the strip is always visible by design.
- **[Trade-off] Two extra routes/actions to maintain** → Accepted: clearer separation than overloading a single controller action with branching on a `tab` param.
- **[Trade-off] Loss of admin-only "all overdue tasks across the team" framing** → Replaced by the team-visible Overdue Tasks alert box, which is strictly more visible (every consultant sees it, not just admins).

## Migration Plan

This is a UI restructure with no data migration. Deploy in a single release:

1. Add new routes for `team_panel` and `mine_panel`.
2. Refactor `DashboardController` (extract per-tab data loaders, add panel actions, drop admin block).
3. Replace `app/views/dashboard/index.html.erb` with the new shell template.
4. Add `app/views/dashboard/team_panel.html.erb` and `app/views/dashboard/mine_panel.html.erb` plus per-widget partials.
5. Add Stimulus tab controller (`app/javascript/controllers/dashboard_tabs_controller.js`).
6. Update `dashboard_controller_test.rb`: collapse admin/consultant test cases, add coverage for the two panel actions and the empty-state of each.
7. Run `bin/ci` and verify.

No rollback complexity beyond `git revert` — no schema changes, no background jobs, no external integrations.
