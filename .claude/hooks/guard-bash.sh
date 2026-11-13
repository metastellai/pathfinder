#!/usr/bin/env bash
# PreToolUse (Bash): every change reaches main through a reviewed PR (AGENTS.md), and
# contracts/openapi.json is generated. So:
#   - deny force-pushes and pushes to main
#   - deny commits on main
#   - ask before a shell command writes contracts/openapi.json
# This is a guardrail for honest mistakes, not a security boundary: commands hidden
# inside `sh -c '...'` or eval are not parsed. Branch protection on main is the real control.
set -Eeuo pipefail
# Fail closed: exit 2 blocks the tool call, any other error would let it through.
trap 'echo "guard-bash.sh failed unexpectedly, so the command was blocked. Ask the user to check the hook." >&2; exit 2' ERR
command -v jq >/dev/null 2>&1 || {
  echo "guard-bash.sh needs jq. Ask the user to install it (brew install jq, or apt install jq)." >&2
  exit 2
}

input=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
dir=$(jq -r '.cwd // empty' <<<"$input")
dir=${dir:-$PWD}

decide() { # decide <deny|ask> <reason>
  jq -n --arg d "$1" --arg r "$2" '{hookSpecificOutput: {
    hookEventName: "PreToolUse", permissionDecision: $d, permissionDecisionReason: $r
  }}'
  exit 0
}

if grep -Eq '(>|tee|sed[^;&|]*-i|perl[^;&|]*-i|cp|mv|rm)[^;&|]*contracts/openapi\.json' <<<"$cmd"; then
  decide ask "contracts/openapi.json is generated. Change the API code and run \`just contracts\`. Edit it by hand only if it is broken (AGENTS.md)."
fi

unquote() { local t=${1#[\"\']}; printf '%s' "${t%[\"\']}"; }

check_git() { # check_git <word>...  (the words after "git")
  local repo=$dir sub=""
  while [ $# -gt 0 ]; do
    case $1 in
      -C) repo=$(unquote "${2:-.}"); case $repo in /*) ;; *) repo="$dir/$repo" ;; esac; shift 2 ;;
      -c | --git-dir | --work-tree | --namespace) shift 2 ;;
      -*) shift ;;
      *) sub=$1; shift; break ;;
    esac
  done
  case $sub in
    push)
      local a positional=0
      for a in "$@"; do
        a=$(unquote "$a")
        case $a in
          --force | --force=* | --force-with-lease | --force-with-lease=* | --force-if-includes | --mirror)
            decide deny "Force-pushing is not allowed (AGENTS.md). Push normally, or ask a human if history really has to be rewritten." ;;
          --*) ;;
          -*f*) decide deny "Force-pushing is not allowed (AGENTS.md). Push normally, or ask a human if history really has to be rewritten." ;;
          -*) ;;
          +*) decide deny "A +refspec is a force-push, which is not allowed (AGENTS.md)." ;;
          *)
            positional=$((positional + 1))
            # The first positional argument is the remote; the rest are refspecs.
            if [ $positional -gt 1 ] && [[ $a == main || $a == *:main || $a == *:refs/heads/main ]]; then
              decide deny "Changes reach main only through a reviewed PR (AGENTS.md). Push a feature branch instead."
            fi ;;
        esac
      done ;;
    commit)
      if [ "$(git -C "$repo" branch --show-current 2>/dev/null || true)" = main ]; then
        decide deny "You are on main in $repo. Create a branch first in its own command (git switch -c <name>), then commit there."
      fi ;;
  esac
}

# Split into simple commands on ; & | and newlines. Quoting is not understood, so a
# separator inside a quoted string can split it; that only ever adds checks.
while IFS= read -r segment; do
  read -ra words <<<"$segment" || true
  [ ${#words[@]} -gt 0 ] || continue
  i=0
  # Skip env assignments and wrappers that run their arguments as a command.
  while [ $i -lt ${#words[@]} ] && [[ ${words[$i]} =~ ^[A-Za-z_][A-Za-z0-9_]*= || ${words[$i]} =~ ^(env|command|exec|time|nohup|sudo)$ ]]; do
    i=$((i + 1))
  done
  [ $i -lt ${#words[@]} ] || continue
  case ${words[$i]} in
    cd) # Follow `cd x && git ...` so the branch check looks at the right repo.
      target=$(unquote "${words[$((i + 1))]:-$HOME}")
      case $target in /*) dir=$target ;; "~"*) dir="$HOME${target#\~}" ;; *) dir="$dir/$target" ;; esac ;;
    git) check_git "${words[@]:$((i + 1))}" ;;
  esac
done < <(tr ';&|' '\n\n\n' <<<"$cmd")
exit 0
