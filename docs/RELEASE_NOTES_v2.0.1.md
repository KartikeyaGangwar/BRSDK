# BeamNG Research SDK (BRSDK) v2.0.1

**BRSDK (BeamNG Research SDK)** is an open-source, dual-runtime computational framework engineered to bridge the **Simulation-to-Real (Sim2Real)** reality gap in autonomous driving, vehicle dynamics, and reinforcement learning within **BeamNG.drive** and **BeamNG.tech**.

Operating directly inside BeamNG's **2,000 Hz Vehicle Lua physics thread** with zero dynamic heap allocations on the hot path, BRSDK exports continuous ground-truth physical state trajectories (tire slip breakaway energy, suspension travel/velocities, wheel loads, and chassis compliance) paired with deterministic RFC 8259 provenance metadata sidecars. Downstream, the `brsdk` Python SDK provides Apache Arrow columnar memory, Polars query acceleration, and zero-copy DLPack interchange for PyTorch and Minari (offline RL).

---

## Key Capabilities

- **2,000 Hz Soft-Body In-Engine Telemetry**: Samples high-frequency vehicle dynamics directly from the soft-body spring-mass physics solver to resolve sub-millisecond transient dynamics critical for Sim2Real policy transfer.
- **Zero-Allocation Memory Architecture**: Pre-allocated serialization buffers and closure evaluations eliminate dynamic Lua heap allocations during logging, preserving deterministic simulation stepping with zero garbage collection (GC) frame drops.
- **RFC 8259 Provenance Metadata Sidecars**: Every dataset includes an automated `session.json` sidecar capturing physics step rates, engine timestamps, vehicle configurations, and environment parameters.
- **Columnar Scientific Python SDK (`brsdk`)**: Backed by Apache Arrow columnar memory and Polars query acceleration, featuring strict Pydantic V2 schema validation and zero-copy DLPack tensor export to PyTorch and Minari for offline reinforcement learning.

---

## What's Changed in v2.0.1

### Authorship & Metadata Synchronization
- Formally synchronized primary authorship to **Kartikeya Gangwar** ([ORCID: 0009-0009-1973-7532](https://orcid.org/0009-0009-1973-7532)) across `CITATION.cff`, `paper/paper.md`, `pyproject.toml`, package documentation, and release manifests.
- Integrated automated repository metadata sidecar (`.zenodo.json`) for seamless Zenodo DOI indexing, author attribution, and categorical discovery.

### Documentation & Build Verification
- Updated API reference, signal documentation, and reproducibility guides to version `v2.0.1`.
- Verified clean package builds (`brsdk-2.0.1.tar.gz`, `brsdk-2.0.1-py3-none-any.whl`) and automated test suite pass across Python 3.10, 3.11, 3.12, and 3.13.

---

## Quickstart

### Installation

```bash
pip install brsdk
```

Or install from source:

```bash
git clone https://github.com/KartikeyaGangwar/BRSDK.git
cd BRSDK/python
pip install -e .
```

### Loading Telemetry Datasets

```python
import brsdk

# Load dataset with strict session.json sidecar validation
dataset = brsdk.load("telemetry.csv")

# Access zero-copy Polars DataFrame
df = dataset.to_polars()
print(df.head())

# Export zero-copy tensors for PyTorch / Minari offline RL
tensors = dataset.to_torch()
```

---

## Citation

If you use BRSDK in your academic or applied research, please cite:

```bibtex
@software{gangwar2026brsdk,
  author  = {Kartikeya Gangwar},
  title   = {BeamNG Research SDK (BRSDK)},
  year    = {2026},
  version = {2.0.1},
  url     = {https://github.com/KartikeyaGangwar/BRSDK},
  license = {Apache-2.0},
  doi     = {10.5281/zenodo.21729606}
}
```

- **Author:** Kartikeya Gangwar (Department of Mathematics, University of Delhi, India)
- **ORCID:** [0009-0009-1973-7532](https://orcid.org/0009-0009-1973-7532)
- **Repository:** https://github.com/KartikeyaGangwar/BRSDK
- **Permanent DOI:** [10.5281/zenodo.21729606](https://doi.org/10.5281/zenodo.21729606)
- **License:** Apache License 2.0
