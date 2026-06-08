#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DEST="${PI_SKILLS_DIR:-$HOME/.pi/agent/skills}"
PROMPT_DEST="${PI_PROMPTS_DIR:-$HOME/.pi/agent/prompts}"

mkdir -p "$SKILL_DEST" "$PROMPT_DEST"
rm -rf "$SKILL_DEST/orchestrated-workflow"
cp -R "$ROOT/orchestrated-workflow" "$SKILL_DEST/orchestrated-workflow"
cp "$ROOT/prompts/orchestrate.md" "$PROMPT_DEST/orchestrate.md"

echo "Installed orchestrated-workflow skill to $SKILL_DEST/orchestrated-workflow"
echo "Installed /orchestrate prompt to $PROMPT_DEST/orchestrate.md"
echo "Restart Pi to reload skills and prompts."
