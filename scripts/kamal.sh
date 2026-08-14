#!/bin/sh
# Runs Kamal through the official container, for machines without a local Ruby.
# Usage: scripts/kamal.sh deploy | app boot | ...
#
# Secrets live in .env (shell "export VAR=..." format, git-ignored). Containers
# don't inherit the host shell env, so every var referenced in .kamal/secrets
# is forwarded explicitly — the list is derived from that file so it can't go
# stale when a new secret is added.
set -e
cd "$(dirname "$0")/.."

set -a
. ./.env
set +a

ENV_FLAGS=""
for var in $(grep -oE '\$[A-Z_][A-Z0-9_]*' .kamal/secrets | tr -d '$' | sort -u); do
  ENV_FLAGS="$ENV_FLAGS -e $var"
done

exec docker run --rm \
  -v "$PWD:/workdir" \
  -v "$HOME/.ssh:/root/.ssh:ro" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e GIT_CONFIG_COUNT=1 -e GIT_CONFIG_KEY_0=safe.directory -e GIT_CONFIG_VALUE_0=/workdir \
  $ENV_FLAGS \
  ghcr.io/basecamp/kamal:latest "$@"
