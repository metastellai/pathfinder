## Spec

<!-- Link the spec in specs/ or the issue. For a trivial fix, say "trivial" and give the reason. -->

## Intent

<!-- One sentence: what this slice does. If you need "and", it may be two PRs. -->

## Quality bar

- [ ] Durable (`packages/`, `contracts/`, `acceptance/`, `mappings/`, `templates/`): `mypy --strict`, unit tests, fixture for every format touched
- [ ] Application (`app/`): type checks, `just accept` green

## Verification

<!-- Paste the real output (the tail is fine). Every command below should have output under it.
     If a command is missing or fails for a reason outside this PR, say so here. -->

```text
$ just lint

$ just test

$ just accept   # only if runtime behaviour changed

```

## In your own words

<!-- Write this yourself, without AI. Two or three sentences each. -->

**The trickiest part of this change, and how it works:**

**An alternative you considered, and why you rejected it:**

## AI use

<!-- Which parts did an AI tool write or suggest? "None" is a fine answer. -->

- [ ] I can explain every line in this diff.

## Checklist

- [ ] Small enough for a reviewer to finish in about 15 minutes (aim for under 400 changed lines, not counting fixtures or generated files)
- [ ] Bug fix: includes a test that fails without the fix
- [ ] Schema change in `contracts/`: version bumped
- [ ] Architecture or convention change: page added in `docs/decisions/`
- [ ] New dependency: license checked against `AGENTS.md` and approved
