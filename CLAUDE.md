# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@AGENTS.md

## Claude Code notes

`AGENTS.md` is the single source of rules for every agent. Keep this file for Claude-specific notes only.

- `.claude/skills` is a symlink to `.agents/skills`, so the repo skills (`sdlc`, `grill-me`) load as Claude Code skills. Add new skills under `.agents/skills/<name>/SKILL.md`, not in `.claude/`.
