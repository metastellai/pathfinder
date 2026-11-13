#!/usr/bin/env bash
# PreToolUse (Bash): a cheap guardrail for honest mistakes, not a security boundary.
# Every change reaches main through a reviewed PR, and contracts/openapi.json is
# generated (AGENTS.md). So this hook:
#   - denies force-pushes, and pushes that name main
#   - denies commit, merge, cherry-pick, revert, am, rebase, reset, pull and push
#     while the session's own directory is on main
#   - asks before a shell command writes contracts/openapi.json
# It reads command text, so it can't see what a command does at runtime: a chain that
# switches to main first, `cd` or `git -C` into another repo, `sh -c`, eval and scripts
# all get past it. Branch protection on main is the real control, and git's own
# pre-commit and pre-push hooks will cover the rest once the pre-commit setup lands.
set -Eeuo pipefail
# Fail closed: exit 2 blocks the tool call, any other error would let it through.
trap 'echo "guard-bash.sh failed unexpectedly, so the command was blocked. Ask the user to check the hook." >&2; exit 2' ERR

input=$(cat)
if command -v jq >/dev/null 2>&1; then
  cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
  dir=$(jq -r '.cwd // empty' <<<"$input")
else
  # No jq: pull out the command string itself, so nothing else in the input (such as a
  # path that contains "git") can trigger a check.
  re='"command"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)"'
  if [[ $input =~ $re ]]; then cmd=${BASH_REMATCH[1]}; else cmd=""; fi
  cmd=${cmd//\\n/$'\n'}
  cmd=${cmd//\\\"/\"}
  dir=""
fi
dir=${dir:-$PWD}

decide() { # decide <deny|ask> <reason>; reasons contain no quotes or backslashes
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' "$1" "$2"
  exit 0
}
FORCE="Force-pushing is not allowed (AGENTS.md). Push normally, or ask a human if history really has to be rewritten."
TO_MAIN="Changes reach main only through a reviewed PR (AGENTS.md). Push a feature branch instead."
OPENAPI="contracts/openapi.json is generated. Change the API code and run \`just contracts\`. Edit it by hand only if it is broken (AGENTS.md)."

on_main=0
[ "$(git -C "$dir" branch --show-current 2>/dev/null || true)" = main ] && on_main=1

# Strip quotes and the brackets of ( ... ) and { ...; } groups from a word.
clean() { local t=$1; t=${t#\(}; t=${t#\(}; t=${t%\)}; t=${t%\)}; t=${t#[\"\']}; printf '%s' "${t%[\"\']}"; }
is_openapi() { [[ $1 == contracts/openapi.json || $1 == */contracts/openapi.json ]]; }

check_openapi() { # check_openapi <word>...: ask if this simple command writes the file
  local prog=${1##*/} w prev="" last="" inplace=0 hit=0
  for w in "$@"; do
    case $prev in -o | --out | --output) is_openapi "$w" && decide ask "$OPENAPI" ;; esac
    [[ $w == --out*=* ]] && is_openapi "${w#*=}" && decide ask "$OPENAPI"
    # -i, -i.bak, -pi, -ni, --in-place
    [[ $w =~ ^-[A-Za-z]*i || $w == --in-place* ]] && inplace=1
    is_openapi "$w" && hit=1
    prev=$w; last=$w
  done
  [ $hit -eq 1 ] || return 0
  case $prog in
    rm | tee | truncate | dd) decide ask "$OPENAPI" ;;
    cp | mv | install | ln) is_openapi "$last" && decide ask "$OPENAPI" ;;
    sed | perl) [ $inplace -eq 1 ] && decide ask "$OPENAPI" ;;
    git) case " ${*:2} " in *" checkout "* | *" restore "* | *" mv "* | *" rm "*) decide ask "$OPENAPI" ;; esac ;;
  esac
  return 0
}

check_git() { # check_git <word>...  (the words after "git")
  local sub="" a
  while [ $# -gt 0 ]; do
    case $1 in
      -C | -c | --git-dir | --work-tree | --namespace) shift 2 ;;
      -*) shift ;;
      *) sub=$1; shift; break ;;
    esac
  done
  case $sub in
    push)
      for a in "$@"; do
        case $a in
          --force | --force=* | --force-with-lease | --force-with-lease=* | --force-if-includes) decide deny "$FORCE" ;;
          --all | --mirror | --branches) decide deny "$a pushes every branch, including main. $TO_MAIN" ;;
          --*) ;;
          -*f*) decide deny "$FORCE" ;;
          +*) decide deny "A +refspec is a force-push, which is not allowed (AGENTS.md)." ;;
          main | *:main | refs/heads/main | *:refs/heads/main) decide deny "$TO_MAIN" ;;
        esac
      done
      [ $on_main -eq 0 ] || decide deny "You are on main. Create a branch first in its own command (git switch -c <name>), then push that." ;;
    commit | merge | cherry-pick | revert | am | rebase | reset | pull)
      case " $* " in *" --abort "* | *" --quit "* | *" --skip "*) return 0 ;; esac
      [ $on_main -eq 0 ] || decide deny "git $sub would change main. Create a branch first in its own command (git switch -c <name>), then work there." ;;
  esac
  return 0
}

# Split into simple commands on ; & | and newlines. `>|` is a redirection, so turn it
# into `>` first. Quoting is not understood, so a separator inside a quoted string can
# split it; that only ever adds checks.
while IFS= read -r segment; do
  if grep -Eq '>[[:space:]]*["'\'']?([^[:space:]]*/)?contracts/openapi\.json["'\'']?([[:space:]]|$)' <<<"$segment"; then
    decide ask "$OPENAPI"
  fi
  read -ra raw <<<"$segment" || true
  words=()
  for w in ${raw[@]+"${raw[@]}"}; do
    w=$(clean "$w")
    [ -n "$w" ] && words+=("$w")
  done
  i=0
  # Skip env assignments, shell keywords and wrappers that run their arguments.
  while [ $i -lt ${#words[@]} ] && [[ ${words[$i]} =~ ^[A-Za-z_][A-Za-z0-9_]*= || ${words[$i]} =~ ^(env|command|exec|time|nohup|sudo|xargs|\{|\}|!|if|then|else|elif|do|while|until)$ ]]; do
    i=$((i + 1))
  done
  [ $i -lt ${#words[@]} ] || continue
  rest=("${words[@]:$i}")
  check_openapi "${rest[@]}"
  if [ "${rest[0]##*/}" = git ] && [ ${#rest[@]} -gt 1 ]; then check_git "${rest[@]:1}"; fi
done < <(sed 's/>|/>/g' <<<"$cmd" | tr ';&|' '\n\n\n')
exit 0
