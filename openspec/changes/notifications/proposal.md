## Why

The CRM currently has no proactive notification system. Consultants must manually check the dashboard for task deadlines and proposal updates, which leads to missed follow-ups and delayed responses. Adding email notifications and an in-app notification bell will keep the team informed without requiring them to constantly poll the application.

## What Changes

- Add email notifications for tasks due in 1 day (sent to assigned consultant)
- Add email notifications on Proposal status changes (sent to responsible + collaborating consultants)
- Add per-user notification preferences allowing opt-out of individual notification types
- Add in-app notification bell in the top bar showing recent activity on the user's records (last 90 days)
- Stale proposal alerts remain dashboard-only — they do not trigger email notifications

## Capabilities

### New Capabilities
- `email-notifications`: Email delivery for task due reminders and proposal status changes, respecting user opt-out preferences
- `notification-preferences`: Per-user settings to enable/disable individual notification types
- `notification-bell`: In-app notification bell showing recent activity on records where the user is responsible or collaborating consultant

### Modified Capabilities

_None — this builds on existing infrastructure (NotificationPreference model, Solid Queue, ActivityLog) without changing their requirements._

## Impact

- **Mailers**: New `TaskReminderMailer` and `ProposalNotificationMailer` using ActionMailer
- **Background jobs**: Solid Queue job for daily task reminder check; inline delivery for proposal status notifications
- **Database**: NotificationPreference model already exists (created in initial-feature-set); may need Notification model for bell state
- **UI**: Notification bell added to top bar layout; notification preferences page in user profile
- **External dependencies**: Requires SMTP configuration for email delivery (already stubbed in environment config)
