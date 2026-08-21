---
name: llmdoc-review
description: "Codex-native entry skill for reviewing a change set with the native code-quality pass plus an llmdoc/team-convention compliance pass. Use this when you want the /llmdoc:review workflow in Codex."
allowed-tools: Read, Glob, Grep, Bash
---

# llmdoc-review

This skill is the Codex-native equivalent of `/llmdoc:review`.

Use it when:

- a change set should be reviewed before commit, push, or merge
- the review must check llmdoc conventions and the team baseline, not only generic code quality
- you want rule-cited compliance findings instead of style opinions

The review has two layers:

1. **Native pass**: normal review judgment — correctness, concurrency, error handling, security, tests.
2. **Compliance pass**: check the change against project llmdoc conventions and, when present, the team baseline. Every compliance finding MUST cite the written rule it violates (file path + section, or a rule ID). A finding without a citation is a native finding or an opinion — never present an opinion as compliance.

The review is **read-only**: report findings; never edit code or docs. Doc defects found here become triage input for `llmdoc-update`.

Read scope flags from `$ARGUMENTS` / the user message:
`[--against REF] [--range A..B ...] [--commits SHA,SHA ...] [--staged] [--working-tree]`

## Workflow

1. Load the `llmdoc` skill and perform the cold-start reads if not already done this session.
2. Resolve scope. Default: `git diff --name-status -M -C -z HEAD` plus untracked files. `--against REF` diffs `$(git merge-base REF HEAD)..HEAD` plus the working tree. Ranges parse exactly like `llmdoc-update` (rename/copy records carry two path tokens; reject merge commits in `--commits`). Read committed content at the range tip (`git show <tip>:<path>`), working-tree content from disk.
3. Resolve the rule set:
   - project llmdoc: `must/` rules, `reference/` conventions, `architecture/` invariants, and the `guides/` mapped to touched subsystems via `must/doc-routing.md`
   - team baseline: declared when `llmdoc/must/team-standards.md` exists AND carries the machine-readable `- team-baseline-path:` line. When declared, read the conventions and checklists relevant to the diff. Declared but unreadable → continue (read-only), but the report MUST open with a "team baseline not loaded" declaration and mark the compliance pass incomplete; never reconstruct team rules from memory. File present but line missing → malformed declaration: report it as a doc defect under Doc impact and mark the compliance pass incomplete the same way.
   - override registry (`reference/team-overrides.md`, when present): a registered deviation suppresses the corresponding baseline finding; verify its recorded reason is still true and report a `stale-override` finding when it is not. An unregistered deviation is always a violation, even when existing code deviates the same way.
4. Run the passes in order: native → compliance (rule-cited) → checklist (per applicable item ID: pass / fail / not-applicable) → doc-impact (does the change contradict stable llmdoc claims or warrant `llmdoc-update`?).
5. Report: verdict summary first (with the baseline declaration when applicable), then Native findings, Compliance findings (including `stale-override`), Checklist results, and Doc impact. Each finding: severity, `file:line`, what, why (rule citation for compliance), suggested fix. State empty sections explicitly.

## Invariants

- Review never edits files; it only reports.
- Compliance findings without a rule citation are invalid — recategorize or drop.
- A registered override is not a violation; a stale override reason is.
- An unreadable declared baseline never silently downgrades the review.
