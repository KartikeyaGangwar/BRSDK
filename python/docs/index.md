# BRSDK Python SDK

> **Version 2.0.0** · [GitHub](https://github.com/KartikeyaGangwar/BRSDK) · [PyPI](https://pypi.org/project/brsdk)

Official Python interface for loading, inspecting, and analysing telemetry
datasets produced by the **BeamNG Research SDK (BRSDK)**.

---

## What is BRSDK?

BRSDK records high-frequency (up to 2 000 Hz) deterministic soft-body vehicle telemetry from [BeamNG.drive](https://www.beamng.com) to bridge the **Simulation-to-Real (Sim2Real)** gap in autonomous vehicle engineering and reinforcement learning. Each recording consists of:

- A **telemetry CSV** containing timestamped signal columns (continuous velocities,
  wheel speeds, suspension travel and compression velocity, tire slip energy, etc.)
- A **session JSON sidecar** (`*_session.json`) containing validated metadata
  (vehicle model, wheelbase, mass distribution, simulation clock, BRSDK version, etc.)

This Python SDK parses, validates, and structures these recordings for machine learning (PyTorch, Minari offline RL) and numerical analysis.

---

## Installation

```bash
pip install brsdk                  # core only
pip install "brsdk[ml]"            # + PyTorch and Minari (offline RL)
pip install "brsdk[viz]"           # + Matplotlib and Plotly
pip install "brsdk[all]"           # everything
```

---

## Quickstart

```python
import brsdk

dataset = brsdk.load("telemetry_20240801_143022.csv")

# Strongly typed metadata from session.json
print(dataset.session.vehicle_name)  # "Ibishu Pessima"
print(dataset.session.log_hz)         # 100

# Polars DataFrame — native columnar computation
df = dataset.dataframe
print(df.schema)

# Perform columnar operations using Polars expressions
fast_frames = df.filter(df["vel_x"].abs() > 5.0)
print(f"High-velocity frames count: {len(fast_frames)}")
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     brsdk.load()                         │
│                                                          │
│  ┌──────────────┐   ┌──────────────────────────────┐    │
│  │  brsdk.io    │   │  brsdk.metadata              │    │
│  │  DataReader  │   │  Pydantic V2 SessionMetadata │    │
│  │  Protocol    │   │  (strict validation)         │    │
│  └──────┬───────┘   └───────────────┬──────────────┘    │
│         │                           │                    │
│         └──────────┬────────────────┘                    │
│                    ▼                                     │
│          ┌──────────────────┐                            │
│          │  brsdk.core      │                            │
│          │  Dataset         │                            │
│          │  (Polars + meta) │                            │
│          └──────┬───────────┘                            │
│                 │                                        │
│        ┌────────┴────────┐                               │
│        ▼                 ▼                               │
│  brsdk.accessors   brsdk.accessors                       │
│  .ml.*             .viz.*                                │
└─────────────────────────────────────────────────────────┘
```

Dependency direction is strictly one-way:
`metadata` and `io` are independent of each other and of `accessors`.
`accessors` depends on `core` only — never on `io` or `metadata` directly.

---

## Design Decisions

The canonical data model is defined in
[RFC-0001](rfcs/rfc-0001-canonical-data-model.md).

Key decisions:

| Decision | Choice | Reason |
|----------|--------|--------|
| Compute engine | Polars | Arrow-backed; lazy evaluation; no GIL contention |
| Memory format | Apache Arrow | Zero-copy bridge to PyTorch via DLPack |
| Metadata validation | Pydantic V2 | Compiled validation core; strict mode parsing |
| ML export | DLPack | Framework-agnostic zero-copy tensor interchange |
| Offline RL | Minari | Modern standard; successor to D4RL |

---

## Pages

- [API Reference](api/index.md)
- [Tutorials](tutorials/quickstart.md)
- [RFC-0001: Canonical Data Model](rfcs/rfc-0001-canonical-data-model.md)
- [Changelog](changelog.md)
- [Contributing](contributing.md)

---

## Licence

Apache License, Version 2.0 — see
[LICENSE](https://github.com/KartikeyaGangwar/BRSDK/blob/main/LICENSE).

## Citation

```bibtex
@software{brsdk2026,
  title   = {{BRSDK}: {BeamNG} Research SDK},
  author  = {Singh, Kartikey and {BRSDK Contributors}},
  year    = {2026},
  url     = {https://github.com/KartikeyaGangwar/BRSDK},
}
```
