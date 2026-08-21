# Doc Structure

## Model

`llmdoc` separates stable knowledge, pending doc-gaps, and temporary scratch space:

- `must/`: recurring must-read startup docs
- `overview/`: project or feature identity and boundaries
- `architecture/`: ownership boundaries, flows, invariants, retrieval maps
- `guides/`: one workflow per document
- `reference/`: stable lookup facts, schemas, conventions, contracts
- `memory/`: `doc-gaps.md` only — actionable documentation gaps with closure criteria
- `.llmdoc-tmp/`: local temporary context cache for scratch artifacts

Why this split works:

- stable docs stay small and reusable
- transient notes stop polluting architecture docs
- temporary reports can go stale or disappear without contaminating long-lived docs

`memory/` holds no permanent residents: every doc-gap entry either closes because the doc got fixed, or is removed as stale. Narrative process memory (per-task reflections, standalone decision records) is deliberately not stored — such narratives are unverifiable against the repository, and durable design rationale belongs in stable-doc prose as current-state facts ("X is deliberately absent because Y").

## Team baseline layer

A project may adopt a shared team baseline: a sibling repository of team-wide conventions, declared by `llmdoc/must/team-standards.md` through its machine-readable `- team-baseline-path: <path>` line. When a baseline is declared:

- the baseline is read-only input for every llmdoc workflow — never edit it from the project side, and never treat its relative-path references as dangling
- project llmdoc holds only project-specific facts and explicit deviations; team rules are referenced by relative path, never copied
- `reference/team-overrides.md` registers every deviation from the baseline, each with a currently-true reason; an unregistered deviation is a violation
- the fail-closed gate lives in `must/team-standards.md`: when the declared baseline entry is unreadable, code changes stop; read-only work continues with an explicit "team baseline not loaded" declaration

## Index responsibilities

`llmdoc/index.md` and `llmdoc/startup.md` must not duplicate each other.

Use this split:

- `llmdoc/index.md`: global map of the documentation system
- `llmdoc/startup.md`: startup reading order for recurring must-read docs

`llmdoc/index.md` should contain:

- the purpose of each top-level category
- the major documents or subsystem indexes available in each category
- routing hints for `must/`, `overview/`, `architecture/`, `guides/`, `reference/`, and `memory/`

`llmdoc/startup.md` should contain:

- only the startup reading order
- short escalation hints for what to read next

## Context budgets and monolith routing

The model-visible startup cost must remain bounded independently of the total number of llmdoc documents.

- Keep the root `index.md` as an L0 router. In a monolith, point it at subsystem indexes instead of listing every leaf document.
- Put L1 subsystem indexes beside the documents they route, for example `llmdoc/architecture/payments/index.md`.
- Load only the L1 index for the active subsystem, then only the leaf documents needed for the task.
- Do not add every subsystem index or leaf document to `startup.md`.
- Keep the UTF-8 size of `index.md` + `startup.md` + `must/` under 24 KiB by default. A project may set a stricter `LLMDOC_STARTUP_MAX_BYTES`; exceeding the budget is a maintenance signal, not permission to omit required invariants silently.
- Prefer no more than about eight task documents at once. If more appear necessary, route again by responsibility or runtime flow.

The byte limit is a deterministic proxy rather than an exact model-token count. It exists to prevent unbounded growth across models and languages.

## Ownership

- `recorder` owns `llmdoc/index.md`, `llmdoc/startup.md`, all stable docs, and `memory/doc-gaps.md`
- temporary investigation scratch stays in `.llmdoc-tmp/`

## Splitting rules

- One concept per document.
- One workflow per guide.
- One ownership boundary or invariant cluster per architecture doc.
- Put repeated startup knowledge in `must/`, not in `overview/`.
- In monoliths, add subsystem indexes instead of growing the root index into a leaf catalog.
- Triage process signals into stable-doc fixes or `memory/doc-gaps.md` entries; never into narrative memory files.
- Keep temporary investigation reports in `.llmdoc-tmp/`, not in `llmdoc/memory/`.

## Temporary Context Cache

`.llmdoc-tmp/` is deliberately outside stable llmdoc.

Use it for:

- investigator scratch reports under `.llmdoc-tmp/investigations/`
- hook logs or other local run artifacts
- temporary handoff notes that may help the current or next nearby session

Do not use it for:

- current-state snapshots that should be trusted by future users
- tracked project documentation
- entries in `llmdoc/index.md`
- doc-gap entries, which belong in `memory/doc-gaps.md`

Scratch reports may survive across sessions, but they are still temporary. Reuse them only after validating their recorded git revision, scope, and unresolved gaps against the current repository. If they are stale, delete or ignore them and investigate again.

## Recommended architecture slicing

Prefer slicing by responsibility, ownership, or runtime flow.

Good architecture doc families:

- request or command flow
- domain model and invariants
- persistence and data ownership
- external integrations
- async jobs and background processing
- frontend composition and state boundaries
- agent and workflow orchestration
