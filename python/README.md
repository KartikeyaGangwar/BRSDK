# brsdk-python

> **Status**: Production Release (v2.0.0) — Scientific Python SDK.

Official Python SDK for loading, inspecting, and analysing
[BRSDK](https://github.com/KartikeyaGangwar/BRSDK) telemetry datasets.

---

## Overview

BRSDK records high-frequency (up to 2 000 Hz) deterministic soft-body vehicle telemetry from [BeamNG.drive](https://www.beamng.com) to bridge the **Simulation-to-Real (Sim2Real)** transfer gap. This Python library parses, validates, and structures those recordings for machine learning, offline reinforcement learning, and numerical analysis:

- **`brsdk.load()`** — dataset loading with Pydantic V2 schema and sidecar validation
- **Sim2Real Ready** — Apache Arrow and DLPack zero-copy tensor export for PyTorch and Minari (offline RL)
- **Polars-Native** — vectorized columnar computation without memory copying
- **Typed** — `mypy --strict` compliance with `py.typed` marker
- **Extensible** — reader and exporter protocols supporting custom storage formats

## Requirements

| Dependency | Minimum version | Reason |
|------------|----------------|--------|
| Python     | 3.10           | SPEC 0 three-year window |
| Polars     | 1.0.0          | Compute engine (Arrow-backed) |
| PyArrow    | 16.0.0         | Raw memory layer; DLPack bridge |
| Pydantic   | 2.5.0          | Metadata boundary validation |

## Installation

```bash
# Core only
pip install brsdk

# With ML adapters (PyTorch + Minari offline RL)
pip install "brsdk[ml]"

# With visualisation (Matplotlib + Plotly)
pip install "brsdk[viz]"

# Full installation (all extras)
pip install "brsdk[all]"

# Development installation (includes pytest, ruff, mypy, build)
pip install -e ".[dev]"
```

### Recommended: `uv`

```bash
uv add brsdk
uv add "brsdk[ml]"
```

## Quickstart

```python
import brsdk

# Load a session — automatically discovers the paired session.json sidecar
dataset = brsdk.load("telemetry_20240801_143022.csv")

# Inspect structured metadata (fully typed, Pydantic-validated)
print(dataset.session.vehicle_name)  # "Ibishu Pessima"
print(dataset.session.log_hz)  # 100

# Access the raw Polars DataFrame for arbitrary computation
df = dataset.dataframe
print(df.schema)

# Perform columnar operations with native multithreaded performance
fast_frames = df.filter(df["vel_x"].abs() > 5.0)
print(f"High-velocity frames count: {len(fast_frames)}")
```

## Architecture

The SDK coordinates I/O, schema validation, and columnar data structures:

```
brsdk.load()
    │
    ├─ brsdk.io          — DataReader protocol implementations (CSV, Arrow IPC, …)
    ├─ brsdk.metadata    — Pydantic V2 models for session.json
    ├─ brsdk.core        — Dataset class (thin Polars + metadata bind)
    └─ brsdk.accessors   — .ml.*  and  .viz.*  namespace extensions
```

Polars is the canonical in-memory format per
[RFC-0001](docs/rfcs/rfc-0001-canonical-data-model.md).

## Development

```bash
# Clone and set up the development environment
git clone https://github.com/KartikeyaGangwar/BRSDK.git
cd brsdk/python
# Install in editable mode with development dependencies
uv pip install -e ".[dev]"

# Install pre-commit hooks (run once)
uv run pre-commit install

# Run the full quality gate
uv run ruff check .
uv run ruff format --check .
uv run mypy src
uv run pytest -v
uv run python -m build
```

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a pull request.
All contributions are subject to the [Code of Conduct](CODE_OF_CONDUCT.md).

## Licence

Apache License, Version 2.0 — see [LICENSE](../LICENSE).

## Citation

If you use BRSDK in academic work, please cite:

```bibtex
@software{brsdk2026,
  title   = {{BRSDK}: {BeamNG} Research SDK},
  author  = {Singh, Kartikey and {BRSDK Contributors}},
  year    = {2026},
  url     = {https://github.com/KartikeyaGangwar/BRSDK},
  version = {2.0.0},
}
```
