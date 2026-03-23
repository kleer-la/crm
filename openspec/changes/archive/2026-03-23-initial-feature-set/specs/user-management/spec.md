## ADDED Requirements

### Requirement: Admin assigns roles to pending users
The system SHALL allow Admins to assign a role (Consultant or Admin) to pending users who have self-registered via Google OAuth. Once a role is assigned, the user gains access to the application.

#### Scenario: Admin assigns role to a pending user
- **WHEN** an Admin assigns the Consultant role to a pending user
- **THEN** the user can access the application on their next page load

#### Scenario: Non-admin attempts user management
- **WHEN** a Consultant attempts to access the user management page
- **THEN** the system denies access

### Requirement: Admin deactivates and reactivates users
The system SHALL allow Admins to deactivate user accounts. Deactivated users SHALL NOT be able to log in. All records and activity log entries created by the deactivated user SHALL be preserved and visible.

#### Scenario: Admin deactivates a user
- **WHEN** an Admin deactivates a user account
- **THEN** the user can no longer log in, and their name appears as "(Deactivated) Name" on all records and logs

#### Scenario: Admin reactivates a user
- **WHEN** an Admin reactivates a previously deactivated account
- **THEN** the user can log in again and their name displays normally

### Requirement: Deactivated users excluded from assignments
Deactivated users SHALL NOT appear as selectable options when assigning responsible or collaborating consultants on new or edited records.

#### Scenario: Assigning a consultant on a record
- **WHEN** a user opens the consultant assignment dropdown on any record
- **THEN** only active users with assigned roles appear as selectable options

### Requirement: Two roles — Consultant and Admin
The system SHALL support exactly two roles: Consultant (full read/write access to all records, can reassign ownership) and Admin (all Consultant permissions plus user account management and app configuration).

#### Scenario: Consultant accesses records
- **WHEN** a Consultant is logged in
- **THEN** they have full read/write access to all Prospects, Customers, Proposals, and Tasks

#### Scenario: Admin accesses admin features
- **WHEN** an Admin is logged in
- **THEN** they have all Consultant permissions plus access to user management and the admin dashboard

### Requirement: Admin views pending users
The system SHALL display pending users (self-registered, no role) in the user management page so Admins can assign roles.

#### Scenario: New user self-registers
- **WHEN** a new user signs in via Google OAuth
- **THEN** they appear in the Admin's user management page as pending
