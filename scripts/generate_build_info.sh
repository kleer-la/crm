#!/bin/bash

# Generate build info JSON for CRM deployments.
# Collects git metadata and outputs JSON to stdout.
#
# Usage:
#   export BUILD_INFO=$(./scripts/generate_build_info.sh)

set -e

cd "$(dirname "$0")/.." || exit 1

export COMMIT_SHA=$(git rev-parse HEAD)
export COMMIT_SHA_SHORT=$(git rev-parse --short HEAD)
export COMMIT_MESSAGE=$(git log -1 --pretty=%B | tr -d '\n')
export AUTHOR=$(git show -s --format='%an <%ae>' HEAD)
export BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
export DEPLOYMENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
export DEPLOYER="${KAMAL_PERFORMER:-$(whoami)}"
export DESTINATION="${KAMAL_DESTINATION:-production}"
export COMMIT_URL="https://github.com/kleer-la/crm/commit/${COMMIT_SHA}"

ruby -rjson -e '
  puts JSON.generate({
    app_name: "crm",
    version: ENV["COMMIT_SHA_SHORT"],
    commit_sha: ENV["COMMIT_SHA"],
    commit_url: ENV["COMMIT_URL"],
    commit_message: ENV["COMMIT_MESSAGE"],
    author: ENV["AUTHOR"],
    branch: ENV["BRANCH_NAME"],
    deployed_at: ENV["DEPLOYMENT_TIME"],
    deployed_by: ENV["DEPLOYER"],
    environment: ENV["DESTINATION"]
  })
'
