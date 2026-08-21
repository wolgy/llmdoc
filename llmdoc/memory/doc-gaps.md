# Documentation Gaps

## Open Gaps
- There is still no executable test or fixture that validates `/llmdoc:init` fan-out behavior against the documented contract; current confidence comes from prompt and config review.
- If runtime behavior diverges again, add a guide or fixture that checks command docs, README summaries, and `.codex/config.toml` together.
- There is no executable test or fixture exercising the commit-watermark resolution ladder and its degraded modes (non-git, shallow, first-run, orphaned/rebased watermark, HEAD-behind, doc-only loop-breaker). Confidence comes from the `commands/update.md` contract and `skills/llmdoc-update/SKILL.md` mirroring it by review only. Closure: add a fixture or checklist that drives each ladder branch against a scratch repo and asserts the resulting watermark advance (or refusal).
