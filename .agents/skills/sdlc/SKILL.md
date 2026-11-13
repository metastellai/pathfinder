---
name: sdlc
description: Pathfinder's change lifecycle, from spec to plan to slice to verify to review. Use when starting a non-trivial change, picking up a spec or issue, or preparing a PR.
---

# SDLC

Every change goes through five stages in order. A trivial fix (a typo, or a one-line bug fix with its test) starts at stage 3.

## 1. Spec

Write `specs/NNNN-short-title.md`, using the next free number and the sections listed in `specs/README.md`. Then run the `grill-me` skill on it.

**Done when** the user confirms you share an understanding of the change, and every question is either answered in the spec or listed under `## Open questions` with an owner.

## 2. Plan

Add a `## Plan` section to the spec that breaks the work into **slices**. A slice is:

- one intent
- one PR that a human can review in under 15 minutes
- one verification command

Order the slices so that `main` stays green after each one merges.

**Done when** every acceptance criterion in the spec maps to at least one slice.

## 3. Implement one slice

- Hold the code to the **quality bar** in `AGENTS.md` for the side it lands on, durable or application.
- For a bug fix, write a test that fails before the fix and passes after it.
- If the slice changes architecture or a convention, add `docs/decisions/NNNN-short-title.md` in the same PR.

**Done when** the slice's intent is met and nothing outside that intent changed.

## 4. Verify

- Run `just lint` and `just test`.
- If the slice changes runtime behaviour, also run `just accept` against `just dev`.
- Copy the real command output into the PR description.

If a command doesn't exist yet, or fails for a reason outside the slice, report exactly that. It counts as a result, not a pass.

**Done when** every relevant command has either passed or been reported as missing, and its output is in the PR.

## 5. Review and merge

1. Run the `defend-pr` skill with the human author. Continue only after a **ready** verdict.
2. Open the PR with the `pr` skill.
3. A separate agent or session that did not write the code does an AI review. Fix or answer every finding. If a fix changes the diff, run `defend-pr` again on the changed hunks before the human review.
4. A human reviews the PR, and a human merges it.

**Done when** a human has approved and merged the PR. Then return to stage 3 for the next slice.
