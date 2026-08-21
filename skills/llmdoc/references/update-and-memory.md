# Update And Memory

## Update protocol

When project knowledge changes, use `/llmdoc:update`.

Tracked `llmdoc/` docs should describe the current repository. They should be smaller than the source code they describe, or add architectural intent, boundaries, and implementation reasoning that raw source search does not provide quickly.

## Commit watermark

Change detection is commit-based, anchored on a durable, git-tracked watermark: `llmdoc/state/sync.md`, whose one load-bearing field `watermark-commit` is the last source commit already reflected in `llmdoc/`.

- Default change set = the NET diff `watermark..HEAD` (`git diff --name-status -M -C -z`): the current state of every path touched since the watermark.
- Multiple batches can be consumed in one run (`--range` repeatable, `--commits`, `--since`, `--from`, `--working-tree-only`); all impact sets are unioned and processed in a single pass.
- Uncommitted working-tree/staged/untracked changes are always an ADDITIONAL input, but they never advance the watermark.
- `recorder` advances the watermark only as the terminal step of a complete, successful update that consumed a committed range.
- `llmdoc/state/sync.md` is machine-managed state, not project knowledge: never index it, never put it in `startup.md`/`must/`, never count it as active memory.

The resolution ladder, batch flags, degraded-mode handling, and exact git commands are the contract in `commands/update.md` and `skills/llmdoc-update/SKILL.md`. Invariants, design rationale, and verified git semantics: `llmdoc/architecture/update-orchestration.md`.

### Net diff vs per-commit

- `recorder` documents CURRENT state, read at the batch tip (`git show <tip>:<path>`, never HEAD/disk except for the uncommitted working-tree set). The net diff decides which docs change and what they now say. Never document an intermediate state absent at the tip.
- `investigator` may consult per-commit history (`git log`, `git show`, `--first-parent`) only to explain WHY a change happened. Per-commit history never decides which docs change.

## Update modes

Choose the lightest mode that keeps the docs correct. The trigger is range size × authorship × risk, not context freshness:

- `fast`: small range (≤ ~3 commits), self-authored, impacted docs nameable. Use the task summary, diff, targeted checks, and any still-valid local scratch reports.
- `analysis`: ~4–15 commits, OR any non-self-authored commit, OR multiple clusters, OR a recovered/derived/first-run baseline. One focused evidence pass.
- `full`: > ~15 commits, multi-batch backfill, history-rewrite recovery, disputed facts, or failure-heavy tasks — separate investigation and stable-doc maintenance.

Hard floors force ≥ `analysis`: a merge-base-recovered baseline, a derived/first-run baseline, or any non-self-authored commit. A first-run/`--since` range beyond ~20 commits or ~50 files forces `full` and explicit user confirmation. Freshness of the assistant's context is an input to mode selection, not the source of change detection.

The update order is:

1. rebuild task context
2. choose update mode
3. investigate only when the mode requires it
4. triage process signals (fix now / doc-gap / discard)
5. update stable docs and reconcile `memory/doc-gaps.md`
6. sync `llmdoc/index.md`

Why signal triage comes before stable-doc edits:

- process failures are freshest immediately after the task
- missing-doc signals are easier to capture before they are rationalized away
- stable docs should absorb only verifiable fixes, not raw narratives

Routine `fast` updates with no signals skip triage entirely.

## Temporary investigation cache

Investigation scratch belongs under `.llmdoc-tmp/investigations/`.

These files are local temporary context cache:

- they may survive across sessions
- they are ignored by git and may be deleted
- they are not indexed by `llmdoc/index.md`
- they are evidence to validate, not project truth

Each reusable scratch report should record enough context to decide whether it is still valid:

- goal and concrete questions
- date and git revision when available
- evidence scope
- conclusions
- unresolved gaps
- promotion candidates for tracked docs

If the current repository no longer matches the scratch report's revision, scope, or assumptions, ignore it or redo the investigation.

Cleanup is active, not just permitted:

- `/llmdoc:update` garbage-collects consumed reports (recorded `Range:` tip already covered by the new watermark, or recorded revision missing) after every successful watermark advance
- `/llmdoc:init` re-bootstrap deletes reports that are stale by their own metadata
- the optional `Stop` hook prunes its own logs under `.llmdoc-tmp/hooks/` after 7 days

Git never tracks `.llmdoc-tmp/`, so these deletions are final and need no archive.

## End-of-task update prompt

At the end of a non-trivial task, the main assistant should actively evaluate whether the user should be prompted to run `/llmdoc:update`.

Prompt the user when any of these are true:

- project structure, architecture, or ownership boundaries changed
- a workflow, convention, or invariant became clearer
- a mistake, failure, or correction pointed at a doc defect
- new knowledge was discovered that future tasks should reuse
- a guide, reference, startup doc, or doc-gap record is stale or missing

Recommended behavior:

1. Briefly name the knowledge that changed.
2. Explain why it is worth persisting.
3. Ask whether to run `/llmdoc:update` now.

## Process-signal triage

llmdoc deliberately stores no narrative process memory. A stable-doc claim is falsifiable against the repository; a narrative about a past task is not, and unverifiable narratives that get read as quality input contaminate future work. Every process signal therefore has exactly three exits:

- **fix now**: the signal traces to a stable-doc defect — a wrong claim, a missing route, an ambiguous contract — that can be verified against the current repository. Fix the doc in the same update.
- **doc-gap**: the defect is real but cannot be fixed in this run. Record an actionable entry with closure criteria in `memory/doc-gaps.md`.
- **discard**: the signal cannot be attributed to a verifiable doc defect. Treat it as noise; do not store it "for later" — later has no referee.

Signal sources worth checking at triage time:

- worker `Process Signals` handoffs
- doc defects reported by `/llmdoc:review` (its Doc impact section hands them off for triage)
- failed commands, tests, permission denials, retry loops
- user corrections and redirections
- rework: files edited repeatedly for the same goal, reverts visible in git history
- tool results that contradicted a stated expectation or a doc claim

The recurrence test separates fix-now from discard for workflow signals: would another competent agent, following the same docs on the same task, likely hit the same problem? If yes, the docs are defective — fix them or record the gap. If no, it is run-specific noise.

Durable design rationale is written into the relevant stable doc's prose as current-state facts ("X is deliberately absent because Y"), never into separate decision or reflection files.

## Memory ownership

- `recorder` maintains `llmdoc/memory/doc-gaps.md` — the only file under `llmdoc/memory/`
- `recorder` is the sole writer of `llmdoc/state/sync.md` (the commit watermark), advancing it only as the terminal step of a successful update; it is machine-managed state, not memory or knowledge

`memory/` holds no permanent residents: every `doc-gaps.md` entry either closes because the doc got fixed, or is removed as stale. Durable knowledge lives only in stable docs.

During every non-trivial update, reconcile `memory/doc-gaps.md`: close gaps that the update resolved, mark stale gaps when the underlying concern no longer applies, and add only actionable new gaps with a clear closure condition.
