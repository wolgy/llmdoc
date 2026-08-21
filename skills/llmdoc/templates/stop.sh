#!/usr/bin/env bash
set -eu

project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"

if command -v git >/dev/null 2>&1; then
  git_root="$(git -C "$project_dir" rev-parse --show-toplevel 2>/dev/null || true)"
  if [ -n "$git_root" ]; then
    project_dir="$git_root"
  fi
fi

tmp_dir="$project_dir/.llmdoc-tmp/hooks"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"

mkdir -p "$tmp_dir"
find "$tmp_dir" -name 'stop-*.json' -mtime +7 -delete 2>/dev/null || true
cat > "$tmp_dir/stop-$timestamp.json"

unexpected_memory_count=0
if [ -d "$project_dir/llmdoc/memory" ]; then
  unexpected_memory_count="$(
    find "$project_dir/llmdoc/memory" -type f \
      ! -name "doc-gaps.md" \
      | wc -l \
      | tr -d '[:space:]'
  )"
fi

if [ "$unexpected_memory_count" -gt 0 ]; then
  cat <<EOF
{
  "systemMessage": "Best-effort reminder: llmdoc/memory/ contains ${unexpected_memory_count} file(s) besides doc-gaps.md. llmdoc stores no narrative process memory; triage each into a stable-doc fix or a doc-gaps.md entry, then delete it (git history is the archive)."
}
EOF
else
  cat <<'EOF'
{
  "systemMessage": "If this turn produced durable knowledge or surfaced doc defects, consider asking whether to run /llmdoc:update."
}
EOF
fi
