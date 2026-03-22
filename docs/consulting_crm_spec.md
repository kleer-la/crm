# Application Spec: Consulting CRM
**Version:** 1.3  
**Date:** March 2026  
**Target Users:** Small consulting team (6–15 people)

---

## 1. Overview

A lightweight internal web application to replace the current spreadsheet-based workflow for managing customer relationships, proposals, pipeline tracking, and follow-up tasks. The goal is a single source of truth that the whole team can access and update in real time.

---

## 2. Goals

- Eliminate duplicate or conflicting spreadsheets
- Give the team full visibility into the pipeline and proposal status at a glance
- Track the history of each customer relationship over time
- Reduce deals falling through the cracks due to missed follow-ups
- Keep it simple — not a full-blown enterprise CRM

---

## 3. Users & Roles

| Role | Description |
|---|---|
| **Consultant** | Full read/write access to all records; can reassign ownership of any record |
| **Admin** | All Consultant permissions, plus user account management and app configuration |

### 3.1 Authentication

- Login is exclusively via **Google OAuth** (no email/password option)
- Only users with accounts provisioned by an Admin can log in
- No guest or external access

### 3.2 User Account Management

- Admins can **deactivate** user accounts rather than delete them
- Deactivated users cannot log in
- All records and activity log entries created by a deactivated user are preserved and remain visible
- Deactivated users are shown as "(Deactivated) Name" in record fields and logs
- Admins can reactivate a deactivated account at any time

### 3.3 Constraints

- **MUST:** Every user must be authenticated before accessing any part of the app.
- **MUST:** Unauthenticated requests must redirect to the Google OAuth login flow.
- **MUST:** Only accounts explicitly provisioned by an Admin are permitted to log in, even if the Google account is valid.
- **MUST NOT:** The app must not support email/password login.
- **MUST:** Deactivating a user must not delete or alter any records they own or have contributed to.
- **MUST:** Deactivated users must not appear as selectable options when assigning responsible or collaborating consultants on new or edited records.

---

## 4. Core Modules

### 4.1 Prospects

Prospects are companies or individuals that have not yet become customers.

**Fields:**

| Field | Type | Required | Notes |
|---|---|---|---|
| Company name | Text | Yes | Must be unique |
| Primary contact name | Text | Yes | |
| Primary contact email | Email | Yes | Must be unique |
| Primary contact phone | Text | No | |
| Industry / sector | Text | No | |
| Source | Enum | No | `Referral` \| `Inbound` \| `Outbound` \| `Event` \| `Other` |
| Responsible consultant | User reference | Yes | The consultant who owns this record |
| Collaborating consultants | User reference (multi) | No | Typically 1–3; no hard maximum |
| Status | Enum | Yes | `New` \| `Contacted` \| `Qualified` \| `Disqualified` |
| Estimated potential value | Currency (USD) | No | |
| Date added | Date | Yes | Auto-set on creation |
| Last activity date | Date | Yes | Auto-updated on any activity |

**Key Actions:**

- **Convert to Customer:** Creates a new Customer record pre-populated from this Prospect's data. All Proposals linked to this Prospect are automatically re-linked to the new Customer record. The Prospect record is marked as `Converted`, becomes read-only, and a reference to the resulting Customer is stored on it.
- **Log a touchpoint:** Adds an entry to the activity log (call, email, meeting, note)
- **Reassign:** Change the responsible consultant or add/remove collaborating consultants
- **Disqualify:** Set status to `Disqualified`; requires a disqualification reason (free text)

**Constraints:**

- **MUST:** `Disqualified` status requires a non-empty reason before saving.
- **MUST:** A `Disqualified` Prospect cannot be converted to a Customer without first changing its status to an active state.
- **MUST:** Company name must be unique across all Prospects and Customers.
- **MUST:** Primary contact email must be unique across all Prospects and Customers.
- **MUST:** On conversion, all Proposals linked to the Prospect must be automatically re-linked to the new Customer record with no data loss.
- **MUST:** A converted Prospect record must store a reference (link) to the Customer it became.
- **MUST NOT:** A converted Prospect must not be editable after conversion.

---

### 4.2 Customers

Customers are companies with whom the firm has had at least one engagement.

**Fields:**

| Field | Type | Required | Notes |
|---|---|---|---|
| Company name | Text | Yes | Must be unique |
| Industry / sector | Text | No | |
| Contacts | Contact list | Yes | At least one; multiple allowed |
| Responsible consultant | User reference | Yes | |
| Collaborating consultants | User reference (multi) | No | Typically 1–3; no hard maximum |
| Status | Enum | Yes | `Active` \| `Inactive` \| `At Risk` |
| Total revenue to date | Currency (USD) | No | Auto-calculated from Won proposals |
| Date became a customer | Date | Yes | Auto-set on conversion; editable on manual creation |
| Last activity date | Date | Yes | Auto-updated on any activity |

**Contact sub-record fields:** name, email, phone, role/title, primary flag (exactly one contact must be flagged as primary at all times).

**Key Actions:**

- **View full history:** All linked Proposals, Tasks, and activity log entries displayed in a single chronological timeline
- **Add / edit contacts:** Manage the contact list; at least one contact must remain at all times
- **Log a touchpoint:** Adds an entry to the activity log
- **Change status:** Mark as `Active`, `Inactive`, or `At Risk`

**Constraints:**

- **MUST:** Every Customer must have exactly one contact flagged as primary at all times.
- **MUST:** Total revenue is read-only and recalculates automatically whenever a linked Proposal changes status.
- **MUST:** Company name must be unique across all Prospects and Customers.
- **MUST NOT:** The last remaining contact on a Customer record cannot be deleted.

---

### 4.3 Proposals

Proposals can be linked to either a Prospect or a Customer. The actual proposal documents are created and stored externally in Google Drive; this app stores metadata and links only — it does not read from, write to, or otherwise interact with Google Drive.

**Fields:**

| Field | Type | Required | Notes |
|---|---|---|---|
| Title | Text | Yes | |
| Linked company | Prospect or Customer reference | Yes | |
| Responsible consultant | User reference | Yes | |
| Collaborating consultants | User reference (multi) | No | Typically 1–3; no hard maximum |
| Status | Enum | Yes | `Draft` \| `Sent` \| `Under Review` \| `Won` \| `Lost` \| `Cancelled` |
| Estimated value | Currency (USD) | No | |
| Final value | Currency (USD) | No | Filled in when marking as Won |
| Date created | Date | Yes | Auto-set |
| Date sent | Date | No | Auto-set when status moves to `Sent`; editable |
| Expected close date | Date | No | |
| Actual close date | Date | No | Auto-set when status moves to `Won`, `Lost`, or `Cancelled`; editable |
| Win/loss reason | Text | Conditional | Required when status is set to `Won` or `Lost` |
| Notes | Long text | No | |
| Current document link | URL | No | Google Drive URL for the latest version |
| Document version history | List of (label, URL, date, user) | No | Archive of prior versions |

**Key Actions:**

- **Create:** Initiated from a Customer or Prospect record, or directly from the Proposals list
- **Update status:** Move through stages; `Won` and `Lost` require a reason
- **Mark as Won:** If linked to a Prospect, the user is prompted to convert the Prospect to a Customer; if the user skips conversion, a pending-conversion alert is added to the team alert widget (see Section 6.2)
- **Duplicate:** Creates a new `Draft` proposal copying all fields except status, dates, and document links
- **Update current document link:** Set or replace the Google Drive URL for the current version; if a current link already exists, the user is prompted to optionally archive it before replacing
- **Archive document version:** Save the current link to the version history with a user-supplied label and the current date; the archived entry records the user who performed the action

**Constraints:**

- **MUST:** `Won` and `Lost` statuses require a non-empty win/loss reason before saving.
- **MUST:** A Proposal linked to a `Disqualified` Prospect cannot be moved to `Won` without first changing the Prospect's status.
- **MUST:** Document links must be validated as well-formed URLs before saving.
- **MUST NOT:** The app must not attempt to read, write, or authenticate with Google Drive. Links are stored and displayed as plain URLs only.
- **SHOULD:** When the user replaces the current document link and a previous link exists, the app must prompt them to optionally archive the previous link before overwriting it.
- **MUST:** Version history entries are immutable once saved.
- **MUST:** When a Won Proposal is linked to a Prospect that has not yet been converted, a pending-conversion alert must be created and displayed in the team alert widget until the conversion is completed.

---

### 4.4 Tasks & Follow-ups

Tasks are tied to a specific record (Prospect, Customer, or Proposal).

**Fields:**

| Field | Type | Required | Notes |
|---|---|---|---|
| Title | Text | Yes | |
| Linked record | Prospect, Customer, or Proposal reference | Yes | |
| Assigned to | User reference | Yes | |
| Due date | Date | Yes | |
| Priority | Enum | Yes | `Low` \| `Medium` \| `High` |
| Status | Enum | Yes | `Open` \| `In Progress` \| `Done` \| `Cancelled` |
| Cancellation reason | Text | Conditional | Required when status is set to `Cancelled` |
| Notes | Long text | No | |

**Key Actions:**

- **Create:** From any Prospect, Customer, or Proposal record
- **Mark as done:** Sets status to `Done`; records a completion timestamp automatically
- **Reassign:** Change the assigned consultant
- **Cancel:** Sets status to `Cancelled`; requires a brief reason

**Constraints:**

- **MUST:** Due date is required at creation and cannot be set to a past date on a new task.
- **MUST:** `Cancelled` status requires a non-empty reason before saving.
- **SHOULD:** Overdue open tasks (due date < today, status `Open` or `In Progress`) must be visually flagged in all task list views.

---

## 5. Pipeline View

A filterable view showing all active Prospects and open Proposals, giving the team a quick read on the current state of the business.

**Features:**

- Display mode: list view in v1; kanban board is a future enhancement
- Filterable by: responsible consultant, collaborating consultant, status, expected close date range, estimated value range
- Summary bar: total pipeline value (open proposals), count of open proposals, count of active prospects
- Overdue expected close dates are visually highlighted
- Clicking any item opens the full detail record

**Constraints:**

- **MUST:** Proposals with status `Won`, `Lost`, or `Cancelled` must not appear in the pipeline view.
- **MUST:** Converted or Disqualified Prospects must not appear in the pipeline view.
- **MUST:** Filters must be combinable (AND logic).

---

## 6. Dashboard (Home Screen)

Each user lands on a personal dashboard after login.

### 6.1 Personal Dashboard

- My open tasks, sorted by due date (overdue first)
- My open proposals, grouped by status
- My active prospects
- Recent activity on records where I am the responsible or collaborating consultant
- Key metrics: my total pipeline value, proposals sent this month, proposals won this month
- **Stale proposal alerts:** any of my open proposals with no activity logged in the last 30 days (dashboard only; no email)

### 6.2 Team Alert Widget

A shared alert widget visible to **all users** on their dashboard. It surfaces team-wide items that require attention and cannot be dismissed by individuals — only resolved by acting on the underlying record.

**Alert types shown in this widget:**

| Alert type | Condition | Resolved when |
|---|---|---|
| Pending conversion | A Proposal has been marked Won but the linked Prospect has not yet been converted to a Customer | The Prospect is converted |
| Stale proposals (team) | An open Proposal has had no activity in the last 30 days | Activity is logged or the Proposal is closed |

**Constraints:**

- **MUST:** The team alert widget must be visible to every logged-in user, regardless of whether they are the responsible consultant on the flagged record.
- **MUST:** Each alert must link directly to the relevant record.
- **MUST:** A pending-conversion alert must be created automatically when a Proposal is marked Won and the linked Prospect remains unconverted.
- **MUST:** Alerts must disappear automatically once the underlying condition is resolved; no manual dismissal.
- **MUST NOT:** Alerts in this widget must not be dismissible by individual users.

### 6.3 Admin Dashboard (additional)

- Team-wide versions of all personal metrics
- All overdue open tasks across the team

**Constraints:**

- **MUST:** "My" records on the personal dashboard means records where the user is either the responsible or a collaborating consultant.
- **MUST:** All metrics are calculated from live data; no stale caching.
- **MUST:** A proposal is considered stale if no activity log entry has been recorded against it in the past 30 calendar days and its status is not `Won`, `Lost`, or `Cancelled`.

---

## 7. Notifications

### 7.1 Email Notifications

| Trigger | Recipient(s) |
|---|---|
| A task is due in 1 day | Assigned consultant |
| A Proposal status changes | Responsible consultant + all collaborating consultants |

### 7.2 In-App Notification Bell

Shows recent activity on records where the logged-in user is the responsible or collaborating consultant. Displays the last **90 days** of activity entries.

**Constraints:**

- **MUST:** Notification emails are sent to the user's Google account email address.
- **MUST NOT:** Notification emails must not include any Google Drive document links or document content.
- **SHOULD:** Users must be able to opt out of individual email notification types from their profile settings.
- **MUST:** The in-app notification bell must show entries from the last 90 days only; older entries remain accessible via the record's activity log.
- **MUST NOT:** Stale proposal alerts must not trigger email notifications; they are surfaced on the dashboard only.

---

## 8. Activity Log

Every record (Prospect, Customer, Proposal) maintains a chronological activity log on its detail page.

**Log entry types:**

| Type | Triggered by |
|---|---|
| System event | Status changes, record creation, assignment changes, document link updates, conversion events |
| Touchpoint | Manual entry by a user: call, email, meeting, or note |

**Each entry shows:** timestamp, user, entry type, and content/description.

**Constraints:**

- **MUST:** Activity log entries are immutable once created; no user or admin may edit or delete them.
- **MUST:** All system events must be logged automatically with no user action required.
- **MUST:** Manual touchpoint entries require a type selection (`Call` \| `Email` \| `Meeting` \| `Note`) and a non-empty description.

---

## 9. Search & Filters

- **Global search:** Searches across Companies (Prospects and Customers), Contacts, and Proposals by name; results show record type and linked company
- **Module-level filters:** Each list view supports filtering by any field and sorting by any column
- **Saved filters:** Out of scope for v1

**Constraints:**

- **MUST:** Global search must return results across all three entity types simultaneously.
- **MUST:** Search must match partial strings (e.g., "acme" matches "Acme Corp").
- **MUST:** Search results must clearly indicate the record type (Prospect, Customer, Proposal).

---

## 10. Data & Reporting

**All monetary values are in USD.**

**Reports available in v1:**

| Report | Description |
|---|---|
| Proposals by status | Count and total USD value grouped by status; filterable by date range and consultant |
| Won vs. Lost breakdown | Count and value of won/lost proposals over a selected period; includes win/loss reason summary |
| Pipeline by consultant | Open proposal count and total USD value per responsible consultant |
| Customer revenue summary | Total won proposal USD value per customer; sortable |

**Constraints:**

- **MUST:** All reports must be exportable to CSV.
- **MUST:** All reports must support filtering by date range at minimum.
- **MUST:** Report data must reflect the current state of the database at generation time.
- **MUST:** All monetary values in reports are displayed and exported in USD.

---

## 11. Technical Considerations

| Concern | Decision |
|---|---|
| **Architecture** | Web app (browser-based); mobile-responsive layout; no native mobile app |
| **Authentication** | Google OAuth only (see Section 3) |
| **Currency** | USD only; no multi-currency support in v1 |
| **Google Drive integration** | None — proposal document links stored as plain URLs; no API calls to Drive |
| **Data migration** | Out of scope for v1; to be addressed separately |
| **Tech stack** | To be decided; no constraints imposed by this spec |
| **Users** | Up to 15 concurrent users; no high-scale requirements |

---

## 12. Out of Scope (v1)

- Email integration (sending or reading emails from within the app)
- Contract or invoice management
- Native mobile app
- Advanced analytics or forecasting
- Public-facing portal for customers
- Automated workflows or triggers beyond task reminders and stale proposal alerts
- Saved/shared filters
- Kanban-style pipeline board
- Data migration tooling
- Multi-currency support
- Any read/write integration with Google Drive or other Google Workspace services

---

*End of Spec — v1.3*
