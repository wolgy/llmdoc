<!--
  Human-facing release notes. Deliberately referenced by NO llmdoc runtime surface:
  do not reference or index this file from llmdoc/index.md, startup.md, must/,
  skills/, commands/, or agents/, and do not let recorder absorb it as knowledge.

  This English version is the default and authoritative one. Keep the Chinese
  translation (CHANGELOG.zh-CN.md) in sync with every release entry.
-->

# Changelog

[中文版](CHANGELOG.zh-CN.md)

## 2.3.0-team.1 — 2026-08-21

### Added: `/llmdoc:review` two-layer code review (command + Codex skill)

New `commands/review.md` (Claude Code command `/llmdoc:review`) and `skills/llmdoc-review/SKILL.md` (Codex helper skill `llmdoc-review`), layering an llmdoc convention-compliance review on top of the native review:

- **Two layers**: a native pass (correctness / concurrency / error handling / security / tests, normal review judgment) plus a compliance pass (against project llmdoc conventions and the team baseline);
- **Every compliance finding must cite the written rule** (file + section, or rule ID); findings without a citation are downgraded to native findings or opinions — the same falsifiability principle this release is built on;
- **Team-baseline awareness**: a baseline is declared when `llmdoc/must/team-standards.md` exists and carries the machine-readable `- team-baseline-path:` line; a declared-but-unreadable baseline lets the (read-only) review continue, but the report must open with a "team baseline not loaded" declaration and mark the compliance pass incomplete — reconstructing team rules from memory is forbidden; a file without the declaration line is a malformed declaration reported as a doc defect;
- **Override suppression**: deviations registered in `reference/team-overrides.md` are not reported as violations, but a registered reason that no longer holds is reported as `stale-override`; unregistered deviations are always violations (even when existing code deviates the same way);
- **Checklist pass**: when applicable checklists exist (e.g. team T-items / project A-items), each item is evaluated as pass / fail / not-applicable by ID;
- **Read-only invariant**: the review never edits files; doc defects it surfaces are handed to `/llmdoc:update` signal triage;
- Scope resolution reuses the update command's git plumbing conventions: uncommitted work by default, `--against REF` (merge-base based, excludes upstream commits), `--range`, `--commits` (merge commits rejected), `--staged`, `--working-tree`.

Also updated: both READMEs, `skills/README.md`, `llmdoc/reference/repo-surfaces.md`, `llmdoc/must/doc-routing.md`, `.codex-plugin/plugin.json` (defaultPrompt gains a review entry; the Codex plugin auto-discovers new skills from `skills/`).

### Added: `/llmdoc:team-init` team-baseline init (command + Codex skill)

New `commands/team-init.md` (`/llmdoc:team-init`) and `skills/llmdoc-team-init/SKILL.md` (`llmdoc-team-init`). The standard `/llmdoc:init` stays untouched; team-governed projects use team-init, which layers team wiring on top of the standard init contract:

- **Ask, don't guess**: init asks the user where the team baseline repository is (or takes it as an argument) — no probing. The prompt reminds the user of the **sibling constraint**: the baseline must be cloned as a sibling of the project root, because every reference is a project-root-relative `../<dirname>/...` path; only sibling-form paths are accepted, and a repository living elsewhere must be cloned/moved to a sibling first. Fail-closed: when the declared path's `index.md` is unreadable the whole command stops with zero changes; scaffolding team files from memory or generic templates while the baseline is absent is forbidden;
- **Team wiring scaffold**: generates `must/team-standards.md` (fail-closed gate + machine-readable `- team-baseline-path: <sibling path>` line + team must-read list + team↔project mapping table) and `reference/team-overrides.md` (deviation registry), sourced from the baseline's own `templates/` (the generic templates in `references/templates.md` are only a fallback for baselines without templates); the gate becomes step 0 of `startup.md`;
- **Two modes**: no `llmdoc/` yet → full init workflow plus the team additions; existing `llmdoc/` → retrofit only, without regenerating docs that are already correct;
- **Investigation ordering**: investigators read the baseline conventions BEFORE code, and every investigator prompt carries that context — otherwise deviations get documented as house style;
- **Delta principle**: project docs hold only project-specific deltas, referencing team rules by relative path instead of copying them; verified deviations (rule citation + a currently-true reason) go into the override registry, suspected ones become doc-gaps with closure criteria; project checklist items follow the baseline's ID-namespace convention;
- **Baseline read-only invariant**: `doc-structure.md` gains a "Team baseline layer" section defining the two-layer knowledge model; recorder (agent + Codex TOML) gains rules — the declared baseline repository is always read-only, its relative-path references are not dangling, and gate wording is not a stale claim, so `/llmdoc:update` cannot damage the team wiring; worker gains gate inheritance — it honors the fail-closed gate even when the caller referenced specific docs.

The machine-readable `- team-baseline-path:` line is also the parse anchor for the `/llmdoc:review` compliance layer. All surfaces stay generic — no team repository name is hardcoded; `hmbird-llmdoc` appears only as an example.

### Added: deterministic `.llmdoc-tmp/` cleanup

Upstream only grants permission to delete scratch artifacts; nothing actually deletes them. This release adds three deterministic rules (zero model cost):

- **Update terminal GC**: after `/llmdoc:update` successfully advances the watermark, delete reports under `.llmdoc-tmp/investigations/` whose recorded `Range:` tip is an ancestor of the new watermark (consumed evidence) and reports whose recorded revision no longer exists in the repository; runs that did not advance skip GC entirely;
- **Init re-bootstrap cleanup**: when `/llmdoc:init` repairs an existing tree, delete investigation reports that are stale by their own metadata (missing revision, reuse conditions no longer met);
- **stop.sh log pruning**: before writing a new log, `find ... -mtime +7 -delete` removes `stop-*.json` files older than 7 days under `.llmdoc-tmp/hooks/`.

`.llmdoc-tmp/` is never tracked by git, so deletion is final with no archive burden. The update report gains a tmp-GC outcome item.

### Breaking: narrative process memory removed (reflection / decision / lessons-learned)

llmdoc no longer stores any narrative process memory. `llmdoc/memory/` converges to a single file, `doc-gaps.md`.

**Rationale.** A stable-doc claim is falsifiable against the current repository; a narrative about a vanished past task (a reflection) is not — an attribution that was wrong when written stays wrong forever, and the old protocol required reading reflections as quality input, so wrong narratives kept contaminating future work. Decision documents share the fate: a decision that still holds is really a current-state fact of the system and belongs in the relevant stable doc's prose ("X is deliberately absent because Y"), not in a standalone decision archive. The **act** of reflection is kept, but its only permitted outputs are verifiable changes.

**New mechanism: three-exit signal triage.** Step 5 of `/llmdoc:update` changes from "write a reflection" to triage. Signal sources include worker `Process Signals` handoffs, doc defects reported by `/llmdoc:review`, failed commands/tests, user corrections, rework, and evidence contradicting doc claims. Every signal takes exactly one exit:

1. **fix now** — a doc defect verifiable against the current repository (wrong claim, missing route, ambiguous contract): fix it in the same run;
2. **doc-gap** — real but not fixable this run: record it in `memory/doc-gaps.md` with a verifiable closure condition;
3. **discard** — anything not attributable to a verifiable doc defect is noise; "keep it for later" is not an option, because later has no referee.

**Removed surfaces:**

- `agents/reflector.md`, `.codex/agents/llmdoc-reflector.toml` (the reflector agent, entirely)
- `skills/llmdoc/references/lessons-learned.md` and the former step 7 "active-memory archive check" of `/llmdoc:update` (the count>5-triggered lessons-learned distillation + archive/ relocation mechanism, entirely)
- `llmdoc/memory/reflections/` and `llmdoc/memory/decisions/` from the skeleton and every contract
- this repository's two dogfood reflections (their promotion candidates had all landed in stable docs such as `context-lifecycle.md`; residual value zero; git history is the archive)

**Changed surfaces:**

- `commands/update.md` / `skills/llmdoc-update/SKILL.md`: step 5 becomes signal triage, the old step 7 is removed and steps renumbered, the report switches from reflection/archive to triage outcomes
- `skills/llmdoc/references/update-and-memory.md`: the Reflection protocol section is replaced by Process-signal triage; Memory ownership converges to the single doc-gaps file, with the "memory holds no permanent residents" invariant
- `skills/llmdoc/references/doc-structure.md`, `templates.md`, `operating-protocol.md`, `design-goals.md`, `codex-cli-hooks.md`, `skills/llmdoc/SKILL.md`: reflection/decision/lessons protocols removed throughout
- `agents/worker.md` / `llmdoc-worker.toml`: the output field `Reflection Handoff` renamed to `Process Signals`, triaged by the caller
- `agents/investigator.md`, `agents/recorder.md` and their TOMLs: reflection-reading requirements removed; recorder's memory ownership converges to doc-gaps.md
- `skills/llmdoc/templates/stop.sh`: the count>5 archive reminder becomes a contamination warning when `memory/` contains anything besides doc-gaps.md
- `skills/llmdoc/templates/session-start.sh`: cold-start guidance no longer asks to read lessons-learned.md / reflections
- `commands/init.md` / `skills/llmdoc-init/SKILL.md`: the skeleton replaces `memory/reflections/` + `memory/decisions/` with `memory/doc-gaps.md`
- `README.md`, `README.zh-CN.md`, `AGENTS.example.md`, `CLAUDE.example.md`, `skills/README.md`: public narratives synced
- this repository's dogfood `llmdoc/` docs fully synced (index, startup, must/, architecture/, guides/, reference/)

### Migration guide for existing projects

1. Give every existing reflection a final triage: delete those whose lessons are already absorbed into stable docs or no longer apply; for still-valid but unlanded ones, translate the conclusion into current-state statements in the relevant stable doc, or record a doc-gap with closure criteria.
2. Decisions under `memory/decisions/`: those that still hold go into the relevant stable doc's prose; those whose premises expired are deleted.
3. Delete `memory/lessons-learned.md` and `memory/archive/` (first handle any still-valid rules per step 1).
4. Afterwards `llmdoc/memory/` should contain only `doc-gaps.md`. No separate backup is needed for any deletion — git history is the archive.

### Version and versioning scheme

- `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`: `2.3.0` → `2.3.0-team.1`.
- This fork uses an **upstream-anchored version scheme** `<upstream-base>-team.<fork-iteration>` instead of an independent major version (briefly named 3.0.0, now abandoned) — an independent number would collide with upstream's future sequence and hide which upstream base the fork tracks.
- Rules: fork-only iterations bump the last number (`2.3.0-team.2`, `.3`, …); after rebasing onto a new upstream release, reset to `<new-base>-team.1` (e.g. upstream 2.4.0 → `2.4.0-team.1`).
- Discriminator: a version **with the `-team` suffix = this fork; a plain upstream version = upstream**. The version checks in the install/migration SOPs rely on this.
- Semver caveat: under strict semver precedence, `2.3.0-team.1` ranks **below** `2.3.0` (pre-release rule). The Claude Code / Codex plugin marketplaces install by source and do not compare versions across sources, so there is no practical impact today; address this before introducing any tooling that compares versions automatically.
