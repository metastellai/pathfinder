---
name: grill-me
description: Relentlessly interview the user about a spec, plan, or decision until every branch is settled. Use when the user says "grill me", before building from a new spec, or before recording a decision.
---

# Grill me

Interview the user relentlessly until you both understand the subject the same way. Map the subject as a **design tree**, where each decision branches into the decisions that depend on it.

## Rounds

The **frontier** is every open decision whose prerequisites are already settled. In each round, ask about the whole frontier at once. Number the questions, give your recommended answer for each, and word each question so that answering "yes" accepts your recommendation:

```
❓ **Q1** - **<title>**: <question, with options if there are any>

➡️ <recommended answer>

---

❓ **Q2** - ...
```

Wait for the answers, then work out the new frontier. If a question depends on another question that is still open, hold it for a later round.

## Facts and decisions

Facts are your job. Look them up yourself in the repo, the docs or your tools, using a subagent if you have one. Keep asking the rest of the frontier while you look. Decisions belong to the user.

## Pathfinder branches

Cover every branch that applies to the subject:

- **Scope**: Which item in `acceptance/checklist.md` does this serve, and is it inside the fixed scope?
- **Quality bar**: Does the code land in durable code or application code? Does it change a schema in `contracts/` or the on-disk data layout?
- **Formats**: Which data types or formats does it touch, and which fixtures prove they work?
- **Dependencies**: Does it add anything new? What license does it carry?
- **One host**: How does it affect PostgreSQL (both metadata and the job queue), local disk use, and how the GPU is shared between pre-labeling and training?
- **Offline install**: Does it still install with no network access?
- **Edge**: Does it need to run on Jetson? Under which JetPack and Python versions?
- **Verification**: Which command proves it is done?

## Done

The frontier is empty: every branch has been visited or explicitly marked out of scope, and nothing is silently assumed.

Write the result into the spec under discussion. If the subject was a decision, write it to `docs/decisions/NNNN-short-title.md` instead. Then ask the user to confirm that you share an understanding. Act on the result only after they confirm.
