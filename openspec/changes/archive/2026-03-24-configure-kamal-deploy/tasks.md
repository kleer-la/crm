## 1. Production deploy configuration

- [x] 1.1 Update `config/deploy.yml`: set `service: crm`, `image: carlospeix/crm`, server IP `5.78.92.152`, enable `proxy.ssl: true` and `proxy.host: crm.kleer.la`, configure Docker Hub registry with `username: carlospeix` and password from `KAMAL_REGISTRY_PASSWORD`, pass `DATABASE_URL` as secret
- [x] 1.2 Update `.kamal/secrets`: add `KAMAL_REGISTRY_PASSWORD`, `RAILS_MASTER_KEY`, `DATABASE_URL`, `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`
- [x] 1.3 Enable SSL in `config/environments/production.rb`: uncomment `config.assume_ssl = true` and `config.force_ssl = true`

## 2. Database configuration

- [x] 2.1 Update `config/database.yml`: single `DATABASE_URL` for all databases (primary, cache, queue, cable) across all environments
- [x] 2.2 Create migrations for Solid Queue, Solid Cache, and Solid Cable tables in `db/migrate/`
- [x] 2.3 Update `config/cache.yml` and `config/cable.yml` to use primary database

## 3. QA destination

- [x] 3.1 Create `config/deploy.qa.yml` and `.kamal/secrets.qa` for QA destination with `DATABASE_URL_CRM_QA`

## 4. Production hardening

- [x] 4.1 Fix mailer host from `example.com` to `crm.kleer.la`
- [x] 4.2 Enable DNS rebinding protection (`config.hosts`) for `crm.kleer.la` and `qa.crm.kleer.la`
- [x] 4.3 Enable `raise_delivery_errors` for mailer (SMTP config deferred until needed)
- [x] 4.4 Disable undefined `TaskDueReminderJob` recurring task

## 5. First deploy

- [x] 5.1 Create production database on server and set env vars locally
- [x] 5.2 Run `kamal setup` for production — app booted and reachable via HTTPS
