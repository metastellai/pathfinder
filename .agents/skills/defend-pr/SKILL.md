---
name: defend-pr
description: Quiz the human author on their own diff before a PR opens, and give a ready or not-ready verdict. Use before opening a PR, or when the user says "defend my PR" or "quiz me on my diff".
---

# Defend PR

The author has to **defend** the diff: explain why it is right, in their own words, before a reviewer sees it. You are the examiner. Leave the code as it is while the quiz runs.

## 1. Read the diff

1. Collect the change: `git diff main...HEAD`, plus `git diff HEAD` for anything not yet committed.
2. Read every changed file in full, and the spec it links to in `specs/`.
3. If the diff is over about 400 changed lines, not counting fixtures or generated files, stop. Give a **not ready** verdict and suggest how to split it.

**Done when** you could explain the purpose of every changed hunk yourself.

## 2. Pick the questions

Ask about the hunks where a misunderstanding would cost the most: logic, error handling, concurrency, schemas, and anything that touches durable code. Use about one question per 50 changed lines, with at least 3 and at most 8. Each question points at a `file:line` and is one of these kinds:

- **Why**: why this approach, and what the alternative was.
- **What if**: what happens on a given edge input or failure, such as an empty file, a duplicate job, a dropped connection, or a malformed MCAP.
- **Trace**: walk through what runs when a specific thing happens.
- **Test**: which test fails if this line is removed. If no test would fail, ask why not.
- **Bar**: which quality bar applies, and whether the change needs a schema version bump or a page in `docs/decisions/`.

**Done when** every file containing logic has at least one question.

## 3. Quiz

Ask one question at a time. Ask the author to answer from memory and the code, without AI help.

- Wait for each answer. Give no hints before they answer.
- Grade each answer:
  - **solid**: correct and specific to this code.
  - **shaky**: vague, partly right, or generic. Ask one follow-up question, then grade again.
  - **missing**: wrong, or "I don't know".

**Done when** every question has a final grade.

## 4. Verdict and teaching

Give the verdict first:

- **Ready**: every answer is solid.
- **Not ready**: list each shaky or missing answer, with its `file:line`.

Then go through each answer that wasn't solid. Explain the correct answer and point to the code or test that shows it. For each gap, recommend one next step:

- **Study**: the code is right but the author didn't understand it. They re-read the code and re-run `defend-pr`.
- **Simplify**: the code is harder to follow than it needs to be, often because AI wrote it. They rewrite it until it can be explained.
- **Ask**: the question depends on context they don't have yet. They take it to their mentor or the code owner.

The PR opens only after a **ready** verdict.
