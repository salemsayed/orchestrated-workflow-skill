---
name: orchestrated-workflow
description: Run a full Pi orchestration workflow. Use when the user wants a main session to clarify requirements with grill-with-docs for codebase work or grill-me for non-code/lightweight planning, then act as orchestrator over pi-subagents, pi-teams, and configured UI agents while monitoring, steering, validating, and reporting.
---

# Orchestrated Workflow

Use this skill when the user triggers an orchestration session or asks the current Pi session to coordinate other agents.

The current/main session is the orchestrator. Do not become a passive executor. Your job is to clarify, decompose, delegate, monitor, steer, integrate, validate, clean up, and report.

## Phase 0: Load Required Operating Context

Before planning or delegating:

1. For codebase work, read and follow `~/.pi/agent/skills/grill-with-docs/SKILL.md` when installed. This is the default clarification skill for implementation, debugging, refactoring, architecture, release, and UI work in a repository.
2. Read and follow `~/.pi/agent/skills/grill-me/SKILL.md` for non-code planning, lightweight pressure tests, explicit “grill me” requests, or cases where the user does not want repository docs touched.
3. Read and follow the installed `pi-subagents` skill if subagents are likely to be used.
4. Read and follow the installed `pi-intercom` skill if cross-session coordination or child-agent clarification may be needed.
5. For any UI/frontend work, route implementation/review to the configured UI agents described below; do not hardcode or override their model/thinking settings unless the user explicitly asks.

Also check for repo-local skills or instructions that govern the request (`.pi/skills/`, `skills/`, `AGENTS.md`, `CLAUDE.md`, deploy/OTA/runbook docs). Project-specific deploy, OTA, release, data, and safety workflows override this generic skill where they are stricter. Record which local skill/runbook is the source of truth in the ledger.

## Phase 0.5: Compaction-Safe State Ledger

For any non-trivial orchestration, create and maintain a small durable ledger in the repo or current working directory before delegation begins. Before creating a new ledger, look for an existing `.pi/orchestration/*/state.md` that matches the same feature, release, or follow-up thread. Continue and refresh that ledger when the user is extending an active workstream; create a new ledger only for a genuinely separate effort. Prefer `.pi/orchestration/<short-task-name>/state.md`; if repo-local `.pi/` is unavailable, use `orchestration-state.md` in the working directory.

The ledger must be concise and current enough that a fresh session can resume without conversation history. Update it:

- after clarification and task decomposition
- after capturing the initial dirty-tree baseline: when in a git worktree, record current branch, existing modified/untracked files, and any files that must be treated as pre-existing user/other-session work; outside git, create a no-git baseline table with target paths, existence, size/mtime or checksum when practical, owner, intended change, and rollback/reconstruction note
- before the first writer starts on non-trivial work, after freezing the lightweight execution contract: latest goal/non-goals, owned areas, validation contract, required review axes, runtime budget, and stop rules
- after each subagent/team is spawned, with run IDs, team names, task IDs, owners, and exact prompts or artifact paths
- after every delegated stage produces or updates artifacts, with input/output paths and synthesis status
- after every user scope change, follow-up request, or release/deploy escalation; rewrite the goal, current phase, next action, validation contract, runtime budget, stop rules, and final report draft so stale state cannot survive
- after every meaningful implementation or validation result
- before starting any long-running process or async subagent/team work
- after any process/subagent/team completes
- before final housekeeping and immediately before the final user report

Keep the ledger structured:

```md
# Orchestration State

## Goal / User Contract
- ...

## Current Status
- phase: planning | delegating | integrating | validating | finalizing
- last updated: <timestamp>
- next action if resumed: ...

## Execution Contract
- latest approved goal/non-goals: ...
- owned files/areas and pre-existing dirty files: ...
- validation contract: ...
- required review axes before success: ...
- stop rules: ...

## Runtime Budget
- max active child/team handles for current phase: ...
- max review rounds: 3 by default unless explicitly overridden
- current review round: ...
- max validation/fix retries per failing command: 2 by default unless explicitly overridden
- fix retry count by command: ...
- cap override reason: ...
- max consecutive no-new-output monitor snapshots: 2 by default
- long-command checkpoint/escalation threshold: ...
- artifact/log budget: save bulky output to files; quote only minimal evidence

## Active Handles
- teams: <id/name>, owner=<...>, lane=<...>, status=<...>, lastSeen=<...>, expectedNextCheck=<...>, staleIfAfter=<...>, artifact/log=<...>, disposition=<active|complete|blocked|superseded|intentionally-left-open>
- subagents: <run id>, owner=<...>, lane=<...>, status=<...>, lastSeen=<...>, expectedNextCheck=<...>, staleIfAfter=<...>, artifact/log=<...>, disposition=<...>
- processes: <process id/name>, owner=<...>, lane=<...>, command=<...>, status=<...>, lastSeen=<...>, expectedNextCheck=<...>, staleIfAfter=<...>, artifact/log=<...>, disposition=<...>
- task list: <task id>, owner=<...>, lane=<...>, status=<...>, lastSeen=<...>, expectedNextCheck=<...>, staleIfAfter=<...>, disposition=<...>

## Active Lanes
- <lane name>: holder=<agent/process/team/task>, status=<running|pending|blocked>, since=<timestamp>, notes=<why claimed or what it blocks>

## Stage Artifacts
- <stage name>: inputs=<paths>, outputs=<paths>, owner=<agent/team>, status=<pending/running/done/blocked>, synthesis=<path or summary>, stop rule=<...>

## Decisions / Scope Boundaries
- ...

## Files Changed / Owned Areas
- initial dirty-tree baseline: ...
- no-git baseline, when outside git: | path | exists? | size/mtime or checksum if available | owner | intended change | rollback/reconstruction note |
- files intentionally changed by this orchestration: ...
- pre-existing or unrelated dirty files not owned by this task: ...

## Validation
- passed: ...
- failed/blockers: ...

## Final Report Draft
- ...
```

If the session resumes after compaction, crash, or a long gap, first read the ledger, then check live handles (`TaskList`, `process list`, subagent status, pi-team task list/inboxes as applicable) before doing new work. Do not rely on memory alone. If the ledger is missing or stale, reconstruct it from git status when available, session artifacts, task lists, process logs, and team/subagent outputs before continuing; outside git, record that there is no repo status and use known files/paths plus artifact evidence. Treat a stale `Final Report Draft`, stale `phase`, or stale open task reference as unsafe until reconciled against the latest user request and live handles.

Avoid letting the orchestrator accumulate large context. When state grows, summarize into the ledger, prefer compact handoff files and fresh-context reviewers, and use fresh-context workers only when the handoff is sufficient and the loss of inherited context is intentional.

### Audit-Derived Hard Gates

Past orchestration sessions showed recurring failures from context blowup, stale handles, max-turn child exits, over-polling, no-git opacity, and ambiguous data/deploy actions. For non-trivial orchestration, record a one-line gate in the ledger before every delegation, monitor pass that may add context, safety-sensitive command, and final report:

- **Context gate:** what new information is needed, where bulky output will be stored, whether child output is file-only, and whether compaction is needed before continuing.
- **Handle gate:** live tasks/processes/subagents/teams checked or intentionally deferred, their next checkpoint, and any stale handle disposition.
- **Safety gate:** for deploy/release/data/destructive work, approval, exact target, dry-run/backup/rollback, verification, and secret-redaction status.
- **Scope gate:** confirms the current action still matches the latest user request, owned files/areas, and non-goals.

If any gate is unknown for deploy, release, migration, data, or destructive external-state work, stop and resolve it before running commands, spawning duplicate workers, or reporting success.

### Parent Context Hygiene and Safe Compaction

The main orchestrator should stay thin. Its durable memory is the ledger plus small artifacts, not raw chat history. Keep the parent context free by default:

- Put durable state in `state.md`.
- Store plans, worker handoffs, review findings, validation results, deploy notes, and final drafts as files next to the ledger.
- Ask subagents/teams for concise summaries and artifact paths, not full diffs, raw logs, or pasted transcripts.
- Prefer `outputMode: "file-only"` for large subagent outputs and read only the needed sections.
- For broad scouts, reviewers, and validators, require file-only output by default and ask for at most: top 10 findings, evidence paths/line refs, commands with exit codes, open questions, and remaining risks.
- Do not paste raw logs, full diffs, transcripts, or long child reasoning into the parent. If the parent would need more than a short section from an artifact, write/read a synthesis artifact instead of importing the whole artifact into chat.
- Do not keep re-reading large files/logs in the parent once a scout, reviewer, validator, or artifact already captured the relevant facts.
- After two substantial child artifacts or monitor summaries have been consumed since the last compaction boundary, update the ledger and compact before launching another broad child unless there is an urgent blocker.

Compact proactively at phase boundaries instead of waiting for forced mid-turn compaction. Good boundaries are: after clarification/plan approval, after worker handoff, after review synthesis, after validation, before a long build/deploy/test run, and before final reporting. Run `/compact` with instructions to preserve orchestration goal, scope boundaries, active handles, phase, next action, validation state, file ownership, blockers, and final report draft while dropping stale logs and repeated monitoring chatter.

If a context-pressure warning appears, treat it as internal orchestration hygiene, not a user-facing request. At the next real boundary, update the ledger yourself, compact when available, and continue hands-off unless there is an actual blocker or approval decision.

Do not add a separate heavyweight workflow-spec phase on top of scout, grill, planning, and validation-contract work. The useful checkpoint is a compact execution contract inside the existing ledger or `plan.md` before the first writer starts. It freezes the latest approved target so workers and adversarial reviewers can verify against the same artifact; it does not replace clarification or planning.

## Phase 1: Pre-Grill Reconnaissance

Before asking `grill-with-docs` or `grill-me` questions, decide whether the request needs repository context.

- If the needed context is tiny, inspect it directly in the main session.
- If exploration touches more than a couple of files/directories, crosses repos, involves unclear app/backend boundaries, production data, external services, deployment/release work, or UI plus backend behavior, stop solo exploration and use read-only `pi-subagents` reconnaissance before grilling.
- Use `scout` for fast mapping and `context-builder` when the result must become handoff material for planning or implementation.
- The main session may do only a short orientation pass before delegation: identify the repo, obvious entry points, and local instructions. Do not spend a long exploratory loop in the orchestrator when a read-only scout can map the area.
- Keep pre-grill reconnaissance narrow and read-only. Its purpose is to ask better questions, not to design or implement the solution.
- Do not spawn writers, UI implementers, or pi-teams during pre-grill reconnaissance.
- Do not let reconnaissance replace the clarification/grilling phase unless the user explicitly asked to skip clarification.
- When production data or secrets are involved, never print secret values. Report presence, paths, counts, ranges, and redacted findings only.

Use the reconnaissance findings to avoid asking questions that the codebase already answers.

## Phase 2: Grill the Request

Use `grill-with-docs` after any needed reconnaissance for codebase work unless the user explicitly says to skip clarification or not to touch repository docs. Use `grill-me` instead for non-code planning, lightweight pressure tests, explicit “grill me” requests, or no-doc-update sessions. If a `/orchestrate` prompt/template description conflicts with this rule, this skill wins.

Rules:
- Ask one question at a time.
- For every question, include your recommended answer.
- If a question can be answered by inspecting the repository, inspect directly or use read-only reconnaissance instead of asking.
- Resolve decision dependencies in order: goal, scope, users, constraints, success criteria, risks, validation, deployment/release expectations.
- With `grill-with-docs`, read existing `CONTEXT.md`, `CONTEXT-MAP.md`, and relevant ADRs when present. Challenge fuzzy or conflicting domain language against those docs and the code.
- Treat `CONTEXT.md` as glossary/domain language only. Do not put implementation plans, task lists, specs, scratch notes, or transient orchestration state in it.
- Create or update `CONTEXT.md` only after a domain term is genuinely resolved. If no domain docs exist yet, ask once before creating the first one unless the user has already approved doc updates for this orchestration.
- Offer ADRs sparingly: only for decisions that are hard to reverse, surprising without context, and the result of a real trade-off.
- If doc updates are skipped or declined, capture resolved terms and durable decisions in the orchestration ledger and handoff artifacts instead.
- Stop grilling when the remaining uncertainty no longer changes the plan materially, or the user explicitly approves moving forward.

Do not spawn writers before the clarification phase has produced a usable task contract.

## Phase 3: Classify the Work

After clarification, classify the request:

- **Trivial:** do directly; no delegation ceremony.
- **Medium/risky single stream:** use `pi-subagents` for scout/planner/oracle/reviewer support around one writer.
- **Broad or parallel implementation:** use `pi-teams` and split work by non-overlapping files/modules/responsibilities.
- **UI/frontend:** route meaningful UI implementation/review to the configured `ui-worker`/`ui-reviewer` agents. Do not pin their model or thinking settings unless the user explicitly requests an override.
- **Release/deploy/blocker-heavy:** use pi-teams with release/checker or test-fixer roles and clean the team up after.

If unsure whether the plan is safe, ask `oracle` before editing or spawning writers.

## Phase 4: Model and Agent Routing

Default routing:

- Main orchestrator: current session/model.
- Non-UI pi-teams teammates: pin `openai-codex/gpt-5.5` with explicit thinking. Do not use mini models or minimal thinking for production, deploy, release, data, or migration work unless the user explicitly requests that trade-off.
- `team-scout`: `openai-codex/gpt-5.5`, `thinking: xhigh`.
- `team-planner`: `openai-codex/gpt-5.5`, `thinking: xhigh`.
- `team-builder`: `openai-codex/gpt-5.5`, `thinking: medium`, use plan mode for broad edits.
- `team-reviewer`: `openai-codex/gpt-5.5`, `thinking: high`.
- `team-test-fixer`: `openai-codex/gpt-5.5`, `thinking: medium`.
- `team-release-checker`: `openai-codex/gpt-5.5`, `thinking: high`.
- `oracle`: `openai-codex/gpt-5.5`, `thinking: xhigh`.
- Builtin `worker`: leave the package default as-is unless the user explicitly changes it.
- UI implementation: configured `ui-worker`; use the agent's configured model/thinking defaults.
- UI review: configured `ui-reviewer`; use the agent's configured model/thinking defaults.

Do not use provider-less model aliases in pi-teams. Always pass exact `openai-codex/...` model names and explicit thinking values when spawning non-UI teammates. If the user explicitly wants a cheaper or different non-UI teammate model, record that exception in the ledger before spawning. For UI subagents, do not pass model/thinking overrides unless explicitly requested.

## Phase 5: Choose Delegation Mechanism

Use `pi-subagents` for:
- read-only discovery (`scout`, `context-builder`)
- implementation plans (`planner`)
- decision/drift checks (`oracle`, usually forked context when conversation history matters)
- goal-style isolated implementation (`worker`) after an approved direction, using an explicit `acceptance` contract when the work has success criteria
- review (`reviewer`)
- UI implementation/review via `ui-worker` and `ui-reviewer`

For UI subagents specifically:
- Prefer fresh-context `ui-worker`/`ui-reviewer` runs with explicit task text, `plan.md`, and narrow file targets. Do not fork large parent conversation history into UI workers unless the inherited conversation itself is essential.
- For broad UI work, write a handoff file next to the ledger before launching the worker. Include approved scope, non-goals, owned files, validation commands, and how to report changed files.
- Split broad UI migrations into coherent batches instead of one giant task: shared primitives/docs, one app section, one route group, or one visual pattern at a time.
- Ask UI workers to stop and report after a coherent batch when the remaining work would require many more files or prolonged tool history.
- Use a follow-up `ui-reviewer` or another `ui-worker` batch rather than letting one UI child accumulate a very large context.

Use `pi-teams` for:
- multiple workstreams
- implementation plus validation/blocker fixing
- deploy/release readiness
- cases where visible team task ownership helps

Keep one writer per file/module unless using worktree isolation. Do not manually edit files that an active teammate/subagent is likely to modify.

When the user changes scope mid-run, pause before spawning or editing more. Update the ledger goal/current status/final report draft, reconcile open tasks and handles, reclassify the work, and decide whether to continue the same ledger or open a separate release/follow-up ledger. Do not keep executing an old plan after the latest request made it stale.

## Phase 6: Orchestrate Actively

### Coordination Lanes

Use lightweight coordination lanes to prevent agents, teams, and processes from stepping on shared resources. A lane is a `do not overlap this` label, not a heavyweight scheduler. Claim lanes before spawning a writer, starting a process, running validation, launching a dev server, or performing deploy/release/data work; release them when that work finishes, is canceled, or is explicitly superseded.

Default lane families:

- `edit:<path-or-module>` — file/module ownership; one writer per area unless using explicit worktree isolation.
- `build` — builds, typechecks, package commands, or commands that contend on build caches.
- `test` — full test suites, database-heavy tests, or shared simulator/device test runs.
- `lint` — lint/format checks; mutating formatters should also claim relevant `edit:*` lanes or `build` when they rewrite compiler inputs.
- `dev-server` — starting, stopping, restarting, or using a shared local server/app instance.
- `browser` — shared browser automation or visual state that can interfere with another UI review.
- `deploy` — staging/preview/production deployments.
- `release` — versioning, publishing, signing, OTA, app-store, or production rollout steps.
- `data` — migrations, seeds, destructive scripts, prod/staging data operations, or shared external state.

Before every spawn/run, ask:

1. Which lanes does this claim?
2. Are any claimed lanes already active in the ledger or live handles?
3. If there is a conflict, should the new work wait, be split, use worktree isolation, cancel/supersede the older work, or ask the user?
4. Did I record the claim in `state.md`?

Conflict rules:

- Never overlap the same `edit:*` lane in one checkout. If two writers need overlapping files, serialize them or use isolated worktrees and merge deliberately.
- Do not overlap `build`, `test`, `lint`, `dev-server`, `browser`, `deploy`, `release`, or `data` lanes unless the repo runbook explicitly says the commands are concurrency-safe.
- Latest explicit user lifecycle intent may supersede older `dev-server`, `browser`, `deploy`, or `release` work only after the old handle is accounted for. Record `supersededBy` or a note in the lane entry.
- For production, deploy, release, migration, or data lanes, do not start a duplicate while the original is unknown. Resolve the original handle first.
- Validation jobs may use stable request-key-style notes such as `requestKey=typecheck-main` so a resumed session can reconnect or avoid starting duplicates.

Before final reporting, all lanes should be released or intentionally left open and reported alongside their live handle.

When running a team:

1. Create/update the compaction-safe state ledger before creating the team.
2. Capture and record the dirty-tree baseline before assigning writers, so teammates do not mistake pre-existing work for their own changes.
3. Create a team with a clear name and record the team name in the ledger.
4. Create team tasks for meaningful work and record task IDs/owners.
5. Spawn narrow teammates with exact model and thinking settings.
6. Require plans before broad/risky edits.
7. Monitor `task_list`, inbox messages, teammate status, and validation output.
8. After each monitoring pass or steering message, update the ledger with what changed, active/released lanes, and the next action.
9. Spawn blocker-fix teammates when tests/lint/typecheck/build failures can be fixed safely in parallel without lane conflicts.
10. Integrate results yourself, inspect diffs, and rerun validation.
11. Mark team tasks complete and shut down every team you created unless the user asked to keep it alive.

Avoid monitoring loops that only alternate `check_teammate` and `read_inbox`. If a teammate is inside a long blocking shell command, it may stay alive but cannot read status pings or send progress until the command returns. In that state, do not keep sending reminders every few seconds. Record the expected wait/checkpoint in the ledger, wait for a tool/process/team notification or a reasonable wall-clock interval, then check once. Track `noNewOutputCount` per handle in the ledger. After two no-new-output snapshots, do not call `process output`, `process list`, `check_teammate`, or `read_inbox` for that handle again until a notification arrives, the recorded checkpoint time passes, or you are taking a real recovery action. Do not send “any update?” pings unless the handle is stale and the next decision is wait/intervene/replace/shutdown. If the teammate has not heartbeated for a meaningful interval and no inbox result arrives, treat it as a recovery situation: inspect the ledger/team state, ask for one status update, and decide whether to wait, interrupt, or shut down. Do not start a duplicate production/deploy runner unless the original confirms it never began mutating work.

When running subagents:

1. Use narrow prompts with exact deliverables.
2. For implementation, fix-worker, migration, release-prep, validation, or any explicit `/goal` / “active goal” / “continue until evidence says done” request, attach an object-only `acceptance` contract instead of relying on prose alone. Define concrete `criteria`, required `evidence`, optional `verify` commands or checks, `stopRules`/constraints, and `maxFinalizationTurns`. This makes the child keep self-reviewing/repairing in the same session until the contract is met or the loop cap is hit.
3. For non-trivial delegated work, default broad reviews, scouts, worker handoffs, and validation summaries to an explicit `output` path with `outputMode: "file-only"`; use a concise no-file summary when artifacts are unnecessary. Do not ask children to paste full diffs or huge logs into chat; ask for file paths, severity-ranked findings, validation evidence, open questions, and remaining risks. When the result will feed another stage, ask the child to include a final fenced JSON handoff matching the relevant schema in `references/handoff-schemas.json` (`scout`, `worker`, `reviewer`, `validator`, or `synthesis`). For review-only children with a configured output path, say: “Do not modify project/source files; writing the configured output artifact is allowed.” Do not say only “do not edit files” when an output artifact is expected.
4. For broad read-only scouts and broad reviewers, require a max-turn-safe partial artifact before deep dives. The child must first write inspected areas, candidate files, unknowns, and a resume plan, then continue deeper only if budget remains. Prompts should say: “If you approach your turn/time budget, stop early and leave a partial but useful artifact with coverage, notInspected, topFindings, and resumeFrom; do not spend final turns trying to be exhaustive.”
5. Use `output: false` only when you truly want no output artifact. Do not pass the string `"false"` as a path; if a child accidentally creates a bad artifact file, clean it before final reporting.
6. Record every run ID, artifact path, acceptance contract, and expected deliverable in the state ledger immediately after spawning.
7. Use fresh context for adversarial review and most UI implementation; use forked context for oracle/drift checks.
8. Avoid sending broad parent history to workers when a compact plan/context file is enough.
9. Prefer async subagent launches by default unless there is a concrete reason to block in the foreground. Async does not permit overlapping writes to the same files.
10. Before waiting on or switching away from async work, write the expected resume step into the ledger.
11. Use intercom only for blockers, clarification, drift warnings, or explicit progress updates.
12. Do not treat child agents as final authority; the orchestrator decides what to accept. A child acceptance report is evidence, not an independent review gate.

### Goal-Style Subagent Acceptance

Use `acceptance` as the default completion contract for non-trivial writer-style subagent runs. It is the Pi-subagents equivalent of Codex `/goal`: the child receives criteria, evidence requirements, verification checks, constraints/stop rules, and a bounded finalization budget. The runtime then keeps the same child session in a self-review/repair loop until either the contract is satisfied with evidence or `maxFinalizationTurns` is exhausted.

Apply this especially to:
- initial `worker` implementation handoffs
- synthesized fix-worker passes after review
- migration, data, release-prep, and risky workflow changes
- validator runs that must prove a behavior, not just inspect code
- any user request phrased as `/goal`, “goal”, “active goal”, or “work until evidence says done”

Do not overuse it for quick read-only scouts or lightweight advisory oracle checks unless there is a concrete evidence contract. Do not mark a run “reviewed” just because its acceptance loop passed; independent fresh-context reviewers still provide the review gate for serious work.

Example worker launch:

```typescript
subagent({
  agent: "worker",
  task: "Implement the approved plan from .pi/orchestration/example/plan.md. Preserve the approved scope and report changed files, commands run, validation evidence, and remaining risks.",
  acceptance: {
    criteria: [
      "Approved behavior is implemented without widening scope",
      "Relevant tests or checks pass, or blockers are reported with evidence",
      "No unrelated files are modified"
    ],
    evidence: [
      "changed files list",
      "commands run with exit codes",
      "test or smoke-check output summary",
      "remaining risks/blockers"
    ],
    verify: ["Run the focused validation command from the plan when available"],
    stopRules: [
      "Stop and ask if a product, architecture, data, or release decision is needed",
      "Do not edit outside the approved owned areas",
      "Do not keep retrying the same failing validation without new evidence"
    ],
    maxFinalizationTurns: 3
  },
  async: true,
  output: ".pi/orchestration/example/worker-handoff.md",
  outputMode: "file-only"
})
```

### Stage Artifact Contract

For non-trivial delegated work, treat child outputs as stage artifacts, not as conversation history to paste back wholesale:

- Before launching a stage, record its input artifact(s), expected output path(s), owner, evidence required, and stop rule in the ledger.
- Default broad reviews, scouts, worker handoffs, and validation summaries to `outputMode: "file-only"` with predictable paths beside the ledger.
- For machine-checkable handoffs, use `references/handoff-schemas.json`; for prompt guidance and examples, read `references/handoff-schemas.md`.
- After a stage completes, the orchestrator reads only the needed artifacts, writes a short synthesis, mirrors any `stageUpdate` into `## Stage Artifacts`, and passes that synthesis or artifact path to the next writer/reviewer.
- Treat a worker handoff as an intermediate artifact, not as final success, unless the user explicitly asked for worker-only work or to stop after implementation.
- Before final reporting, every artifact path recorded in the ledger must either exist or be marked “not produced” with a short reason.

For production deploy, release, or OTA work:

1. Treat it as high risk, even when the command looks routine.
2. Load and follow the relevant repo-local deploy/OTA/release skill or runbook first. If it says the main session must not run deploy/OTA commands directly, delegate to the required teammate shape and obey that boundary.
3. Use `openai-codex/gpt-5.5` with `thinking: high` for release teammates; do not use mini/minimal release runners by default.
4. Prefer `team-release-checker`, `deploy-runner`, `ota-runner`, or a narrowly prompted release teammate over a generic builder when the project workflow defines those roles.
5. Confirm the target environment, branch/channel/platform, rollback path, validation command, and release message before changing production.
6. If a deploy/release command is expected to run for more than a short interval, prefer having the release teammate start it with the `process` tool using `alertOnSuccess`/`alertOnFailure`, record the process ID/log paths in the ledger, and continue orchestration from notifications instead of blocking the teammate in one long shell call.
7. If production users report a bad deploy, mitigate first when possible, then investigate root cause.
8. Report exact deploy identifiers, OTA/update IDs, backup paths, validation performed, rollback state, warnings, and any user action needed.

For data, migration, or destructive external-state work:

1. Treat migrations, seeds, cleanup scripts, remote DB/storage changes, billing/auth/admin changes, production/staging data operations, and irreversible local destructive actions as high risk.
2. Confirm exact target identifiers and environment; never infer prod/staging from defaults.
3. Capture explicit approval in the current conversation for destructive or production-affecting actions.
4. Produce a dry-run or read-only impact artifact first when the tool supports it.
5. Record backup, rollback, or undo strategy; if none exists, say so plainly and ask for approval before proceeding.
6. Redact secrets and sensitive row/user values; report counts, ranges, paths, and safe IDs only.
7. Run one post-change verification and record evidence.
8. Do not start a duplicate data runner while the original handle is unknown.

## Phase 6.5: Long-Running Process Discipline

Use the `pi-processes` skill whenever orchestration depends on a dev server, watcher, build, deploy, log tail, or any command that may run long enough to tempt polling. Load that skill before starting the process if it has not already been loaded in the current session.

Rules:

- Before starting a command likely to be long-running, record the expected checkpoint/escalation threshold in the ledger.
- Start long-running commands with `process start` and useful notifications (`alertOnSuccess` for finite validation/build/deploy commands, `alertOnFailure` for all task-specific commands).
- Record the process ID, command, cwd, log paths, and expected completion/checkpoint in the state ledger immediately after start.
- Do not pass invented wait/timeout parameters to `process output`; it is a snapshot check, not a wait primitive. A large `timeout` field does not make it block until completion.
- Do not tight-loop on `process output`, `process list`, `check_teammate`, or `read_inbox`. After a snapshot shows no new output, increment that handle's `noNewOutputCount`; after two empty snapshots, wait for the configured process notification, the ledger checkpoint time, or a real recovery action before checking again.
- For finite commands that appear silent longer than expected, perform one status/log snapshot, then either keep waiting with the ledger updated or stop/escalate based on the command's risk. Do not repeatedly poll every few seconds.
- Before final reporting, clear finished processes and stop task-specific long-running processes unless intentionally left running and reported.

## Phase 6.6: Runtime Budgets and Stop Rules

Use hard default budgets for non-trivial orchestration unless the ledger records an explicit override and reason:

- Max review rounds: 3. Track `reviewRound` in the ledger.
- Max validation/fix retries: 2 per failing command before replan, escalation, or user decision. Track `fixRetryCountByCommand` in the ledger.
- Max consecutive no-new-output monitor snapshots for the same handle: 2; after that, wait for a notification, do independent work, or take a real recovery action.
- Max active child/team handles for the current phase: if the ledger has no current-phase active-handle limit, set one before spawning; do not spawn until it is recorded, and do not exceed it silently.
- One writer in the active checkout unless worktree isolation is explicitly enabled.
- Bulky logs and bulky child outputs must be saved to files; quote only the smallest relevant evidence in the main conversation and final report.

When a budget is hit, update the ledger and choose exactly one next action: wait with a concrete checkpoint, interrupt/replace the handle, narrow scope, ask the user, or stop with partial findings. Do not keep polling, spawning, or retrying silently. Launching review round >3 or validation/fix retry >2 requires explicit user approval or a recorded replan that narrows scope; a scope change does not silently reset counters unless the ledger records that it is a new workstream and why.

## Phase 7: Validation and Reporting

Before reporting success:

- Run the most relevant validation available: tests, lint, typecheck, build, smoke check, or rendered UI inspection.
- For UI work, inspect the rendered result when practical across desktop and mobile sizes.
- For broad or risky non-trivial code, user-visible, data, auth, deploy, migration, or UI work, success requires at least two fresh-context checks before final reporting: one spec/runtime correctness axis and one standards/tests/maintainability axis. UI work can count the configured `ui-reviewer` for the UI/user-flow/spec axis, but standards/tests/maintainability must still be covered by another reviewer or explicitly included in a dual-axis prompt for small changes. Tiny safe changes may use parent-only review; small non-trivial changes may use one reviewer only if that reviewer explicitly covers both axes.
- Check tasks, processes, async subagents, and teams for stale in-progress work; reconcile any ledger task IDs against the live task list before claiming completion. Do not finalize with `in_progress` task IDs, open lanes, unknown async subagents, live processes, or stale handles unless each has a disposition of `intentionally-left-open` and is reported to the user.
- Stop/clear task-specific background processes unless intentionally left running.
- Shut down pi-teams unless intentionally kept alive.
- Remove accidental artifacts created by mis-specified child output paths when safe, or explicitly report why they remain.
- Update the state ledger with final validation results, open risks, final active-handle status, and a final report draft that matches the latest user request before sending the final response. Perform finalization checks directly: validation recorded, no stale active handles, final report draft present, task/process/subagent/team state reconciled, and the ledger matches the latest user request. This protects against the common failure mode where validation is complete but compaction/interruption happens before the user receives the report.
- If any task, team, process, or subagent is still intentionally open, say so plainly. Otherwise do not report success until the ledger and live handles agree that nothing task-specific is left running.

Final report should be short and plain English:
- what was done
- what was validated
- anything intentionally left running/open
- remaining risks or decisions, if any

## Operational Checklists

Use these as quick gates; keep them lightweight and proportional to the task.

### Stop/Go Gates

Before implementation, confirm or record:
- approved scope and non-goals
- owned files/areas and any pre-existing dirty files
- no-git baseline table when outside git: path, exists, size/mtime or checksum if available, owner, intended change, rollback/reconstruction note
- validation contract and success criteria
- subagent `acceptance` criteria, required evidence, verification checks, constraints/stop rules, and loop cap for writer-style runs
- child output contract: artifact path, file-only where broad, top-N findings limit, evidence paths only, no raw logs/transcripts
- required review axes before final success
- runtime budget and stop rules, including `reviewRound`, `fixRetryCountByCommand`, and any `capOverrideReason`
- one-writer plan or explicit worktree isolation

Before deploy, release, OTA, data, migration, or destructive external-state work, confirm or record:
- target environment, platform, branch/channel, exact resource identifiers, and release/change message
- explicit approval for destructive or production-affecting actions
- dry-run or read-only impact artifact when supported
- rollback path, backup expectations, or explicit acknowledgement that rollback is unavailable
- validation and smoke/post-change checks
- secret-redaction plan: no secrets or sensitive row/user values pasted
- project-specific runbook/skill to follow

Before final reporting, confirm:
- ledger state and live handles agree
- recorded stage artifacts exist or are explicitly marked not produced with reasons
- task list has no stale in-progress task for this work
- processes, teams, and async subagents are complete or intentionally left open and reported
- every active handle has a current disposition and no stale `lastSeen`/`staleIfAfter` mismatch
- final report draft matches the latest user request, not an earlier scope
- outside git, final report states that no git diff was available and summarizes owned changed paths from the no-git baseline

### Standard Artifact Names

Prefer predictable names next to the ledger so resumed sessions can orient quickly:
- `plan.md`
- `worker-handoff.md`
- `review-findings.md`
- `review-synthesis.md`
- `validation.md`
- `round-N/<axis>.md` for multi-round review/fix loops
- `release-notes.md` or `deploy-result.md` for release work

Use more specific names only when multiple batches need separate artifacts, such as `ui-worker-handoff.md` or `backend-review-findings.md`.

### Reviewer Fanout

Scale review to risk, but treat review as a gate for non-trivial work:
- Tiny safe change: parent review is enough.
- Small non-trivial implementation: one reviewer can cover both axes, or use the configured UI reviewer when UI-facing, if the prompt explicitly asks for both axes.
- Broad, backend, data, auth, billing, deployment, migration, or user-visible workflow change: use distinct fresh-context reviewers, and preserve the two top-level axes below.

Review-gate reviewers and validators are read-only unless the parent is intentionally launching the synthesized fix worker. When they have a configured output path, tell them: “Do not modify project/source files; writing the configured output artifact is allowed.” Reviewer prompts must tell reviewers to inspect the actual repository/diff directly and not rely on the worker’s reasoning. For audit/security/dead-code sweeps, use an adversarial shape when practical: finder agents report candidate issues, challenger agents try to disprove or downgrade them, and the parent reports only findings that survive cross-checking.

Two-axis review contract:
- **Standards axis:** compare the diff against documented repo standards and conventions: `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `CONTEXT.md`, `CONTEXT-MAP.md`, ADRs, style docs, and machine-enforced config such as lint/type/format settings. Cite the standard for each finding, distinguish hard violations from judgment calls, and skip issues already covered by automated tooling.
- **Spec axis:** compare the diff against the latest approved user contract: orchestration ledger, plan, issue, PRD, acceptance criteria, or explicit chat decision. Flag missing/partial requirements, scope creep, and behavior that appears implemented but wrong. Quote or reference the source of the requirement when possible.
- Keep the two axes separate in `review-findings.md`, reviewer artifacts, and the final report. Do not merge or rerank them in a way that lets standards compliance hide spec failure, or spec success hide standards violations.
- If no explicit spec exists, the Spec axis should say so and fall back to the ledger plus the latest approved user request.
- The parent must synthesize reviewer output into blockers, fixes worth doing now, optional/deferred items, and ignored feedback with reasons before launching any fix worker.
- If reviewers find non-trivial fixes and the fix pass changes meaningful code, run one focused follow-up review before final validation.

### Failure Recovery

When a subagent, team, process, validation, deploy, or OTA run fails:
1. Inspect the concrete artifact/log/status first; do not guess from the summary alone.
2. Update the ledger with what failed, evidence, and current handles.
3. Decide explicitly: resume with clearer instructions, replace the worker, fix locally, roll back, wait, or ask the user.
4. Do not spawn duplicate production/deploy/release work until the original run is accounted for.

### Anti-Over-Orchestration

Using `/orchestrate` does not mean every request needs a team. If the task is tiny, safe, and well-scoped, do it directly after brief clarification/recon, then validate and report. Use delegation when it reduces risk, improves context, or enables real parallel read/review/validation work.

### Scope-Change Freeze

When the user changes scope mid-run, freeze the old plan before continuing:
1. Update the ledger goal, status, next action, validation contract, runtime budget, stop rules, stage artifacts, and final report draft.
2. Reconcile open tasks, processes, teams, and subagents.
3. Reclassify the new work and decide whether it belongs in the same ledger or a new follow-up/release ledger.
4. Continue only from the latest approved scope.

## Hard Constraints

- Never commit or push unless the user explicitly asks in the current conversation.
- Do not silently change product, architecture, or release assumptions.
- Do not let multiple writers edit overlapping files in the same checkout.
- Do not start work that conflicts with an active coordination lane unless you deliberately wait, supersede, isolate, or get approval.
- Do not use UI-specialized agents for non-UI work by default.
- Do not use generic non-UI writers for meaningful UI implementation/review when configured UI agents are available.
- Do not hardcode UI agent model/thinking settings; use configured defaults unless the user explicitly overrides them.
- Keep the orchestrator responsible for decisions, integration, and final quality.
