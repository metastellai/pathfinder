# Pathfinder

**A data platform for robot and multimodal data: ingest, check, label, version, train, and deploy to the edge.**

> Status: pre-alpha. The scaffold is being built now. The commands below are the contract the scaffold must meet. If a command here doesn't work, fix the code or this file in the same PR.

---

## Why "Pathfinder"

NASA's Mars Pathfinder was a compact, low-cost mission that proved the route for everything after it. This project works the same way. It has a small application on top of a durable core, the core has to outlast the application, and it gets the job done end to end.

---

## What it does

| # | Module | Delivered |
|---|---|---|
| ▲1 | Collection and ingest | Upload text, images, video, audio and documents. Import MCAP, ROS1 bag, ROS2 db3, HDF5 and LeRobot through field mappings. Get metadata and previews |
| 2 | Quality checks and tasks | Rule-based checks, anomaly flags, task assignment, batch and parallel jobs |
| 3 | Storage and management | Unified storage, search, dataset building, immutable versions |
| ▲4 | Labeling and review | 7+ data types, fine and batch labeling, SAM 2 pre-labeling, review with rework |
| 5 | Label templates | 50+ templates by industry and scenario, extendable |
| 6 | Import, export, conversion | 11+ formats, including JSON, COCO, YOLO, LeRobot, HDF5 and MCAP |
| ▲7 | Training and edge inference | Fine-tuning jobs on dataset versions, with deployment to Jetson edge devices |

The scope is fixed. The acceptance checklist is [`acceptance/checklist.md`](acceptance/checklist.md).

---

## Architecture at a glance

- **Durable core**: the on-disk data layout, the `muliu-formats` library, the schemas in `contracts/`, and the acceptance suite. These are built to outlast the application and are held to a strict quality bar.
- **Application**: a FastAPI server and worker, a React web UI, Label Studio (unmodified), training runners, and an Edge Agent. These are kept small and simple.
- **One host**: PostgreSQL handles both metadata and the job queue, and files live on local disk. Everything installs offline.

Full details are in [ARCHITECTURE.md](ARCHITECTURE.md).

---

## Quick start

### Prerequisites

- Ubuntu 22.04 or 24.04. macOS works for the API and the web UI, but not for GPU jobs.
- Python 3.11+ with [uv](https://github.com/astral-sh/uv)
- Node.js 20+
- PostgreSQL 16
- [just](https://github.com/casey/just)
- An NVIDIA GPU, for pre-labeling and training only

### First run

```bash
just setup       # install dependencies and pre-commit hooks
just db-up       # create databases, run migrations, load seed data
just dev         # start the server, worker, web UI and Label Studio
```

Open http://127.0.0.1 and log in with the seed admin account that `just db-up` prints.

### Everyday commands

```bash
just test        # unit tests (packages/) + type checks
just accept      # acceptance suite against the running system
just lint        # ruff, mypy, eslint, tsc
just fixtures    # download sample files for every supported format
just contracts   # regenerate the openapi.json snapshot
just package     # build the offline installer
```

---

## Repository layout

```
pathfinder/
├── README.md
├── ARCHITECTURE.md
├── AGENTS.md                 # rules for AI coding tools
├── justfile
├── packages/
│   └── muliu-formats/        # DURABLE: readers, converters, mappings, QC rules
├── contracts/                # DURABLE: JSON Schemas + OpenAPI snapshot
├── acceptance/               # DURABLE: executable scope checklist + fixtures
├── templates/                # DURABLE: Label Studio XML templates
├── mappings/                 # DURABLE: field mappings per data source
├── app/
│   ├── server/               # FastAPI: api, domain, storage, labeling, training, edge
│   ├── web/                  # React + Ant Design
│   └── edge-agent/           # daemon for Jetson devices
├── deploy/                   # systemd units, nginx config, installer, backup
└── docs/
    └── decisions/            # one page per architecture decision
```

---

## How we work

**Two quality bars**
- **Durable code** (`packages/`, `contracts/`, `acceptance/`, `mappings/`, `templates/`) needs `mypy --strict`, unit tests, and a fixture for every format. Changing a schema needs a version bump.
- **Application code** (`app/`) needs type checks and must keep the acceptance suite green. Keep it simple. No abstractions "for later".

**Every PR**
- Small, and merged within a day or two.
- Passes `just lint` and `just test` locally before you push.
- Comes with a test if it fixes a bug.
- You can explain every line in it. AI tools are welcome, but if you can't explain the code, it doesn't merge.
- Gets an AI review first, then a human review.

**Every Friday**
- `just package`, then a clean install on the integration host, then `just accept`.

---

## Third-party components

Muliu's code is proprietary. Third-party components keep their own licenses, and the installer includes a `NOTICE` file for all of them.

| Component | License |
|---|---|
| Label Studio Community | Apache-2.0 (used unmodified) |
| PostgreSQL | PostgreSQL License |
| FastAPI, React, Ant Design | MIT |
| SAM 2, LeRobot, rosbags, YOLOX | Apache-2.0 |
| mcap, ONNX Runtime | MIT |
| h5py | BSD-3-Clause |
| openpi | Apache-2.0 for the code. **pi0.5 weights fall under the Gemma Terms of Use**, so ship the Gemma notice with them |
| TensorRT, JetPack | NVIDIA license |

**Do not add** AGPL or non-commercial dependencies, for example Ultralytics YOLO, MinIO, or Garage. Any new copyleft dependency needs sign-off before it merges.

---

## Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md): design, data layout, contracts, deployment
- [acceptance/checklist.md](acceptance/checklist.md): what "done" means, item by item
- [docs/decisions/](docs/decisions/): why things are the way they are
