## Context

The CRM application has all core modules implemented (Prospects, Customers, Proposals, Tasks, Pipeline, Dashboard, Search). The existing infrastructure includes:
- `NotificationPreference` model (user_id, notification_type, enabled) — already migrated
- Solid Queue configured for background job processing
- `ApplicationMailer` stub ready for mailer subclasses
- `ActivityLog` model with system events and touchpoints on all records
- `ConsultantAssignment` join model for collaborating consultants
- Top bar layout with a notification bell placeholder

Consultants currently have no proactive alerts — they must check the dashboard manually.

## Goals / Non-Goals

**Goals:**
- Deliver timely email reminders for tasks due tomorrow
- Notify responsible and collaborating consultants on proposal status changes
- Allow users to opt out of specific notification types
- Surface recent activity via an in-app notification bell (last 90 days)

**Non-Goals:**
- Real-time push notifications or WebSocket-based updates
- SMS or Slack notifications
- Email notifications for stale proposals (dashboard-only)
- Notification bell for records where the user is not responsible or collaborating
- Digest/summary emails

## Decisions

### 1. Daily Solid Queue job for task reminders

**Decision:** Schedule a recurring `TaskReminderJob` via Solid Queue that runs daily, queries tasks due tomorrow (Open/In Progress), checks notification preferences, and sends individual emails.

**Rationale:** A single daily job is simple and predictable. With ≤15 users and a small task volume, batch processing in one job is efficient. Solid Queue is already configured and avoids adding new dependencies.

**Alternatives considered:**
- *Per-task scheduled job at creation time*: More complex to manage (rescheduling on due date changes, cancelling on completion). Unnecessary for this scale.
- *Cron-based rake task*: Would work but Solid Queue's recurring job support is more Rails-idiomatic and doesn't require external cron setup.

### 2. Inline notification on proposal status change (via after_commit callback)

**Decision:** Trigger proposal status change emails from an `after_commit` callback on the Proposal model. The callback enqueues a `ProposalStatusNotificationJob` that sends emails to the responsible consultant and all collaborating consultants, respecting preferences.

**Rationale:** Status changes are user-initiated and infrequent. Enqueuing a background job from the callback keeps the request fast while ensuring delivery. The existing `after_commit` pattern is already used for activity logging.

**Alternatives considered:**
- *Controller-level trigger*: Would miss status changes from service objects (e.g., mark_as_won). Callback is more reliable.
- *Synchronous delivery*: Would slow down the request. Background job is better UX.

### 3. Notification model for in-app bell

**Decision:** Create a `Notification` model (user_id, activity_log_id, read boolean, created_at) that references ActivityLog entries. When activity is logged on a record, create Notification rows for each relevant consultant. The bell queries unread notifications for the current user.

**Rationale:** A separate model allows tracking read/unread state per user without modifying the immutable ActivityLog. It also enables efficient queries for the bell count badge.

**Alternatives considered:**
- *Query ActivityLog directly with joins*: Would work for display but can't track read/unread state. Would also require complex joins on both responsible_consultant and consultant_assignments.
- *Store notifications in session/cache*: Not persistent across sessions; would lose state on logout.

### 4. Use existing NotificationPreference model

**Decision:** Use the existing `NotificationPreference` model with `notification_type` values: `task_due_reminder`, `proposal_status_change`. Default to enabled (send notifications unless explicitly opted out).

**Rationale:** The model was created during the initial feature set specifically for this purpose. Default-enabled ensures consultants get notifications immediately without configuration.

## Risks / Trade-offs

- **Email deliverability depends on SMTP config** → SMTP settings are environment-configured; development uses letter_opener or similar. Production SMTP must be set up separately.
- **Daily job timing matters** → If the job runs at midnight, "due tomorrow" is straightforward. Document the expected schedule time. Solid Queue recurring jobs can be configured with a specific time.
- **Notification table growth** → With 15 users and moderate activity, growth is manageable. Add a cleanup job later if needed (not in scope).
- **Bell refresh requires page load** → Without WebSockets, the bell count only updates on navigation. Acceptable for this scale; Turbo Drive makes navigation fast.
