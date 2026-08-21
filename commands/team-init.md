---
description: "Initialize or retrofit llmdoc for a project governed by a shared team baseline repository, asking for its sibling location (fail-closed)."
argument-hint: "[team-baseline-path]"
---

# /llmdoc:team-init

Use this command instead of `/llmdoc:init` for a project governed by a shared team baseline repository (a repo of team-wide conventions, e.g. `hmbird-llmdoc`).

The standard init workflow in `commands/init.md` remains the base contract; this command adds the team wiring on top and does not repeat what that contract already defines. Before executing, load the `llmdoc` skill.

## Actions

1. Resolve the baseline location (ask, don't guess).
   - When `$ARGUMENTS` carries a path, use it. Otherwise ASK the user where the team baseline repository is. Never guess or probe on the user's behalf.
   - Remind the user of the sibling constraint while asking: the baseline must be cloned as a **sibling of the project root**, because every reference to it is written as a project-root-relative `../<dirname>/...` path.
   - Only accept a sibling-form path (`../<dirname>`). When the user names a repository that currently lives elsewhere, do not wire that location in — tell them to clone (or move) it to a sibling directory first, then continue with the sibling path.

2. Gate (fail-closed).
   - Verify `<team-baseline-path>/index.md` is readable from the project root.
   - Unreadable → STOP the whole command. Make no changes. Tell the user to clone the baseline as a sibling of the project, then retry. Never scaffold team files from memory or from the generic templates when the baseline itself is absent.
   - The baseline is READ-ONLY input for the whole run: never create, edit, or "fix" files inside it.

3. Read the team entry docs.
   - Read the baseline's `index.md` and its listed workflow and template docs (for example `templates/new-project-llmdoc.md` and `templates/team-overrides.md` when present).
   - The baseline's own templates are the source of truth for team-file content; the generic templates in `skills/llmdoc/references/templates.md` are only a fallback for baselines that ship no templates.

4. Wire the team files into `llmdoc/`.
   - `llmdoc/must/team-standards.md`: from the baseline's new-project template when present, adjusted to this project's name. It must carry the machine-readable declaration line `- team-baseline-path: <sibling path>`, the fail-closed gate wording, the team must-read list, and the team↔project mapping table.
   - `llmdoc/reference/team-overrides.md`: from the baseline's override template — the deviation registry. An unregistered deviation is a violation.
   - `llmdoc/startup.md`: the gate check is step 0, and `must/team-standards.md` comes first in the reading order.

5. Initialize or retrofit the rest.
   - No `llmdoc/` yet → run the full `/llmdoc:init` workflow (skeleton, watermark seed, multi-investigator passes, stable docs, index sync) with the team additions below.
   - `llmdoc/` already exists → retrofit only: add the team files, update `startup.md`, and reconcile existing docs against the delta principle; do not regenerate docs that are already correct.
   - Team additions to the base workflow:
     - Investigators read the baseline `index.md` and the stack-relevant conventions BEFORE investigating code, and every investigator prompt carries that context — otherwise deviations get documented as house style instead of being recognized as deviations.
     - Project docs hold only project-specific deltas: reference team rules by relative path (`<team-baseline-path>/...`, written as code spans, resolved from the project root), never copy them.
     - Seed `reference/team-overrides.md` with the deviations the investigation actually verified — each row cites the team rule (file + section or ID) and a currently-true reason. Suspected-but-unverified deviations become `memory/doc-gaps.md` entries with closure criteria, not override rows.
     - Follow the baseline's ID-namespace convention when adding project checklist items (team and project item IDs must not overlap).

6. Synchronize `llmdoc/index.md` per the standard init contract.

7. Summarize what was created or retrofitted, where the startup docs live, and confirm the gate: the declared baseline path and its current readability.
