## ADDED Requirements

### Requirement: Deployment model stores deploy metadata
The system SHALL store each deployment with: `version` (short SHA), `commit_sha` (full), `commit_url`, `commit_message`, `author`, `branch`, `environment`, `deployed_at`, and `deployed_by`.

#### Scenario: Valid deployment is persisted
- **WHEN** a deployment record is created with all required fields
- **THEN** the record SHALL be saved with version, commit_sha, commit_url, commit_message, author, branch, environment, deployed_at, and deployed_by

#### Scenario: deployed_at is required
- **WHEN** a deployment is created without deployed_at
- **THEN** validation SHALL fail

#### Scenario: commit_sha is required
- **WHEN** a deployment is created without commit_sha
- **THEN** validation SHALL fail

#### Scenario: deployed_at must be unique
- **WHEN** a deployment is created with a deployed_at matching an existing record
- **THEN** validation SHALL fail

### Requirement: Deployments are ordered newest first
The system SHALL provide a `recent` scope ordering deployments by `deployed_at` descending.

#### Scenario: Recent scope returns newest first
- **WHEN** multiple deployments exist
- **THEN** `Deployment.recent` SHALL return them ordered by deployed_at descending

### Requirement: Deployment auto-recorded on app boot
The system SHALL record the current deployment from the `BUILD_INFO` environment variable when the Rails server process boots. It SHALL NOT record in console or rake processes.

#### Scenario: BUILD_INFO present on server boot
- **WHEN** the Rails server boots with `BUILD_INFO` set to valid JSON
- **THEN** a new Deployment record SHALL be created from the parsed data

#### Scenario: Duplicate deployment is skipped
- **WHEN** the Rails server boots and a deployment with the same `deployed_at` already exists
- **THEN** no new record SHALL be created

#### Scenario: Missing BUILD_INFO is ignored
- **WHEN** the Rails server boots without `BUILD_INFO` set
- **THEN** no deployment SHALL be recorded and no error SHALL be raised

#### Scenario: Invalid BUILD_INFO JSON is handled
- **WHEN** `BUILD_INFO` contains invalid JSON
- **THEN** the error SHALL be logged and no deployment SHALL be recorded

### Requirement: Build info script captures git metadata
The `scripts/generate_build_info.sh` script SHALL output JSON with keys: `app_name`, `version`, `commit_sha`, `commit_url`, `commit_message`, `author`, `branch`, `deployed_at`, `deployed_by`, and `environment`.

#### Scenario: Script outputs valid JSON
- **WHEN** the script runs in a git repository
- **THEN** it SHALL output JSON to stdout with commit SHA, message, author, branch, and timestamp
- **AND** `commit_url` SHALL point to `https://github.com/kleer-la/crm/commit/<sha>`
- **AND** `deployed_by` SHALL use `KAMAL_PERFORMER` if set, otherwise `whoami`
- **AND** `environment` SHALL use `KAMAL_DESTINATION` if set, otherwise `production`

### Requirement: Deployment history page accessible to all authenticated users
The system SHALL serve a deployment history page at `GET /system/deployments` accessible to any authenticated, active user.

#### Scenario: Authenticated user views deployment history
- **WHEN** an authenticated user requests `/system/deployments`
- **THEN** the page SHALL render with deployment detail and history table

#### Scenario: Unauthenticated user is redirected
- **WHEN** an unauthenticated user requests `/system/deployments`
- **THEN** they SHALL be redirected to the login page

### Requirement: Master-detail deployment view
The deployment history page SHALL show a detail card for the selected deployment and a paginated table of all deployments. By default, the latest deployment is selected.

#### Scenario: Default view shows latest deployment
- **WHEN** a user visits `/system/deployments` without query params
- **THEN** the detail card SHALL show the most recent deployment

#### Scenario: Selecting a past deployment
- **WHEN** a user visits `/system/deployments?id=<deployment_id>`
- **THEN** the detail card SHALL show that deployment's details
- **AND** the corresponding row in the history table SHALL be highlighted

#### Scenario: No deployments exist
- **WHEN** no deployments are recorded
- **THEN** the page SHALL show an informational message instead of the detail card and table

### Requirement: Deployment history is paginated
The history table SHALL display 20 deployments per page with pagination controls.

#### Scenario: More than 20 deployments
- **WHEN** more than 20 deployments exist
- **THEN** pagination controls SHALL appear
- **AND** each page SHALL show at most 20 records

### Requirement: Sidebar shows last deployment date
The sidebar SHALL display the last deployment date at the bottom, formatted as "Deployed: YYYY-MM-DD HH:MM", linking to `/system/deployments`.

#### Scenario: Deployments exist
- **WHEN** the sidebar renders and at least one deployment exists
- **THEN** the footer SHALL show "Deployed: <date>" linking to `/system/deployments`

#### Scenario: No deployments exist
- **WHEN** the sidebar renders and no deployments exist
- **THEN** no deployment footer SHALL be displayed

### Requirement: BUILD_INFO added as Kamal secret
`BUILD_INFO` SHALL be listed as a secret in `.kamal/secrets` and passed as an env var in `config/deploy.yml`. The QA destination SHALL also receive `BUILD_INFO`.

#### Scenario: Production deploy includes BUILD_INFO
- **WHEN** deploying to production
- **THEN** `BUILD_INFO` SHALL be available as an environment variable in the container

#### Scenario: QA deploy includes BUILD_INFO
- **WHEN** deploying to QA
- **THEN** `BUILD_INFO` SHALL be available as an environment variable in the container
