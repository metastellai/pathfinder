#!/usr/bin/env bash
# PostToolUse (Write|Edit): format Python files with ruff as soon as they are written,
# so formatting never shows up as noise in review.
set -euo pipefail

file=$(jq -r '.tool_response.filePath // .tool_input.file_path // empty')
case "$file" in
  *.py | *.pyi) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
# Prefer the project's pinned ruff; fall back to one on PATH; skip if neither exists yet.
if [ -f "$root/pyproject.toml" ]; then
  uv run --quiet --project "$root" ruff format --quiet "$file"
elif command -v ruff >/dev/null 2>&1; then
  ruff format --quiet "$file"
fi
