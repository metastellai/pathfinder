# 0001: Development process and agent guardrails

## Status
Proposed

## Context
Pathfinder is pre-alpha and is built by a small team, most of them new graduates, who write much of their code with AI agents. The template's rules (spec first, small changes, verify with evidence, independent review) were generic. They did not say where the quality bar changes, who reviews what, or how to check that a human understands code an agent wrote.

## Decision
- `AGENTS.md` is the single source of rules for every agent. `CLAUDE.md` imports it, and `.claude/skills` is a symlink to `.agents/skills`.
- Every non-trivial change follows the `sdlc` skill: spec, plan, slice, verify, review. Specs go in `specs/`, and decisions go in `docs/decisions/`.
- There are two quality bars. Durable code (`packages/`, `contracts/`, `acceptance/`, `mappings/`, `templates/`) needs `mypy --strict`, unit tests and fixtures. Application code (`app/`) needs type checks and a green `just accept`.
- Before a PR opens, the author passes `defend-pr`, a quiz on their own diff. They also write the "In your own words" section of the PR template without AI.
- `CODEOWNERS` routes review by risk. Maintainers, including new grads, review application code. `pathfinder-core` reviews durable code, specs and decisions. `pathfinder-leads` reviews process, CI, deployment, scope and dependency manifests.
- Claude Code hooks catch honest mistakes: force-pushes, pushes and commits to `main`, and hand edits to generated files. They also format Python. Branch protection on `main` is the real control, and the hooks don't replace it.

## Consequences
- Each PR costs the author more effort: a quiz and their own write-up. In return, reviewers see code the author can explain.
- Senior reviewers are a bottleneck for durable code and for dependency changes. That is intended, because those are the hardest changes to undo.
- The hooks need `jq`, and they block tool calls when it is missing.
- Until the scaffold exists, the verification stage can only report `just` commands as missing.
- The PR that introduced this process didn't follow it, because the process didn't exist yet. It had no spec and covered several intents in one PR.
