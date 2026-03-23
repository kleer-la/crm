## 1. Notification Model & Migration

- [ ] 1.1 Generate Notification model (user_id FK, activity_log_id FK, read boolean default false, created_at) with indexes on user_id and activity_log_id
- [ ] 1.2 Add Notification model validations, associations (belongs_to :user, belongs_to :activity_log), and scopes (unread, recent — last 90 days)

## 2. Email Notifications

- [ ] 2.1 Create TaskReminderMailer with task_due_reminder email (task title, due date, link to task)
- [ ] 2.2 Create ProposalNotificationMailer with status_changed email (proposal title, old/new status, link to proposal — no document URLs)
- [ ] 2.3 Create TaskReminderJob (Solid Queue recurring job): query tasks due tomorrow with status Open/In Progress, check notification preferences, send emails
- [ ] 2.4 Create ProposalStatusNotificationJob: send status change emails to responsible + collaborating consultants, respecting preferences
- [ ] 2.5 Add after_commit callback on Proposal to enqueue ProposalStatusNotificationJob on status change

## 3. Notification Preferences

- [ ] 3.1 Create NotificationPreferencesController with edit/update actions for current user's preferences
- [ ] 3.2 Build notification preferences view with toggles for task_due_reminder and proposal_status_change
- [ ] 3.3 Add helper method on User model: `notifications_enabled?(type)` — returns true if no preference record exists or preference is enabled
- [ ] 3.4 Add route and link to notification preferences from user profile menu

## 4. In-App Notification Bell

- [ ] 4.1 Create NotificationsController with index (bell dropdown), mark_read (single), and mark_all_read actions
- [ ] 4.2 Add callback on ActivityLog creation to generate Notification records for responsible + collaborating consultants on the parent record
- [ ] 4.3 Build notification bell UI in top bar: unread count badge, dropdown with recent notifications (last 90 days), "Mark all as read" link
- [ ] 4.4 Create Stimulus controller for notification bell dropdown toggle and mark-as-read via Turbo
- [ ] 4.5 Add notification bell routes (index, mark_read, mark_all_read)
