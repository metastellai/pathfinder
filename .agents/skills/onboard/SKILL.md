---
name: onboard
description: Guided first-day tour of Pathfinder for a new teammate, ending with a running environment and a first issue. Use when someone is new to the repo, or says "onboard me" or "where do I start".
---

# Onboard

Walk a new teammate through Pathfinder one **stop** at a time. Each stop points them at the source file and ends with a **teach-back**: they explain the idea in one or two sentences of their own. If the teach-back is off, correct it and ask again before moving on. Read the source files with them rather than summarising from memory. Pathfinder is pre-alpha, so if a file doesn't exist yet, say so and use `README.md` instead.

## 1. Meet them

Ask, all in one message:

- their background (Python, TypeScript, robotics or ML, databases)
- which module they're joining, from the table in `README.md`
- who their mentor is

**Done when** you have all three answers.

## 2. Tour

| Stop | Read | Teach-back |
|---|---|---|
| What Pathfinder is | `README.md`, `acceptance/checklist.md` | What does it deliver, and why is the scope fixed? |
| Architecture | `ARCHITECTURE.md` | What is in the durable core, what is in the application, and what does the one host run? |
| Quality bars | "Quality bars" in `AGENTS.md`, `.github/CODEOWNERS` | Which bar applies to their module's code, and who reviews it? |
| How a change ships | `.agents/skills/sdlc/SKILL.md`, `.github/pull_request_template.md` | The path from an issue to a merged PR, naming the `grill-me` and `defend-pr` steps. |
| Their module | The module's rows in the README layout, then its code | Where would a change to their module go? |
| Decisions | `docs/decisions/` | Pick one decision and say why it was made. |

**Done when** every stop has an accepted teach-back.

## 3. Environment

Have them run these themselves, and confirm each one from its output:

1. `just setup`
2. `just db-up`
3. `just dev`, then open the web UI and log in with the seed admin account
4. `just test`

If a command fails, debug it with them. If it is missing because the scaffold isn't built yet, note that and move on.

**Done when** every command has either passed or been noted as missing.

## 4. First issue

1. List starter tasks: `gh issue list --label "good first issue" --state open`.
2. Recommend the one that best fits their background and module, and explain why.
3. If there are none, tell them to ask their mentor to file one with the Good first issue template.

**Done when** they have picked an issue. End by telling them the next steps: read the issue's "Start here" section, then follow the `sdlc` skill.
