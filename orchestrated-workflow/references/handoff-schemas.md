# Structured Orchestration Handoff Schemas

Use `references/handoff-schemas.json` when a child agent should return a predictable handoff instead of freeform prose. The schemas are optional contracts for Pi subagent/team prompts rather than a new runtime dependency.

Keep this file and `references/handoff-schemas.json` in sync when adding fields.

## When to use

Use structured handoffs for:

- scouts and context builders that feed a plan
- workers that changed files
- reviewers and validators whose output will drive fix/no-fix decisions
- synthesis steps that update the orchestration ledger and final report draft
- safety-sensitive data/deploy/destructive work where target, approval, dry-run, rollback, and verification evidence must survive compaction

For tiny tasks, normal concise prose is enough.

## How to prompt children

Ask the child to end with a fenced JSON object matching one of these `kind` values:

- `scout`
- `worker`
- `reviewer`
- `validator`
- `synthesis`

Tell the child: “Return concise prose first only if needed, then finish with one fenced JSON object matching the `<kind>` schema in `references/handoff-schemas.json`.” If the child tool/runtime supports JSON Schema structured output, pass the full schema with the selected top-level `$ref`, or bundle the selected `$defs` schema together with every referenced definition so `$ref`s resolve.

For broad scouts, reviewers, and validators, also say:

- write the full result to the configured artifact path
- keep parent-visible prose short
- include at most top findings, evidence paths/line refs, commands with exit codes, open questions, and risks
- do not paste raw logs, full diffs, transcripts, or long reasoning
- if you approach your turn/time budget, stop early and leave `coverage`, `notInspected`, `resumeFrom`, and `partial: true`

## Shared audit-derived fields

Schemas may include these fields when relevant:

- `coverage`: areas actually inspected
- `notInspected`: important areas skipped and why
- `resumeFrom`: next file/query/check if interrupted
- `partial`: whether the artifact is intentionally partial but useful
- `activeHandlesDelta`: handle changes for parent ledger reconciliation
- `contextEvidence`: artifact/log path plus minimal quoted evidence, with bulky output omitted
- `safetyGate`: target, environment, approval, dry-run, rollback/backup, post-verify, and secret-redaction evidence

Example shared snippets:

```json
{
  "activeHandlesDelta": [
    {
      "id": "proc-12",
      "kind": "process",
      "owner": "validator",
      "lane": "build",
      "status": "complete",
      "lastSeen": "2026-06-07T12:00:00.000Z",
      "expectedNextCheck": null,
      "staleIfAfter": null,
      "artifactOrLogPath": "validation.md",
      "disposition": "complete"
    }
  ],
  "contextEvidence": {
    "artifactPath": "validation.md",
    "logPath": "validation.log",
    "quotedLines": "minimal relevant lines only",
    "omittedBulkyOutput": true
  },
  "safetyGate": {
    "target": "staging-db/customers",
    "environment": "staging",
    "approval": "captured",
    "dryRunArtifact": "dry-run.md",
    "backupOrRollback": "backup id/path or rollback note",
    "postVerify": "passed: counts match expected range",
    "secretRedaction": "secrets and row values redacted; counts only reported"
  }
}
```

## Stage updates

Every schema can include a `stageUpdate` (or `stageUpdates` for synthesis):

```json
{
  "label": "Review",
  "status": "done",
  "owner": "reviewer",
  "inputs": ["worker-handoff.md"],
  "outputs": ["review-findings.md"],
  "synthesis": "review-findings.md",
  "stopRule": "no blocker findings"
}
```

Mirror those updates into the ledger `## Stage Artifacts` section.

## Minimal examples

### Scout

```json
{
  "kind": "scout",
  "summary": "Mapped the auth flow and found two likely entry points.",
  "relevantFiles": [
    { "path": "src/auth/session.ts", "reason": "Session creation", "lines": "10-80" }
  ],
  "entryPoints": ["src/auth/session.ts"],
  "constraints": ["No production data inspected"],
  "coverage": ["auth/session", "auth/routes"],
  "notInspected": ["billing integration not relevant to requested scope"],
  "topFindings": ["Session refresh owns the failing behavior"],
  "resumeFrom": "src/auth/refresh.ts",
  "partial": false,
  "openQuestions": [],
  "risks": [],
  "contextEvidence": { "artifactPath": "scout.md", "logPath": null, "quotedLines": "paths only", "omittedBulkyOutput": true },
  "stageUpdate": { "label": "Recon", "status": "done", "owner": "scout" }
}
```

### Worker

```json
{
  "kind": "worker",
  "summary": "Implemented the approved UI adapter batch.",
  "changedFiles": [{ "path": "src/ui/native-switch.tsx", "reason": "Added native switch adapter", "lines": null }],
  "decisions": [],
  "validation": [{ "command": "pnpm typecheck", "status": "passed", "exitCode": 0, "evidence": "completed without errors", "logPath": "validation.md" }],
  "leftUndone": [],
  "risks": [],
  "needsParentDecision": [],
  "activeHandlesDelta": [],
  "contextEvidence": { "artifactPath": "worker-handoff.md", "logPath": "validation.md", "quotedLines": "typecheck passed", "omittedBulkyOutput": true },
  "stageUpdate": { "label": "UI", "status": "done", "owner": "ui-worker" }
}
```

### Reviewer

```json
{
  "kind": "reviewer",
  "verdict": "fail",
  "summary": "One blocker remains in the validation path.",
  "findings": [
    {
      "severity": "blocker",
      "axis": "validation",
      "title": "Typecheck not rerun after fix",
      "evidence": "worker changed src/ui/native-switch.tsx after the last typecheck",
      "path": "src/ui/native-switch.tsx",
      "line": null,
      "recommendation": "rerun typecheck before finalizing",
      "fixWorthDoingNow": true
    }
  ],
  "coverage": ["changed UI adapter", "validation artifact"],
  "notInspected": [],
  "resumeFrom": null,
  "partial": false,
  "standardsChecked": ["AGENTS.md"],
  "specSourcesChecked": ["state.md", "plan.md"],
  "contextEvidence": { "artifactPath": "review-findings.md", "logPath": null, "quotedLines": "one blocker summary", "omittedBulkyOutput": true },
  "stageUpdate": { "label": "Review", "status": "blocked", "owner": "reviewer" }
}
```

### Validator with safety gate

```json
{
  "kind": "validator",
  "verdict": "pass",
  "summary": "Dry-run and post-change verification passed for staging cleanup.",
  "checks": [
    { "command": "cleanup --dry-run", "status": "passed", "exitCode": 0, "evidence": "3 rows would be affected", "logPath": "dry-run.md" },
    { "command": "verify-counts", "status": "passed", "exitCode": 0, "evidence": "counts match expected range", "logPath": "validation.md" }
  ],
  "evidencePaths": ["dry-run.md", "validation.md"],
  "blockers": [],
  "safetyGate": {
    "target": "staging cleanup job",
    "environment": "staging",
    "approval": "captured",
    "dryRunArtifact": "dry-run.md",
    "backupOrRollback": "backup path recorded in deploy-result.md",
    "postVerify": "passed",
    "secretRedaction": "only counts and safe IDs reported"
  },
  "stageUpdate": { "label": "Validate", "status": "done", "owner": "validator" }
}
```
