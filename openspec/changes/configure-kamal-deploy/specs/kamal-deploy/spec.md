## ADDED Requirements

### Requirement: Deploy configuration targets production server
The `config/deploy.yml` SHALL configure deployment to server `5.78.92.152` with service name `crm`, image `carlospeix/crm`, and `amd64` architecture.

#### Scenario: Deploy config has correct server and image
- **WHEN** `config/deploy.yml` is loaded
- **THEN** `servers.web` SHALL contain `5.78.92.152`
- **AND** `image` SHALL be `carlospeix/crm`
- **AND** `service` SHALL be `crm`

### Requirement: SSL proxy is enabled with domain
The deploy configuration SHALL enable Kamal's proxy with SSL via Let's Encrypt for domain `crm.kleer.la`.

#### Scenario: Proxy SSL configuration is present
- **WHEN** `config/deploy.yml` is loaded
- **THEN** `proxy.ssl` SHALL be `true`
- **AND** `proxy.host` SHALL be `crm.kleer.la`

### Requirement: Docker Hub registry is configured
The deploy configuration SHALL use Docker Hub as the container registry with username `carlospeix` and password sourced from the `KAMAL_REGISTRY_PASSWORD` secret.

#### Scenario: Registry points to Docker Hub
- **WHEN** `config/deploy.yml` is loaded
- **THEN** `registry.server` SHALL be absent or default (Docker Hub)
- **AND** `registry.username` SHALL be `carlospeix`
- **AND** `registry.password` SHALL reference `KAMAL_REGISTRY_PASSWORD`

### Requirement: Container environment connects to PostgreSQL container
The deploy configuration SHALL pass `DB_HOST` and `APP_DATABASE_PASSWORD` so the app can reach the PostgreSQL container via the shared `kamal` Docker network.

#### Scenario: Database environment variables are set
- **WHEN** the app container starts
- **THEN** `DB_HOST` SHALL be set to `postgres` in clear env (the PG container name, resolved via Docker DNS on the `kamal` network)
- **AND** `APP_DATABASE_PASSWORD` SHALL be passed as a secret env var

### Requirement: Rails production enforces SSL
`config/environments/production.rb` SHALL have `config.assume_ssl = true` and `config.force_ssl = true` enabled.

#### Scenario: SSL settings are active in production
- **WHEN** Rails boots in production environment
- **THEN** `config.assume_ssl` SHALL be `true`
- **AND** `config.force_ssl` SHALL be `true`

### Requirement: Secrets sourced from environment variables
`.kamal/secrets` SHALL read `KAMAL_REGISTRY_PASSWORD`, `RAILS_MASTER_KEY`, and `APP_DATABASE_PASSWORD` from environment variables, never from hardcoded values.

#### Scenario: Secrets file references environment
- **WHEN** `.kamal/secrets` is evaluated
- **THEN** `KAMAL_REGISTRY_PASSWORD` SHALL be read from `$KAMAL_REGISTRY_PASSWORD`
- **AND** `RAILS_MASTER_KEY` SHALL be read from `cat config/master.key`
- **AND** `APP_DATABASE_PASSWORD` SHALL be read from `$APP_DATABASE_PASSWORD`

### Requirement: QA destination deploys to same server with separate domain
A Kamal destination file `config/deploy.qa.yml` SHALL exist that overrides the service name to `crm-qa`, proxy host to `qa.crm.kleer.la`, and database name to QA-specific databases, allowing deployment via `kamal setup -d qa`.

#### Scenario: QA destination file overrides production values
- **WHEN** `config/deploy.qa.yml` is loaded as a Kamal destination
- **THEN** `service` SHALL be `crm-qa`
- **AND** `proxy.host` SHALL be `qa.crm.kleer.la`
- **AND** `proxy.ssl` SHALL be `true`
- **AND** the database environment SHALL reference QA-specific database names

### Requirement: Production database config reads host from ENV
`config/database.yml` production section SHALL read the database host from the `DB_HOST` environment variable.

#### Scenario: Database host is configurable via ENV
- **WHEN** Rails loads `database.yml` in production
- **THEN** the `host` key SHALL use `ENV["DB_HOST"]`
