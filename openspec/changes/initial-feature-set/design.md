## Context

The consulting team (6-15 people) manages customer relationships via spreadsheets, leading to data conflicts, missed follow-ups, and lack of pipeline visibility. This is a greenfield build of a lightweight internal CRM web application. There are no existing systems to integrate with beyond Google OAuth for authentication. The app stores Google Drive links as plain URLs but never calls the Drive API.

## Goals / Non-Goals

**Goals:**
- Build a single-source-of-truth web application for the team's CRM workflow
- Support the full lifecycle: Prospects → Customers → Proposals → Tasks
- Provide pipeline visibility, dashboards, and basic reporting
- Keep the system simple and maintainable for a small team
- Mobile-responsive browser-based UI

**Non-Goals:**
- Enterprise-scale CRM features (forecasting, advanced analytics, workflow automation)
- Native mobile applications
- Google Drive API integration or any file storage
- Email integration (sending/reading emails from the app)
- Contract, invoice, or billing management
- Multi-currency support
- Kanban board views (v1 is list-only)
- Data migration tooling
- Public-facing customer portal

## Decisions

### 1. Tech Stack: Rails 8 + Hotwire + PostgreSQL

**Decision:** Use Ruby on Rails 8 with PostgreSQL, Hotwire (Turbo + Stimulus) for interactivity, and Tailwind CSS for styling.

**Rationale:** This is a classic CRUD app with relational data, background jobs, and server-rendered views — Rails' sweet spot. ActiveRecord provides first-class support for associations, validations, callbacks, and polymorphic references. Hotwire handles the interactivity needs (dashboards, filters, forms) without a heavy JS framework. The team lead has deep Rails experience.

**Alternatives considered:**
- *Next.js + Prisma*: Capable but requires more plumbing for features Rails provides out of the box (background jobs, mailers, polymorphic associations). Overkill client-side framework for this UI complexity.
- *Separate SPA + API*: More operational overhead for a 15-user internal tool.

### 2. Authentication: OmniAuth with Google OAuth2

**Decision:** Use the `omniauth-google-oauth2` gem for authentication. Any Google user can sign in, which auto-creates a User record in a "pending" state (no role). The user cannot access any app functionality until an Admin assigns them a role (Consultant or Admin). Sessions are managed via Rails' built-in cookie session store.

**Rationale:** OmniAuth is the standard Rails solution for OAuth. Self-registration with admin approval keeps onboarding simple while maintaining access control. No username/password — Google OAuth is the sole login method.

**Alternatives considered:**
- *Devise + OmniAuth*: Devise adds unnecessary complexity (password recovery, confirmation, etc.) when there's no password-based auth.
- *Rails 8 authentication generator*: Designed for session-based username/password auth, not applicable here.

### 3. Authorization: Role-based before_action filters

**Decision:** Implement role-based access control (pending, Consultant, Admin) via `before_action` filters in ApplicationController. All controllers require an authenticated user with an assigned role. Admin-only controllers add an additional admin check.

**Rationale:** Two roles with simple rules don't warrant a full RBAC framework like Pundit or CanCanCan. `before_action` filters are idiomatic Rails and keep authorization visible in controllers. Pending users (no role) are redirected to a "waiting for approval" page.

### 4. Database Schema: ActiveRecord polymorphic associations

**Decision:** Tasks and Activity Logs use Rails' built-in `belongs_to :linkable, polymorphic: true` to reference Prospects, Customers, or Proposals. Proposals use a similar polymorphic association for their linked company (Prospect or Customer).

**Rationale:** ActiveRecord's polymorphic association support handles the type+id pattern natively, including eager loading and querying. This is a well-understood Rails pattern.

**Alternatives considered:**
- *Separate join tables per entity type*: More tables, more migrations, same result at this scale.
- *STI (Single Table Inheritance) for Prospect/Customer*: Tempting since they share fields, but their lifecycles and field sets diverge enough that separate models are cleaner.

### 5. Activity Log: Append-only model with ActiveRecord callbacks

**Decision:** ActivityLog entries are created via `after_commit` callbacks on models and explicit logging in service objects. The model has no `update` or `destroy` actions exposed. A `readonly?` override returns true for persisted records.

**Rationale:** Immutability is a hard requirement. ActiveRecord callbacks keep logging co-located with the domain logic. `readonly?` prevents accidental updates at the ORM level.

### 6. Background Jobs: Solid Queue + Action Mailer

**Decision:** Use Solid Queue (Rails 8 default) for background job processing. Action Mailer handles email composition. A recurring job checks for tasks due in 1 day. Proposal status change notifications are enqueued via `after_commit` callbacks.

**Rationale:** Solid Queue ships with Rails 8 and uses the PostgreSQL database — no Redis dependency. Action Mailer is the standard Rails email solution with built-in delivery job support.

**Alternatives considered:**
- *Sidekiq + Redis*: More powerful but adds an infrastructure dependency unnecessary at this scale.

### 7. Search: PostgreSQL trigram search via pg_search gem

**Decision:** Use the `pg_search` gem with PostgreSQL trigram indexes for partial string matching across Prospects, Customers, and Proposals.

**Rationale:** At this scale, PostgreSQL's native search is sufficient. The `pg_search` gem provides a clean ActiveRecord interface for multi-model search.

### 8. Reports: Controller actions with CSV streaming

**Decision:** Reports are generated server-side via ActiveRecord queries against live data. CSV export uses Rails' `send_data` with Ruby's CSV stdlib. No caching layer.

**Rationale:** The dataset is small enough that live queries are performant. The spec requires reports to reflect current state. Ruby's CSV library makes export trivial.

### 9. Team Alert Widget: Scoped queries, no alerts table

**Decision:** Alerts (pending conversion, stale proposals) are computed on each dashboard load via ActiveRecord scopes. No separate alerts table.

**Rationale:** With few users and records, computing alerts on-the-fly is simpler than maintaining a separate alert lifecycle. Alerts auto-resolve when conditions change, as required by the spec.

### 10. Frontend: Hotwire (Turbo + Stimulus) + Tailwind CSS

**Decision:** Server-rendered views with Turbo Frames for partial page updates (e.g., inline editing, modal forms), Turbo Streams for live updates if needed, and Stimulus controllers for client-side behavior (dropdowns, filters, search). Tailwind CSS for styling with mobile-responsive layout.

**Rationale:** The UI is primarily forms, lists, and dashboards — no complex client-side state. Hotwire keeps the frontend simple and server-driven.

## Risks / Trade-offs

- **[Polymorphic associations]** Rails polymorphic associations can't enforce foreign key constraints at the DB level → Data integrity relies on application validations. **Mitigation:** Add model-level validations; add CHECK constraints on type columns.

- **[Live-computed alerts]** Dashboard load time increases with data volume → At scale, this could slow down. **Mitigation:** Acceptable for 15 users. Add database indexes on status and date fields. Revisit if load times degrade.

- **[Single currency]** USD-only is hardcoded → Adding multi-currency later requires schema and UI changes. **Mitigation:** Store amounts as `decimal(12,2)` columns with an explicit currency column defaulting to "USD", making future extension easier.

- **[Email delivery]** Transactional email requires SMTP/provider setup → Emails may fail silently. **Mitigation:** Solid Queue retries; Action Mailer delivery logging; surface failures in admin dashboard in a future iteration.

- **[Self-registration approval lag]** New users who sign in sit in a pending state until an Admin assigns a role → Could cause confusion. **Mitigation:** Show a clear "waiting for approval" page; optionally notify Admins when a new user registers.
