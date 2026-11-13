#!/usr/bin/env bash
# PreToolUse (Bash): every change reaches main through a reviewed PR (AGENTS.md), and
# contracts/openapi.json is generated. So:
#   - deny force-pushes and pushes to main
#   - deny commit, merge, cherry-pick, revert, am and rebase while on main
#   - ask before a shell command writes contracts/openapi.json
# This is a guardrail for honest mistakes, not a security boundary: commands hidden
# inside `sh -c '...'`, eval or a script are not parsed. Branch protection on main is
# the real control.
set -Eeuo pipefail
# Fail closed: exit 2 blocks the tool call, any other error would let it through.
trap 'echo "guard-bash.sh failed unexpectedly, so the command was blocked. Ask the user to check the hook." >&2; exit 2' ERR

input=$(cat)
if ! command -v jq >/dev/null 2>&1; then
  # Without jq the command can't be parsed. Block only what this hook guards, so that
  # everything else, including installing jq, still works.
  if [[ $input == *git* || $input == *openapi.json* ]]; then
    echo "guard-bash.sh needs jq to check git and openapi.json commands. Ask the user to install it (brew install jq, or apt install jq)." >&2
    exit 2
  fi
  exit 0
fi

cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
dir=$(jq -r '.cwd // empty' <<<"$input")
dir=${dir:-$PWD}

decide() { # decide <deny|ask> <reason>
  jq -n --arg d "$1" --arg r "$2" '{hookSpecificOutput: {
    hookEventName: "PreToolUse", permissionDecision: $d, permissionDecisionReason: $r
  }}'
  exit 0
}
FORCE="Force-pushing is not allowed (AGENTS.md). Push normally, or ask a human if history really has to be rewritten."
TO_MAIN="Changes reach main only through a reviewed PR (AGENTS.md). Push a feature branch instead."
OPENAPI="contracts/openapi.json is generated. Change the API code and run \`just contracts\`. Edit it by hand only if it is broken (AGENTS.md)."

# Strip quotes and the brackets of ( ... ) and { ...; } groups from a word.
clean() { local t=$1; t=${t#\(}; t=${t#\(}; t=${t%\)}; t=${t%\)}; t=${t#[\"\']}; printf '%s' "${t%[\"\']}"; }
is_openapi() { [[ $1 == contracts/openapi.json || $1 == */contracts/openapi.json ]]; }
branch_of() { git -C "$1" branch --show-current 2>/dev/null || true; }
resolve() { case $1 in /*) printf '%s' "$1" ;; "~"*) printf '%s' "$HOME${1#\~}" ;; *) printf '%s' "$dir/$1" ;; esac; }

# check_openapi <word>...: ask when a simple command would write contracts/openapi.json.
check_openapi() {
  local prog=${1##*/} w prev="" last="" inplace=0 hit=0
  for w in "$@"; do
    case $prev in -o | --out | --output) is_openapi "$w" && decide ask "$OPENAPI" ;; esac
    [[ $w == --out*=* || $w == --output=* ]] && is_openapi "${w#*=}" && decide ask "$OPENAPI"
    [[ $w == -i* || $w == --in-place* ]] && inplace=1
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
  local repo=$dir sub=""
  while [ $# -gt 0 ]; do
    case $1 in
      -C) repo=$(resolve "${2:-.}"); shift 2 ;;
      -c | --git-dir | --work-tree | --namespace) shift 2 ;;
      -*) shift ;;
      *) sub=$1; shift; break ;;
    esac
  done
  case $sub in
    push)
      local a dst refspecs=0
      for a in "$@"; do
        case $a in
          --force | --force=* | --force-with-lease | --force-with-lease=* | --force-if-includes) decide deny "$FORCE" ;;
          --all | --mirror | --branches) decide deny "$a pushes every branch, including main. $TO_MAIN" ;;
          --*) ;;
          -*f*) decide deny "$FORCE" ;;
          -*) ;;
          +*) decide deny "A +refspec is a force-push, which is not allowed (AGENTS.md)." ;;
          *)
            refspecs=$((refspecs + 1))
            [ $refspecs -gt 1 ] || continue # the first positional argument is the remote
            dst=${a##*:}
            case $dst in
              main | refs/heads/main) decide deny "$TO_MAIN" ;;
              HEAD | @) [ "$(branch_of "$repo")" = main ] && decide deny "$TO_MAIN" ;;
            esac ;;
        esac
      done
      # No refspec pushes the current branch.
      if [ $refspecs -le 1 ] && [ "$(branch_of "$repo")" = main ]; then decide deny "You are on main. $TO_MAIN"; fi ;;
    commit | merge | cherry-pick | revert | am | rebase)
      case " $* " in *" --abort "* | *" --quit "* | *" --skip "*) return 0 ;; esac
      if [ "$(branch_of "$repo")" = main ]; then
        decide deny "git $sub would change main in $repo. Create a branch first in its own command (git switch -c <name>), then work there."
      fi ;;
  esac
  return 0
}

# Split into simple commands on ; & | and newlines. Quoting is not understood, so a
# separator inside a quoted string can split it; that only ever adds checks.
while IFS= read -r segment; do
  read -ra raw <<<"$segment" || true
  words=()
  for w in ${raw[@]+"${raw[@]}"}; do
    w=$(clean "$w")
    [ -n "$w" ] && words+=("$w")
  done
  [ ${#words[@]} -gt 0 ] || continue
  # Redirections are where most hand edits happen: > file, >> file, >file.
  if grep -Eq '>[[:space:]]*["'\'']?([^[:space:]]*/)?contracts/openapi\.json' <<<"$segment"; then decide ask "$OPENAPI"; fi
  i=0
  # Skip env assignments, shell keywords and wrappers that run their arguments.
  while [ $i -lt ${#words[@]} ] && [[ ${words[$i]} =~ ^[A-Za-z_][A-Za-z0-9_]*= || ${words[$i]} =~ ^(env|command|exec|time|nohup|sudo|xargs|\{|\}|!|if|then|else|elif|do|while|until)$ ]]; do
    i=$((i + 1))
  done
  [ $i -lt ${#words[@]} ] || continue
  rest=("${words[@]:$i}")
  check_openapi "${rest[@]}"
  case ${rest[0]##*/} in
    cd) dir=$(resolve "${rest[1]:-$HOME}") ;; # follow `cd x && git ...` to the right repo
    git) if [ ${#rest[@]} -gt 1 ]; then check_git "${rest[@]:1}"; fi ;;
  esac
done < <(tr ';&|' '\n\n\n' <<<"$cmd")
exit 0
