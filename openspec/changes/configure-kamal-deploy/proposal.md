## Why

The Rails CRM app needs to be deployed to production for the first time. Kamal is already included in the project but the configuration still has placeholder values. Configuring Kamal properly will enable repeatable, zero-downtime Docker-based deployments to the team's VPS with SSL via Let's Encrypt.

## What Changes

- Update `config/deploy.yml` with real server IP (`5.78.92.152`), Docker Hub registry (`carlospeix/crm`), domain (`crm.kleer.la`), and proxy SSL settings.
- Add a QA deployment destination (`config/deploy.qa.yml`) for `qa.crm.kleer.la` on the same server, using a separate database and Docker service name.
- Update `.kamal/secrets` to supply `KAMAL_REGISTRY_PASSWORD` and `APP_DATABASE_PASSWORD` from environment variables.
- Add `DB_HOST` and `APP_DATABASE_PASSWORD` to the container environment so the app connects to the existing PostgreSQL on the server.
- Enable `config.assume_ssl` and `config.force_ssl` in `config/environments/production.rb` (required when using Kamal's SSL proxy).
- Provide a step-by-step first-deploy runbook covering server preparation, DNS, secrets, and the `kamal setup` command.

## Capabilities

### New Capabilities
- `kamal-deploy`: Production deployment configuration via Kamal — covers deploy.yml, secrets, SSL proxy, registry, and environment wiring.

### Modified Capabilities

_None — this is infrastructure configuration only; no domain behavior changes._

## Impact

- **Files changed**: `config/deploy.yml`, `config/deploy.qa.yml`, `.kamal/secrets`, `config/environments/production.rb`
- **Dependencies**: Requires Docker Hub credentials (access token), the Rails master key, and the production database password to be available as environment variables or in a password manager.
- **Infrastructure**: The target VPS (`5.78.92.152`) must have Docker installed and SSH access configured for the deploy user. PostgreSQL must be running and accessible from Docker containers on the same host. DNS for both `crm.kleer.la` and `qa.crm.kleer.la` must point to the server IP.
