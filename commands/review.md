---
description: "Review a change set with the native code-quality pass plus an llmdoc/team-convention compliance pass, producing rule-cited findings."
argument-hint: "[--against REF] [--range A..B ...] [--commits SHA,SHA ...] [--staged] [--working-tree]"
---

# /llmdoc:review

Use this command to review a change set in an llmdoc-enabled project.

The review has two layers, and the second is what this command adds over a plain review:

1. **Native pass**: normal review judgment — correctness, concurrency, error handling, security, test coverage. Not constrained to written rules.
2. **Compliance pass**: check the change against the project's llmdoc conventions and, when present, the team baseline. Every compliance finding MUST cite the written rule it violates (file path + section, or a rule ID such as `T1`). A finding that cannot cite a written rule is a native finding or an opinion — never present an opinion as compliance.

Before executing, load the `llmdoc` skill and perform the cold-start reads if not already done this session.

This command is **read-only**: report findings; never edit code or docs during review. Doc defects discovered here are handed to `/llmdoc:update` signal triage, not fixed inline.

## Scope Resolution

Default scope: uncommitted work — `git diff --name-status -M -C -z HEAD` plus untracked files (`git ls-files --others --exclude-standard`).

- `--against REF`: review the branch — diff `$(git merge-base REF HEAD)..HEAD` so upstream commits are excluded, folding in the working tree.
- `--range A..B` (repeatable) / `--commits SHA,…`: explicit ranges, parsed exactly like `/llmdoc:update` (rename/copy records carry two path tokens; reject merge commits in `--commits`).
- `--staged` / `--working-tree`: restrict to the staged set or the full working tree.

Read committed-range file content at the range tip (`git show <tip>:<path>`); read working-tree files from disk. In a non-git project, review the files the user names.

## Rule Sources (compliance pass)

Resolve the applicable rule set before reading the diff in depth:

1. **Project llmdoc**: `must/` rules, `reference/` conventions, `architecture/` invariants, and the `guides/` mapped to the touched subsystems via `must/doc-routing.md` and `llmdoc/index.md`.
2. **Team baseline**. A baseline is declared when `llmdoc/must/team-standards.md` exists AND carries the machine-readable `- team-baseline-path:` line. When declared, read the baseline conventions and checklists relevant to the diff.
   - Baseline declared but unreadable: the review may continue (it is read-only), but the report MUST open with a "team baseline not loaded" declaration, and the compliance pass MUST be marked incomplete. Never reconstruct team rules from memory.
   - `team-standards.md` exists but the declaration line is missing: treat it as a malformed declaration — report it as a doc defect under Doc impact, and mark the compliance pass incomplete the same way.
3. **Override registry** (`reference/team-overrides.md`, when present): a registered deviation SUPPRESSES the corresponding baseline-rule finding — do not report it as a violation. Instead verify that the recorded reason is still a true fact about the repository; if it no longer holds, report a `stale-override` finding citing the registry row.

An unregistered deviation from a baseline rule is always a violation finding, even when the project's existing code deviates the same way — cite the rule and note the precedent separately.

## Review Passes

Run in order; later passes reuse earlier evidence:

1. **Native pass** over the diff: bugs, correctness, concurrency, error handling, security, tests. Normal judgment.
2. **Compliance pass**: for each changed file, check the resolved rule set. Cite every finding (`<rule file> §<section>` or rule ID). Do not flag rules that plainly do not apply to the touched code.
3. **Checklist pass**: when domain or otherwise gated code changed and an applicable checklist exists (team change checklist, project-specific checklist items), evaluate each applicable item and report pass / fail / not-applicable per item ID.
4. **Doc-impact pass**: does the change contradict a stable llmdoc claim, or introduce knowledge worth persisting? Report whether `/llmdoc:update` is warranted and name the impacted docs. Doc defects found while reviewing are reported here as triage input, not fixed.

## Output

Open with the verdict summary (and the baseline-not-loaded declaration when applicable), then:

- **Native findings**: severity, `file:line`, what is wrong, why it matters, suggested fix.
- **Compliance findings**: severity, `file:line`, the violated rule citation, what deviates, suggested fix. Include `stale-override` findings here.
- **Checklist results**: per item ID — pass / fail / not-applicable, with one-line evidence for fail.
- **Doc impact**: whether to run `/llmdoc:update`, impacted docs, and any doc-defect signals to carry into its triage.

Rank findings by severity within each section. When a section is empty, state that explicitly — an empty compliance section with a loaded baseline is a meaningful result, an empty one with an unloaded baseline is not.

## Invariants

- Review never edits files; it only reports.
- Compliance findings without a rule citation are invalid — recategorize or drop them.
- A registered override is not a violation; a stale override reason is.
- An unreadable declared baseline never silently downgrades the review: the gap is stated in the opening line.
