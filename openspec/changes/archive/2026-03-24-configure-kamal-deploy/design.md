## Context

The CRM app is a Rails 8 application using PostgreSQL, currently running only in development. Kamal 2 is already in the Gemfile and scaffolded (`config/deploy.yml`, `.kamal/secrets`, Dockerfile). The deploy config has placeholder values (IP `192.168.0.1`, registry `localhost:5555`, no proxy/SSL). The production database.yml expects `APP_DATABASE_PASSWORD` via ENV and connects to a local-ish PostgreSQL.

Target environment:
- **Server**: Hetzner VPS at `5.78.92.152` (Ubuntu/Debian assumed)
- **Domain**: `crm.kleer.la` with SSL via Let's Encrypt
- **Database**: PostgreSQL already running on the server
- **Registry**: Docker Hub under `carlospeix/crm`
- **Deploy user**: root (Kamal default) via SSH

## Goals / Non-Goals

**Goals:**
- Configure Kamal for a working first deploy (`kamal setup`)
- Enable HTTPS via Kamal's built-in proxy with Let's Encrypt
- Wire the app container to the host's PostgreSQL instance
- Keep secrets out of version control

**Non-Goals:**
- Multi-server or load-balanced setup
- CI/CD pipeline integration (future work)
- Running PostgreSQL as a Kamal accessory
- Kamal hooks customization
- Custom health check endpoints
- Separate server for QA (same VPS, different service/domain)

## Decisions

### 1. Container-to-container PostgreSQL connectivity

**Decision**: Set `DB_HOST: postgres` in the deploy config. The `postgres` container (running `postgres:17`) and all Kamal-managed apps share the `kamal` Docker network, which Kamal 2 creates and uses by default. No extra network configuration is needed — Kamal automatically attaches app containers to the `kamal` network, where Docker DNS resolves container names.

**Why**: The server already has `kamal-proxy`, multiple Kamal-deployed apps (`fugazzeta`, `eventer`, `website17`), and a `postgres` container all on the `kamal` network. Setting `DB_HOST: postgres` is all that's needed for the app container to reach the database.

**Alternative considered**: `host-docker-internal` — not needed since PG is a container on the same network, not a host process.

### 2. Docker Hub as registry

**Decision**: Push images to `carlospeix/crm` on Docker Hub, authenticating with a personal access token stored in `KAMAL_REGISTRY_PASSWORD` env var.

**Why**: Docker Hub is the simplest option and the user already has an account. The access token (not password) follows Docker Hub best practices.

### 3. SSL via Kamal proxy

**Decision**: Enable `proxy.ssl: true` and `proxy.host: crm.kleer.la` in deploy.yml. Uncomment `config.assume_ssl` and `config.force_ssl` in production.rb.

**Why**: Kamal 2 uses kamal-proxy which handles Let's Encrypt certificate provisioning automatically. This is the standard approach — no need for an external reverse proxy or Cloudflare.

### 4. Secrets management

**Decision**: Source all secrets from environment variables in `.kamal/secrets`: `KAMAL_REGISTRY_PASSWORD`, `RAILS_MASTER_KEY` (already present via master.key file), and `APP_DATABASE_PASSWORD`.

**Why**: Keeps secrets out of git. The deployer sets these env vars before running kamal commands (via `.env`, `direnv`, or shell export).

### 5. QA deployment destination

**Decision**: Create `config/deploy.qa.yml` as a Kamal destination file. It overrides `service` to `crm-qa`, `proxy.host` to `qa.crm.kleer.la`, and `DB_HOST`/database env to point at separate QA databases. Deploy with `kamal setup -d qa` / `kamal deploy -d qa`.

**Why**: Kamal supports destinations natively — a destination file only needs to override the values that differ from the base `deploy.yml`. Running both on the same server with different service names and proxy hosts keeps things simple and cheap.

**Alternative considered**: Separate deploy.yml — rejected because destinations are the idiomatic Kamal approach and avoid duplicating the full config.

### 6. Database configuration in production.rb

**Decision**: Update `database.yml` production config to read `DB_HOST` from ENV (defaulting to `localhost`), so the Kamal env var wiring works without hardcoding IPs.

**Why**: The current config has no `host` key for production, which defaults to a Unix socket — but inside a Docker container there's no Unix socket to the host's PostgreSQL.

## Risks / Trade-offs

- **[Docker networking]** → Relies on the `postgres` container remaining on the `kamal` network with that name. If the PG container is recreated with a different name, `DB_HOST` must be updated. Mitigation: this is the established pattern on this server (other apps like fugazzeta and eventer use the same approach).
- **[Let's Encrypt rate limits]** → Failed attempts consume rate-limited requests. Mitigation: ensure DNS is pointing correctly before first deploy.
- **[Single server]** → No redundancy. Mitigation: acceptable for a small internal team CRM; can scale later.
- **[Storage volume]** → `app_storage:/rails/storage` is a named Docker volume. If the server is lost, Active Storage files and Solid Queue/Cache/Cable SQLite databases are lost. Mitigation: set up backups (out of scope for this change).
