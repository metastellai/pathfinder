#!/usr/bin/env bash
# PostToolUse (Write|Edit|MultiEdit): format Python files with ruff as soon as they are
# written, so formatting never shows up as noise in review. Never touches the network.
set -euo pipefail
command -v jq >/dev/null 2>&1 || exit 0

file=$(jq -r '.tool_response.filePath // .tool_input.file_path // empty')
case "$file" in
  *.py | *.pyi) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
# Prefer the project's pinned ruff from `just setup`; fall back to one on PATH; skip if
# neither exists. Calling .venv directly avoids `uv run`, which would sync dependencies.
if [ -x "$root/.venv/bin/ruff" ]; then
  "$root/.venv/bin/ruff" format --quiet "$file"
elif command -v ruff >/dev/null 2>&1; then
  ruff format --quiet "$file"
fi
