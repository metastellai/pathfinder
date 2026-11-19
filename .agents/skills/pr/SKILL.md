---
name: pr
description: Write the PR description from the Pathfinder template with real verification output, then open the PR. Use when a branch is ready for review, or the user says "open a PR" or "write the PR description".
---

# PR

Fill in `.github/pull_request_template.md` with facts you checked yourself, then open the PR once the author confirms.

## 1. Check prerequisites

- You are on a feature branch, not `main`.
- The working tree is clean.
- `defend-pr` gave a **ready** verdict on this diff. If you didn't see that happen in this session, ask the author. If it hasn't happened, run `defend-pr` first.

**Done when** all three hold.

## 2. Gather the facts

- the diff and its size: `git diff main...HEAD` and `git diff --shortstat main...HEAD`. Leave fixtures and generated files out of the size.
- the commits: `git log --oneline main..HEAD`
- the linked spec in `specs/` and the issue it came from

## 3. Run the verification

1. Run `just lint` and `just test`.
2. If runtime behaviour changed, also run `just accept` against `just dev`.
3. Keep the tail of each command's real output.

If a command is missing or fails, record exactly that. Fix a failure or report it before you go further.

**Done when** every relevant command has either passed or been recorded as missing, and you captured its output.

## 4. Write the description

Fill in each section of the template:

- **Spec**: the spec and issue links.
- **Intent**: one sentence. If it needs "and", tell the author the PR may be two slices.
- **Quality bar**: tick the box for each side the diff touches, based on the paths changed.
- **Verification**: paste the output you captured in step 3.
- **In your own words**: leave both prompts empty for the author to write.
- **AI use**: list what AI wrote or suggested. You know what you wrote in this session; ask the author about the rest.
- **Checklist**: tick only the items you confirmed from the diff.

Write the description to a file outside the working tree, for example `$(git rev-parse --git-dir)/PR_BODY.md`.

For the title, use the commit prefix (`feat:`, `fix:`, `docs:`, `chore:`) followed by the intent, in under 70 characters.

## 5. Open the PR

1. Show the author the title and description.
2. Ask them to write the "In your own words" section, and paste it in exactly as they wrote it.
3. Once they confirm, push the branch and run `gh pr create --title "<title>" --body-file <file>`.
4. If "In your own words" is still empty, add `--draft`.

**Done when** the PR is open and you have given the author its URL.
