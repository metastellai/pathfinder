#!/usr/bin/env bash
# PreToolUse (Bash): every change reaches main through a reviewed PR (AGENTS.md),
# so block force-pushes and commits made directly on main.
set -euo pipefail

input=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $r
  }}'
  exit 0
}

if grep -Eq '(^|[;&|[:space:]])git[[:space:]]+([^;&|]*[[:space:]])?push([[:space:]][^;&|]*)?[[:space:]](--force|--force-with-lease|-f)([[:space:]=]|$)' <<<"$cmd" \
  || grep -Eq '(^|[;&|[:space:]])git[[:space:]]+([^;&|]*[[:space:]])?push([[:space:]][^;&|]*)?[[:space:]]\+[^[:space:]]' <<<"$cmd"; then
  deny "Force-pushing is not allowed (AGENTS.md). Push normally, or ask a human if history really has to be rewritten."
fi

if grep -Eq '(^|[;&|[:space:]])git[[:space:]]+([^;&|]*[[:space:]])?commit([[:space:]]|$)' <<<"$cmd"; then
  branch=$(git -C "${cwd:-.}" branch --show-current 2>/dev/null || true)
  if [ "$branch" = "main" ]; then
    deny "You are on main. Create a branch first in its own command (git switch -c <name>), then commit there."
  fi
fi
