## 1. Production deploy configuration

- [ ] 1.1 Update `config/deploy.yml`: set `service: crm`, `image: carlospeix/crm`, server IP `5.78.92.152`, enable `proxy.ssl: true` and `proxy.host: crm.kleer.la`, configure Docker Hub registry with `username: carlospeix` and password from `KAMAL_REGISTRY_PASSWORD`, set `DB_HOST: postgres` in clear env, add `APP_DATABASE_PASSWORD` to secret env
- [ ] 1.2 Update `.kamal/secrets`: add `KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD` and `APP_DATABASE_PASSWORD=$APP_DATABASE_PASSWORD` (keep existing `RAILS_MASTER_KEY`)
- [ ] 1.3 Enable SSL in `config/environments/production.rb`: uncomment `config.assume_ssl = true` and `config.force_ssl = true`

## 2. Database configuration

- [ ] 2.1 Update `config/database.yml` production section: add `host: <%= ENV.fetch("DB_HOST", "localhost") %>` to the primary production config

## 3. QA destination

- [ ] 3.1 Create `config/deploy.qa.yml` as a Kamal destination file: override `service: crm-qa`, `proxy.host: qa.crm.kleer.la`, and set QA-specific database names (`crm_qa`, `crm_qa_cache`, `crm_qa_queue`, `crm_qa_cable`) via env vars

## 4. Create databases on server

- [ ] 4.1 Create the production PostgreSQL role and databases: `crm_production`, `crm_production_cache`, `crm_production_queue`, `crm_production_cable` (via `docker exec` into the `postgres` container)
- [ ] 4.2 Create the QA PostgreSQL databases: `crm_qa`, `crm_qa_cache`, `crm_qa_queue`, `crm_qa_cable` using the same role

## 5. First deploy runbook

- [ ] 5.1 Verify configuration files are correct and secrets are not committed to git
- [ ] 5.2 Run `kamal setup` for production and `kamal setup -d qa` for QA — confirm both apps boot and are reachable via HTTPS
