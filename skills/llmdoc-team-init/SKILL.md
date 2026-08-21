---
name: llmdoc-team-init
description: "Codex-native entry skill for initializing or retrofitting llmdoc in a project governed by a shared team baseline repository; asks for the baseline's sibling location. Use this when you want the /llmdoc:team-init workflow in Codex."
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, WebSearch, WebFetch
---

# llmdoc-team-init

This skill is the Codex-native equivalent of `/llmdoc:team-init`. Use it instead of `llmdoc-init` for a project governed by a shared team baseline repository (a repo of team-wide conventions, e.g. `hmbird-llmdoc`).

The standard `llmdoc-init` workflow remains the base contract; this skill adds the team wiring on top.

## Workflow

1. Resolve the baseline location (ask, don't guess). Use the path from `$ARGUMENTS` when given; otherwise ASK the user where the team baseline repository is, reminding them of the sibling constraint: the baseline must be cloned as a **sibling of the project root**, because every reference to it is a project-root-relative `../<dirname>/...` path. Only accept a sibling-form path (`../<dirname>`); when the repo currently lives elsewhere, tell the user to clone or move it to a sibling first.
2. Gate (fail-closed). Verify `<team-baseline-path>/index.md` is readable. Unreadable → STOP, make no changes, tell the user to clone the baseline as a sibling, then retry. Never scaffold team files from memory when the baseline is absent. The baseline is READ-ONLY input for the whole run.
3. Read the team entry docs: the baseline's `index.md` plus its workflow and template docs (e.g. `templates/new-project-llmdoc.md`, `templates/team-overrides.md`). The baseline's templates are the source of truth for team-file content; `skills/llmdoc/references/templates.md` is only a fallback for baselines without templates.
4. Wire the team files:
   - `llmdoc/must/team-standards.md` from the baseline's new-project template, adjusted to this project's name, carrying the machine-readable line `- team-baseline-path: <sibling path>`, the fail-closed gate wording, the team must-read list, and the team↔project mapping table
   - `llmdoc/reference/team-overrides.md` from the baseline's override template (an unregistered deviation is a violation)
   - `llmdoc/startup.md` with the gate as step 0 and `must/team-standards.md` first in the reading order
5. Initialize or retrofit the rest. No `llmdoc/` yet → run the full `llmdoc-init` workflow with the team additions; existing `llmdoc/` → retrofit only (add team files, update startup, reconcile against the delta principle). Team additions:
   - investigators read the baseline index and stack-relevant conventions BEFORE code, and every investigator prompt carries that context
   - project docs hold only project-specific deltas; reference team rules by relative path, never copy them
   - seed `reference/team-overrides.md` only with verified deviations (team rule citation + currently-true reason); suspected ones become `memory/doc-gaps.md` entries
   - follow the baseline's ID-namespace convention for project checklist items
6. Synchronize `llmdoc/index.md` per the standard init contract.
7. Summarize what was created or retrofitted, and confirm the gate: the declared baseline path and its readability.
