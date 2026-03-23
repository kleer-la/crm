## Why

The consulting team (6-15 people) currently manages customer relationships, proposals, pipeline tracking, and follow-up tasks using spreadsheets. This leads to duplicate/conflicting data, missed follow-ups, and no single source of truth. A lightweight internal CRM web application will centralize this workflow and give the team real-time visibility into the pipeline.

## What Changes

- Introduce Google OAuth authentication with Admin-provisioned user accounts and two roles (Consultant, Admin)
- Add Prospect management with full lifecycle (create, qualify, disqualify, convert to Customer)
- Add Customer management with multi-contact support and automatic revenue calculation from won proposals
- Add Proposal tracking with status workflow (Draft through Won/Lost/Cancelled), document link management, and version history
- Add Tasks & Follow-ups tied to any record, with due date enforcement and overdue flagging
- Add a filterable Pipeline view showing active Prospects and open Proposals with summary metrics
- Add personal and admin Dashboards with open tasks, proposals, activity feeds, key metrics, and a team alert widget for pending conversions and stale proposals
- Add an immutable Activity Log on every record (system events + manual touchpoints)
- Add global search across Prospects, Customers, and Proposals with partial string matching
- All monetary values in USD only
- No Google Drive API integration (links stored as plain URLs)

## Capabilities

### New Capabilities
- `google-auth`: Google OAuth login, session management, Admin-provisioned accounts, account deactivation/reactivation
- `user-management`: User roles (Consultant, Admin), user CRUD by Admins, deactivated user handling across the app
- `prospects`: Prospect records with full lifecycle — create, qualify, disqualify, convert to Customer; unique company/email constraints
- `customers`: Customer records with multi-contact management, primary contact enforcement, auto-calculated revenue
- `proposals`: Proposal metadata tracking, status workflow with win/loss reasons, document link and version history management
- `tasks`: Tasks & follow-ups linked to any record, due date validation, overdue flagging, cancellation with reasons
- `pipeline-view`: Filterable list view of active Prospects and open Proposals with summary bar and combined filters
- `dashboard`: Personal dashboard (my tasks, proposals, prospects, activity, metrics, stale alerts), team alert widget, admin dashboard
- `activity-log`: Immutable chronological activity log on every record — system events and manual touchpoints
- `search-filters`: Global cross-entity search with partial matching; module-level filtering and sorting on all list views

### Modified Capabilities

_None — this is the initial feature set with no pre-existing capabilities._

## Impact

- **New web application**: Full-stack browser-based app with mobile-responsive layout (tech stack TBD)
- **Database**: New relational schema for users, prospects, customers, contacts, proposals, tasks, activity logs, notifications, and alerts
- **External dependencies**: Google OAuth API for authentication
- **No Google Drive API**: Document links stored as plain URLs only
- **Scale**: Designed for up to 15 concurrent users; no high-scale requirements
