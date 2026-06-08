---
description: Clarify codebase work with grill-with-docs, non-code planning with grill-me, then orchestrate subagents/teams safely
argument-hint: "<request>"
---
Use the `orchestrated-workflow` skill for this request.

First read `~/.pi/agent/skills/orchestrated-workflow/SKILL.md`, then follow it exactly. Treat that skill as the source of truth: route repository/codebase work through `grill-with-docs`; use `grill-me` only for non-code planning, lightweight pressure tests, or when the user explicitly asks not to touch docs.

User request:
$ARGUMENTS
