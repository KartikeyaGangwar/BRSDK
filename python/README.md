# brsdk-python

> **Status**: Pre-Alpha (v0.1.0) — API is unstable and subject to change without notice.

Official Python SDK for loading, inspecting, and analysing
[BRSDK](https://github.com/KartikeyaGangwar/BRSDK) telemetry datasets.

---

## Overview

BRSDK records zero-allocation, deterministic vehicle telemetry from
[BeamNG.drive](https://www.beamng.com) at up to 2 000 Hz. This Python
library turns those recordings into first-class scientific objects:

- **`brsdk.load()`** — one-call dataset loading with strict metadata validation
- **Polars-native** — columnar computation without copying data
- **Typed** — full `mypy --strict` compliance; ships `py.typed`
- **Extensible** — reader and exporter protocols allow third-party backends

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

The SDK is a thin facade over two industry-standard libraries:

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
  author  = {{BRSDK Team}},
  year    = {2026},
  url     = {https://github.com/KartikeyaGangwar/BRSDK},
  version = {0.1.0},
}
```
