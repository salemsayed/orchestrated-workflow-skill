# Orchestrated Workflow Skill

A shareable Pi skill for running skill-only orchestration workflows: clarify the request, decompose work, delegate to subagents/teams, maintain a durable ledger, protect parent context, validate, clean up, and report.

## Contents

```text
orchestrated-workflow/
├── SKILL.md
└── references/
    ├── handoff-schemas.md
    └── handoff-schemas.json

prompts/
└── orchestrate.md   # optional /orchestrate prompt
```

## Install

From this repo:

```bash
mkdir -p ~/.pi/agent/skills ~/.pi/agent/prompts
cp -R orchestrated-workflow ~/.pi/agent/skills/
cp prompts/orchestrate.md ~/.pi/agent/prompts/orchestrate.md
```

Or run:

```bash
./install.sh
```

Restart Pi after installing so it reloads skills/prompts.

## Usage

In Pi, either ask for orchestration naturally or use the optional prompt:

```text
/orchestrate <request>
```

The prompt tells Pi to load and follow `orchestrated-workflow`.

## Recommended companion skills/tools

The skill is most useful when these are available:

- `pi-subagents`
- `pi-teams`
- `pi-intercom`
- `pi-processes`
- `grill-with-docs` for codebase clarification
- `grill-me` for non-code planning or pressure testing

It can still be read as a process guide without all companions, but parts of the workflow mention those tools.

## Safety note

Skills can strongly influence agent behavior. Review `orchestrated-workflow/SKILL.md` before installing or sharing further.

## What this skill emphasizes

- durable `state.md` ledgers instead of UI state
- parent-context hygiene and compaction boundaries
- artifact-first child outputs
- max-turn-safe scout/reviewer handoffs
- active handle and lane tracking
- anti-polling rules
- no-git baseline tracking
- explicit data/deploy/destructive-work gates
- final cleanup before reporting success
