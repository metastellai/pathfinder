# 0001: Development process and agent guardrails

## Status
Proposed

## Context
Pathfinder is pre-alpha and is built by a small team, most of them new graduates, who write much of their code with AI agents. The template's rules (spec first, small changes, verify with evidence, independent review) were generic. They did not say where the quality bar changes, who reviews what, or how to check that a human understands code an agent wrote.

## Decision
- `AGENTS.md` is the single source of rules for every agent. `CLAUDE.md` imports it, and `.claude/skills` is a symlink to `.agents/skills`.
- Every non-trivial change follows the `sdlc` skill: spec, plan, slice, verify, review. Specs go in `specs/`, and decisions go in `docs/decisions/`.
- There are two quality bars. Durable code (`packages/`, `contracts/`, `acceptance/`, `mappings/`, `templates/`) needs `mypy --strict`, unit tests and fixtures. Application code (`app/`) needs type checks and a green `just accept`.
- Before a PR opens, and again after any review fix changes the diff, the author passes `defend-pr`, a quiz on their own diff. They also write the "In your own words" section of the PR template without AI.
- `CODEOWNERS` routes review by risk, using the existing org teams. `contributor`, which includes the new grads, reviews application code. `reviewer` reviews durable code, specs and decisions. Process, CI, deployment, scope, dependency manifests and quality-gate config need `leader` or `reviewer`, so the one leader is never a bottleneck.
- Three layers protect `main`, from strongest to weakest:
  1. **Branch protection on GitHub** is the real control.
  2. **Git's `pre-commit` and `pre-push` hooks** will check the real branch and refspecs for every tool. They come with the pre-commit setup, which isn't built yet.
  3. **Claude Code hooks** catch honest mistakes cheaply by reading command text. They deny force-pushes and pushes that name `main`. When the session's directory is on `main`, they also deny commits, merges, cherry-picks, reverts, `am`, rebases, resets, pulls and pushes. And they ask before any hand edit to `contracts/openapi.json`, the only generated file so far.

  The Claude Code hooks stay small on purpose: parsing shell text can never see everything a command does at runtime. They miss chains that switch to `main` first, `cd` or `git -C` into another repo, and commands inside `sh -c`, `eval` or scripts. Guard each new generated file in `.claude/hooks/` when it is added.
- Python formatting runs in the pre-commit step rather than after every agent edit, so files don't change under the agent between edits.

## Consequences
- Each PR costs the author more effort: a quiz and their own write-up. In return, reviewers see code the author can explain.
- Senior reviewers are a bottleneck for durable code and for dependency changes. That is intended, because those are the hardest changes to undo.
- The hooks work without `jq`, but parse the input more loosely.
- Until the scaffold exists, the verification stage can only report `just` commands as missing.
- The PR that introduced this process didn't follow it, because the process didn't exist yet. It had no spec and covered several intents in one PR.
