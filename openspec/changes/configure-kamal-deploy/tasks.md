## 1. Production deploy configuration

- [x] 1.1 Update `config/deploy.yml`: set `service: crm`, `image: carlospeix/crm`, server IP `5.78.92.152`, enable `proxy.ssl: true` and `proxy.host: crm.kleer.la`, configure Docker Hub registry with `username: carlospeix` and password from `KAMAL_REGISTRY_PASSWORD`, pass `DATABASE_URL` (and cache/queue/cable variants) as secrets
- [x] 1.2 Update `.kamal/secrets`: add `KAMAL_REGISTRY_PASSWORD`, `DATABASE_URL`, `CACHE_DATABASE_URL`, `QUEUE_DATABASE_URL`, `CABLE_DATABASE_URL` (keep existing `RAILS_MASTER_KEY`)
- [x] 1.3 Enable SSL in `config/environments/production.rb`: uncomment `config.assume_ssl = true` and `config.force_ssl = true`

## 2. Database configuration

- [x] 2.1 Update `config/database.yml` production section: use `DATABASE_URL` for primary and `CACHE_DATABASE_URL`/`QUEUE_DATABASE_URL`/`CABLE_DATABASE_URL` for the other databases

## 3. QA destination

- [x] 3.1 Create `config/deploy.qa.yml` as a Kamal destination file: override `service: crm-qa`, `proxy.host: qa.crm.kleer.la`, same secret env vars (different `DATABASE_URL` values at deploy time)

## 4. Create databases on server

- [ ] 4.1 Create production databases: `crm_production`, `crm_production_cache`, `crm_production_queue`, `crm_production_cable` (via `docker exec` into the `postgres` container using `postgres` superuser)
- [ ] 4.2 Create QA databases: `crm_qa`, `crm_qa_cache`, `crm_qa_queue`, `crm_qa_cable`

## 5. First deploy

- [ ] 5.1 Set env vars locally: `KAMAL_REGISTRY_PASSWORD`, `DATABASE_URL`, `CACHE_DATABASE_URL`, `QUEUE_DATABASE_URL`, `CABLE_DATABASE_URL` (production values for `kamal setup`, QA values for `kamal setup -d qa`)
- [ ] 5.2 Run `kamal setup` for production and `kamal setup -d qa` for QA
