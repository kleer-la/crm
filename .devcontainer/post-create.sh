#!/bin/bash
set -e

# Claude Code: persist config across container rebuilds
mkdir -p /app/.claude
ln -sfn /app/.claude /home/user/.claude

# Load environment variables in every shell session
# echo '[ -f /app/.env ] && set -a && . /app/.env && set +a' >> /home/user/.bashrc

# Dependencies
cd /app
[ -d openspec ] && openspec update || true
