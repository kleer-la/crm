## 1. Project Setup

- [x] 1.1 Initialize Rails 8 app with PostgreSQL, Hotwire (Turbo + Stimulus), and Tailwind CSS
- [x] 1.2 Configure database.yml and create development/test databases
- [x] 1.3 Set up environment variables (credentials/dotenv) for Google OAuth client ID/secret and SMTP settings
- [x] 1.4 Configure Solid Queue for background job processing

## 2. Database Schema & Models

- [x] 2.1 Generate User model (name, email, role enum [pending/consultant/admin], active flag, google_uid, avatar_url)
- [x] 2.2 Generate Prospect model (company_name, primary_contact_name, primary_contact_email, primary_contact_phone, industry, source enum, status enum, estimated_value, disqualification_reason, converted_customer_id, responsible_consultant_id, date_added, last_activity_date)
- [x] 2.3 Generate Customer model (company_name, industry, status enum, total_revenue, date_became_customer, last_activity_date, responsible_consultant_id)
- [x] 2.4 Generate Contact model (name, email, phone, role_title, primary flag, customer_id FK)
- [x] 2.5 Generate Proposal model (title, linkable polymorphic [Prospect/Customer], status enum, estimated_value, final_value, date_sent, expected_close_date, actual_close_date, win_loss_reason, notes, current_document_url, responsible_consultant_id)
- [x] 2.6 Generate DocumentVersion model (label, url, proposal_id FK, archived_by_id FK, archived_at)
- [x] 2.7 Generate Task model (title, linkable polymorphic [Prospect/Customer/Proposal], assigned_to_id FK, due_date, priority enum, status enum, cancellation_reason, completed_at, notes)
- [x] 2.8 Generate ActivityLog model (loggable polymorphic, user_id FK, entry_type enum [system/touchpoint], touchpoint_type enum [call/email/meeting/note], content, created_at)
- [x] 2.9 Generate NotificationPreference model (user_id FK, notification_type, enabled flag)
- [x] 2.10 Create ConsultantAssignment join model (user_id, assignable polymorphic) for collaborating consultants
- [x] 2.11 Add database indexes (polymorphic type+id, status fields, due dates, unique constraints on company_name, unique on email) and run migrations

## 3. Authentication & Authorization

- [x] 3.1 Install omniauth-google-oauth2 gem and configure OmniAuth middleware with Google credentials
- [x] 3.2 Create SessionsController with Google OAuth callback: find or create User by google_uid/email, set session
- [x] 3.3 Implement pending user flow: redirect users with no role to a "waiting for approval" page
- [x] 3.4 Implement deactivated user flow: deny login and show deactivation message
- [x] 3.5 Add `require_authenticated_user` and `require_active_role` before_action filters in ApplicationController
- [x] 3.6 Add `require_admin` before_action filter for admin-only controllers
- [x] 3.7 Create login page with Google sign-in button and error states
- [x] 3.8 Create "waiting for approval" page for pending users

## 4. User Management (Admin)

- [x] 4.1 Build Admin::UsersController with index (list all users grouped by status: pending, active, deactivated)
- [x] 4.2 Implement assign role action (Admin sets pending user to Consultant or Admin)
- [x] 4.3 Implement deactivate/reactivate user actions
- [x] 4.4 Add "(Deactivated) Name" display helper used across the app
- [x] 4.5 Build user management views with Turbo Frames for inline role assignment

## 5. Shared Layout & Components

- [x] 5.1 Create application layout (sidebar nav, top bar with user menu and notification bell placeholder, mobile-responsive)
- [x] 5.2 Build reusable form partials (text input, select, multi-select, date picker, currency input, URL input with validation)
- [x] 5.3 Build reusable sortable/filterable table partial with Stimulus controller for filter controls
- [x] 5.4 Build consultant selector partial (single and multi-select, scoped to active users with roles)
- [x] 5.5 Build activity log timeline partial (chronological entries display)
- [x] 5.6 Build touchpoint logging form partial (type selector: Call/Email/Meeting/Note + description textarea)

## 6. Activity Log System

- [x] 6.1 Create ActivityLog model with readonly? override (returns true for persisted records), no update/destroy routes
- [x] 6.2 Create Loggable concern: shared methods for models that have activity logs (has_many :activity_logs, as: :loggable)
- [x] 6.3 Implement after_commit callbacks on Prospect, Customer, Proposal for automatic system event logging (status changes, creation, assignment changes, conversions, document link updates)
- [x] 6.4 Create TouchpointsController for manual touchpoint logging with type and description validation
- [x] 6.5 Auto-update last_activity_date on parent record when activity is logged

## 7. Prospects Module

- [x] 7.1 Create Prospect model validations: required fields, company_name uniqueness (across Prospects + Customers), email uniqueness (across Prospects + Customer contacts)
- [x] 7.2 Build ProspectsController with full CRUD actions
- [x] 7.3 Create Prospect list view with filtering by all fields and column sorting
- [x] 7.4 Create Prospect show/edit views with all fields and status management
- [x] 7.5 Implement Disqualify action with required reason validation
- [x] 7.6 Implement Convert to Customer service object: create Customer, re-link Proposals, mark Prospect read-only with converted_customer reference
- [x] 7.7 Add touchpoint logging and activity log display on Prospect show page
- [x] 7.8 Implement consultant reassignment (responsible + collaborating) with activity log entries

## 8. Customers Module

- [x] 8.1 Create Customer model validations: required fields, company_name uniqueness, at least one contact
- [x] 8.2 Build CustomersController with full CRUD actions
- [x] 8.3 Create Customer list view with filtering and sorting
- [x] 8.4 Create Customer show/edit views with all fields and status management
- [x] 8.5 Build nested ContactsController: add/edit/remove contacts, primary flag enforcement (exactly one primary), prevent deleting last contact
- [x] 8.6 Implement auto-calculated total_revenue (sum of final_value from Won proposals) via callback/query
- [x] 8.7 Build Customer full history timeline partial (linked Proposals, Tasks, activity log in chronological order)
- [x] 8.8 Add touchpoint logging on Customer show page

## 9. Proposals Module

- [x] 9.1 Create Proposal model validations: required fields, win/loss reason required for Won/Lost, URL format for document link
- [x] 9.2 Build ProposalsController with full CRUD and status transition actions
- [x] 9.3 Create Proposal list view with filtering and sorting
- [x] 9.4 Create Proposal show/edit views with all fields and status workflow
- [x] 9.5 Implement Mark as Won: require reason, prompt Prospect conversion via Turbo modal if linked to Prospect, create pending-conversion condition if skipped
- [x] 9.6 Implement Mark as Lost: require reason, auto-set actual close date
- [x] 9.7 Implement document link management: URL validation, archive prompt (Turbo Frame) when replacing existing link
- [x] 9.8 Build document version history display (immutable entries)
- [x] 9.9 Implement Duplicate Proposal action (copy fields except status, dates, document links → new Draft)
- [x] 9.10 Implement guard: cannot set Won on Proposal linked to Disqualified Prospect

## 10. Tasks Module

- [x] 10.1 Create Task model validations: due_date not in past on creation, cancellation_reason required for Cancelled
- [x] 10.2 Build TasksController with CRUD, status transitions, and reassignment
- [x] 10.3 Create Task list view with filtering, sorting, and overdue visual flagging (Stimulus controller for highlight)
- [x] 10.4 Create Task show/edit views with status transitions (Open → In Progress → Done/Cancelled)
- [x] 10.5 Implement Mark as Done with automatic completed_at timestamp
- [x] 10.6 Implement Cancel with required reason validation
- [x] 10.7 Add task creation from Prospect, Customer, and Proposal show pages (Turbo Frame form)

## 11. Pipeline View

- [x] 11.1 Create PipelineController with index action: query active Prospects + open Proposals, apply combined AND filters
- [x] 11.2 Build Pipeline list view with summary bar (total pipeline value, open proposal count, active prospect count)
- [x] 11.3 Implement filter controls (consultant, status, date range, value range) with Stimulus controller
- [x] 11.4 Add overdue expected close date highlighting and click-through links to detail records

## 12. Dashboard

- [ ] 12.1 Create DashboardController: query personal metrics (my pipeline value, proposals sent/won this month)
- [ ] 12.2 Build personal dashboard view: my open tasks (overdue first), my proposals by status, my active prospects, recent activity
- [ ] 12.3 Implement stale proposal scopes (open proposals with no activity in 30 days) and display on personal dashboard
- [ ] 12.4 Build team alert widget partial: pending-conversion alerts (Won Proposal + unconverted Prospect) and team-wide stale proposals, computed via scopes
- [ ] 12.5 Ensure alerts link to relevant records and cannot be manually dismissed
- [ ] 12.6 Build Admin dashboard section: team-wide metrics and all overdue tasks, conditionally rendered for Admin role

## 13. Global Search

- [ ] 13.1 Add pg_search gem, configure trigram indexes on Prospect (company_name), Customer (company_name), Proposal (title)
- [ ] 13.2 Create SearchController with cross-model search action returning typed results
- [ ] 13.3 Build search UI in top bar with Stimulus controller: input field, results dropdown with record type labels and linked company

## 14. Notifications

- [ ] 14.1 Configure Action Mailer with SMTP settings for transactional email
- [ ] 14.2 Create TaskReminderMailer and recurring Solid Queue job for daily task-due-tomorrow emails
- [ ] 14.3 Create ProposalStatusMailer, enqueue via after_commit on Proposal status change (exclude document links from email)
- [ ] 14.4 Build notification preferences in user profile (opt-out per notification type) with NotificationPreference model
- [ ] 14.5 Build in-app notification bell: query recent activity (last 90 days) on user's records, render in dropdown via Turbo Frame

## 15. Reports

- [ ] 15.1 Create ReportsController with actions for each report: proposals_by_status, won_vs_lost, pipeline_by_consultant, customer_revenue
- [ ] 15.2 Build report views with date range and consultant filter controls
- [ ] 15.3 Implement CSV export (respond_to :csv with send_data) for all reports, monetary values in USD
- [ ] 15.4 Verify reports query live data at generation time

## 16. Polish & Validation

- [ ] 16.1 Ensure mobile-responsive layout across all pages (Tailwind breakpoints)
- [ ] 16.2 Add flash messages and form error displays across all modules
- [ ] 16.3 Verify cross-model uniqueness constraints (company name, email) with integration tests
- [ ] 16.4 Verify converted Prospect is read-only and Proposals re-link correctly
- [ ] 16.5 Write system tests for full Prospect → Customer → Proposal → Task lifecycle
