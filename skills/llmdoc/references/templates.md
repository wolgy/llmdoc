# Templates

## `index.md`

```md
# llmdoc Index

## Purpose
- This file is the global map of the llmdoc system.
- If `startup.md` exists, startup reading continues there.

## Categories
- `must/`: startup pack for recurring task context
- `overview/`: project and feature identity
- `architecture/`: flows, invariants, and ownership boundaries
- `guides/`: workflow-specific instructions
- `reference/`: stable lookup facts and contracts
- `memory/`: `doc-gaps.md` — actionable documentation gaps

## Key Documents
- `llmdoc/startup.md`: startup reading order
- `llmdoc/overview/project-overview.md`: project identity and boundaries
- Add the main architecture, guide, and reference docs here with one-line descriptions

## Routing Rules
- Read `startup.md` once for cold-start context
- After context compaction, continue from `LLMDOC_STATE` instead of replaying the startup pack
- Read `guides/` before editing a known workflow
```

## `startup.md`

```md
# Startup

Read in order once on cold start:

1. `llmdoc/must/project-basics.md`
2. `llmdoc/must/working-agreement.md`
3. `llmdoc/must/doc-routing.md`

Escalate to more docs when:
- touching a specific subsystem
- changing architecture or conventions
- updating workflows or stable docs

Read related guides before editing when available.

After context compaction, continue from the preserved task state. Re-read only the smallest relevant document set when the state is stale, insufficient, or the work enters a new subsystem.
```

For a monolith, keep the root index as an L0 router and add subsystem indexes such as `llmdoc/architecture/<subsystem>/index.md`; never add every leaf document to the startup list.

## `state/sync.md`

Machine-managed commit watermark. Seed at init with `watermark-commit=$(git rev-parse HEAD)`. Keep the `watermark-commit` line isolated by blank lines (minimizes merge-conflict surface). Never index it, never add it to `startup.md`/`must/`, never count it as active memory.

```md
# llmdoc sync state
<!-- Machine-managed by /llmdoc:update. Do not hand-edit watermark-commit except to
     recover from a rebase. Never add to startup.md / MUST. Never index as knowledge. -->

- schema: 1

- watermark-commit: <full commit SHA of HEAD at init>

- watermark-subject: <subject line of the watermark commit>
- updated-at: <ISO-8601 UTC>
- updated-by: /llmdoc:init (seed)
```

## `overview/project-overview.md`

```md
# Project Overview

## Identity
- What this project is.
- What problem it solves.

## Boundaries
- What belongs here.
- What does not belong here.

## Major Areas
- Main subsystems and their roles.
```

## `architecture/<concept>.md`

```md
# Architecture of <Concept>

## Purpose
- Why this subsystem exists.

## Core Components
- `path/to/file.ext` (`SymbolName`): Responsibility.

## Flow
- Entry point.
- Main delegation path.
- Important invariants or failure points.

## Related Docs
- Other llmdoc paths to read next.
```

## `guides/<workflow>.md`

```md
# How to <Do One Thing>

1. Preconditions
2. Main steps
3. Verification
4. Common failure points
5. Related docs
```

## `reference/<topic>.md`

```md
# <Topic> Reference

## Scope
- What this document covers.

## Stable Facts
- Contracts, schemas, conventions, or rules.

## Sources of Truth
- `path/to/file.ext` (`SymbolName`): Why it matters.
```

## `memory/doc-gaps.md`

```md
# Documentation Gaps

## Open Gaps
- <Actionable gap>. Closure: <verifiable condition under which this entry is removed>.
```

## `must/team-standards.md` (only when a team baseline is wired in)

Prefer the baseline repository's own `templates/` when it ships one; this generic template is the fallback. Keep the `- team-baseline-path: ` line prefix exact — tooling anchors on it.

```md
# Team Baseline Entry (fail-closed)

- team-baseline-path: ../<team-baseline-repo>

## Path convention
The team baseline repository must be cloned as a sibling of this project.
All baseline references in this repository are relative to the project root.

## Gate: baseline unreadable → no code changes
Before ANY code change, verify `<team-baseline-path>/index.md` is readable. When it is not:
- make NO code change; do not fill the gap from default habits
- tell the user to clone the baseline repository, then retry
- exception: read-only Q&A may continue, but must open with a "team baseline not loaded" declaration

## Team must-reads
1. <baseline doc to read every session>
2. <baseline doc to read before writing any code>

## Team ↔ project mapping
| Topic | Team baseline | Project supplement |
|---|---|---|
```

## `reference/team-overrides.md` (only when a team baseline is wired in)

```md
# Team Baseline Deviation Registry

Every deviation from the team baseline is registered here. An unregistered deviation is a violation.

| Baseline rule (file + section or ID) | This project's practice | Reason (must be a currently-true fact) | Convergence planned |
|---|---|---|---|
```

## `.llmdoc-tmp/investigations/<topic>.md`

```md
# Investigation Scratch Report

## Metadata
- Date:
- Git Revision:
- Evidence Scope:
- Reuse Conditions:

## Goal
- What questions this scratch report answers.

## Evidence
- `path/to/file.ext` (`SymbolName`): Relevant fact.

## Interim Findings
- Working conclusions for init or update.

## Promotion Notes
- What should become stable docs.
- What should stay temporary and be deleted later.

## Gaps
- What remains unresolved or needs fresh investigation before reuse.
```
