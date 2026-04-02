## 1. Model & Database

- [ ] 1.1 Create migration for `deployments` table (version, commit_sha, commit_url, commit_message, author, branch, environment, deployed_at, deployed_by) with indexes on deployed_at (unique) and commit_sha
- [ ] 1.2 Create `Deployment` model with validations, `recent` scope, and `record_from_build_info` class method
- [ ] 1.3 Create FactoryBot factory for deployments
- [ ] 1.4 Write model tests (validations, uniqueness, scope, record_from_build_info happy path, duplicate skip, missing/invalid BUILD_INFO)

## 2. Boot Recording & Build Script

- [ ] 2.1 Create `config/initializers/record_deployment.rb` — records deployment on server boot only
- [ ] 2.2 Create `scripts/generate_build_info.sh` — collects git metadata, outputs JSON (app_name, version, commit_sha, commit_url, commit_message, author, branch, deployed_at, deployed_by, environment)

## 3. Kamal Configuration

- [ ] 3.1 Add `BUILD_INFO` to `.kamal/secrets` (generated from `scripts/generate_build_info.sh`)
- [ ] 3.2 Add `BUILD_INFO` as secret env var in `config/deploy.yml`
- [ ] 3.3 Add `BUILD_INFO` as secret env var in `config/deploy.qa.yml`

## 4. Controller & Routes

- [ ] 4.1 Add `System::DeploymentsController#index` with pagination and selected deployment logic
- [ ] 4.2 Add route `get "system/deployments"` in `config/routes.rb`
- [ ] 4.3 Write controller tests (authenticated access, redirect when unauthenticated, pagination, selected deployment via id param)

## 5. View & Sidebar

- [ ] 5.1 Create `app/views/system/deployments/index.html.erb` — detail card + paginated history table in Tailwind
- [ ] 5.2 Add deployment footer to `app/views/layouts/_sidebar.html.erb` — compact "Deployed: YYYY-MM-DD HH:MM" link
- [ ] 5.3 Run `bin/ci` to verify all tests, style, and security checks pass
