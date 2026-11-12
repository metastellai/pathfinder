# AGENTS.md

Pathfinder is a single-host data platform for robot and multimodal data. It covers ingest, quality checks, labeling, versioning, training and deployment to Jetson edge devices. `README.md` defines the scope, which is fixed, and `acceptance/checklist.md` defines what "done" means.

**Status: pre-alpha.** The scaffold (`justfile`, `packages/`, `app/` and the rest) doesn't exist yet. If you run a command that is missing, report it as missing.

## Commands

The `justfile` is the command contract. Use these targets rather than calling the underlying tools directly.

```bash
just setup      # dependencies + pre-commit hooks
just db-up      # databases, migrations, seed data
just dev        # server, worker, web UI, Label Studio
just lint       # ruff, mypy, eslint, tsc
just test       # unit tests (packages/) + type checks
just accept     # acceptance suite against the running system
just fixtures   # sample files for every supported format
just contracts  # regenerate the openapi.json snapshot
```

If a command and the README disagree, fix one of them in the same PR.

## Quality bars

Where the code lives decides the bar it must meet.

- **Durable code** (`packages/`, `contracts/`, `acceptance/`, `mappings/`) is built to outlast the application. It needs `mypy --strict`, unit tests, and a fixture for every format it handles. Any schema change needs a version bump.
- **Application code** (`app/`) needs type checks and must keep `just accept` green. Write the simplest code that passes, and build only what a spec asks for.

## Process

Use the `sdlc` skill for any change beyond a trivial fix. It runs spec → plan → slice → verify → review.

- Specs go in `specs/` (see `specs/README.md` for the format).
- Architecture and convention decisions go in `docs/decisions/`, one page each, added in the same PR as the change.
- To stress-test a spec, plan or decision, use the `grill-me` skill.

Skills live in `.agents/skills/<name>/SKILL.md`.

## Boundaries

**Ask first**

- **New dependencies.**
  - Allowed without sign-off: permissive licenses (MIT, BSD, Apache-2.0, PostgreSQL).
  - Needs sign-off: any copyleft license, including LGPL.
  - Never added: AGPL or non-commercial dependencies, such as Ultralytics YOLO, MinIO or Garage.
- **Changes to** `contracts/` schemas, the on-disk data layout, `mappings/`, or Label Studio templates.
- **Changes to** CI, `deploy/`, secrets, or the offline installer.
- **Anything that would modify Label Studio itself.** It ships unmodified, so integrate with it through its API and templates.

**Hard rules**

- Regenerate `contracts/openapi.json` with `just contracts`. Only edit it by hand if it's broken.
- Keep secrets out of commits.
- A human merges every PR, and only after explicit approval. Never force-push.
- Report file paths, API behaviour and test results only from what you actually observed.

## Code style

- Follow the existing patterns.
- Write comments that explain *why*.
- Everything must install offline. Fetch data at runtime only when the user configures a source.
