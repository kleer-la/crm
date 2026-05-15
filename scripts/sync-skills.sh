#!/usr/bin/env bash
set -euo pipefail

# Syncs skills from .agents/skills/ to opencode commands in .opencode/commands/
#
# Usage:
#   scripts/sync-skills.sh            # sync all skills
#   scripts/sync-skills.sh --dry-run  # preview without writing
#   scripts/sync-skills.sh --quiet    # suppress per-file output
#
# After adding/updating a skill (via skills-lock.json or manually), run this
# to make it available as an opencode slash command.

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$APP_ROOT/.agents/skills"
COMMANDS_DIR="$APP_ROOT/.opencode/commands"
DRY_RUN=false
QUIET=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --quiet) QUIET=true ;;
  esac
done

mkdir -p "$COMMANDS_DIR"

created=0
skipped=0

for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
  [ -f "$skill_md" ] || continue

  name=$(sed -n '/^---$/,/^---$/p' "$skill_md" | grep '^name: ' | sed 's/^name: //')
  desc=$(sed -n '/^---$/,/^---$/p' "$skill_md" | grep '^description: ' | sed 's/^description: //; s/^"//; s/"$//')

  [ -n "$name" ] && [ -n "$desc" ] || continue

  command_file="$COMMANDS_DIR/$name.md"

  if [ -f "$command_file" ]; then
    skipped=$((skipped + 1))
    continue
  fi

  if [ "$DRY_RUN" = true ]; then
    $QUIET || echo "  Create: $command_file"
  else
    cat > "$command_file" <<CMDEOF
---
description: $desc
---

Load the \`$name\` skill and follow its process.
CMDEOF
    $QUIET || echo "  Created: $command_file"
  fi

  created=$((created + 1))
done

$QUIET && exit 0

echo
echo "Done: $created created, $skipped skipped"
