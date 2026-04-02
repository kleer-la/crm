## Why

No visibility into what version is deployed or when the last deployment happened. Team members (not just admins) need a quick way to see deployment history for troubleshooting and awareness.

## What Changes

- New `Deployment` model to store deployment metadata (commit, author, branch, environment, timestamp, deployer)
- Kamal build script (`scripts/generate_build_info.sh`) captures git metadata into `BUILD_INFO` env var
- Rails initializer records deployment to DB on app boot
- New `/system/deployments` page with master-detail view: selected deployment detail card + paginated history table
- Sidebar footer shows last deployment date as a compact link to the deployments page
- `BUILD_INFO` added as Kamal secret for both production and QA

## Capabilities

### New Capabilities
- `deployment-history`: Track and display deployment history — model, capture pipeline, UI (detail + history list), sidebar indicator

### Modified Capabilities
- `kamal-deploy`: Adding `BUILD_INFO` secret and build script to the deployment pipeline

## Impact

- New DB table: `deployments`
- New route namespace: `/system/`
- Sidebar layout modified (footer section added)
- Kamal secrets and deploy configs updated (production + QA)
- No impact on existing domain models or business logic
