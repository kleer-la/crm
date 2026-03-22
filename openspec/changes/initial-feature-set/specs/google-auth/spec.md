## ADDED Requirements

### Requirement: Google OAuth login with self-registration
The system SHALL authenticate users exclusively via Google OAuth. Any Google user MAY sign in, which auto-creates a User record in a pending state (no role assigned). No email/password login SHALL be supported.

#### Scenario: First-time Google sign-in
- **WHEN** a user signs in with Google for the first time
- **THEN** the system creates a User record with no role (pending) and redirects to a "waiting for approval" page

#### Scenario: Returning user with assigned role
- **WHEN** a user with an assigned role (Consultant or Admin) signs in via Google
- **THEN** the system creates a session and redirects to the dashboard

#### Scenario: Returning user still pending
- **WHEN** a user with no assigned role signs in via Google
- **THEN** the system redirects to the "waiting for approval" page

#### Scenario: Deactivated user signs in
- **WHEN** a deactivated user signs in via Google
- **THEN** the system denies access and displays an error indicating the account has been deactivated

### Requirement: Pending users have no app access
Users without an assigned role SHALL NOT access any application functionality beyond the "waiting for approval" page.

#### Scenario: Pending user attempts to access a page
- **WHEN** a pending user navigates to any application route
- **THEN** the system redirects to the "waiting for approval" page

### Requirement: Unauthenticated access redirects to login
The system SHALL redirect unauthenticated requests to the Google OAuth login flow.

#### Scenario: Unauthenticated user visits any page
- **WHEN** an unauthenticated user requests any application route
- **THEN** the system redirects to the Google OAuth login flow

### Requirement: Session management
The system SHALL maintain authenticated sessions and provide a logout mechanism.

#### Scenario: User logs out
- **WHEN** an authenticated user clicks the logout button
- **THEN** the session is destroyed and the user is redirected to the login page

#### Scenario: Session expiry
- **WHEN** a user's session expires
- **THEN** the next request redirects to the Google OAuth login flow
