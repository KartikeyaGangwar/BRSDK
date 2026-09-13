---
title: 'BRSDK: A High-Frequency Zero-Allocation Telemetry Framework and Scientific Python SDK for BeamNG Research'
tags:
  - Python
  - Lua
  - BeamNG
  - autonomous vehicles
  - reinforcement learning
  - vehicle dynamics
  - telemetry
  - robotics
authors:
  - name: Kartikey Singh
    orcid: 0009-0009-1973-7532
    affiliation: 1
affiliations:
  - name: Independent Researcher, India
    index: 1
date: 13 September 2026
bibliography: paper.bib
---

# Summary

High-fidelity physics simulation is essential for modern robotics, autonomous vehicle engineering, and reinforcement learning. BeamNG.drive and its enterprise counterpart BeamNG.tech offer a soft-body dynamics physics engine that resolves vehicle components as spring-mass lattices at 2,000 Hz [@BeamNG:2020]. While this level of fidelity captures realistic tire contact patches, chassis deformation, and non-linear suspension dynamics, extracting this data at research frequencies has historically presented significant engineering hurdles. 

The BeamNG Research SDK (`BRSDK`) is an open-source, dual-runtime framework engineered to extract, serialize, validate, and analyze deterministic vehicle physics from BeamNG. It operates directly within the 2,000 Hz sandboxed Vehicle Lua Virtual Machine (VM) using a zero-dynamic-allocation hot-path architecture, preventing garbage-collection latency spikes from disrupting the simulation. Downstream, `BRSDK` couples each telemetry recording with an RFC 8259 JSON metadata sidecar and provides a modern, strictly typed Python SDK (`brsdk`) backed by Apache Arrow memory and the Polars query engine [@Arrow:2024; @Vink:2024].

# Statement of need

Scientific vehicle dynamics, system identification, and offline reinforcement learning algorithms rely on strictly deterministic, high-frequency physical state observations [@Towers:2023]. In BeamNG, vehicle-side code executes inside a Just-In-Time (JIT) compiled Lua VM [@Ierusalimschy:2007]. Conventional data logging approaches within Lua typically construct dynamic tables, strings, and closures inside each frame callback. In a 2,000 Hz physics loop, these operations rapidly accumulate garbage on the Lua memory heap, triggering periodic garbage collector pauses. These pauses cause non-deterministic frame stepping, missed samples, and sampling jitter, invalidating experimental reproducibility.

Furthermore, existing tools lack unified provenance metadata. Telemetry files frequently omit structural vehicle parameters (such as vehicle curb mass, part configurations, center-of-gravity offsets, and wheel dimensions) necessary to interpret raw kinematic arrays. Post-processing has historically relied on ad-hoc scripts that parse unstructured comma-separated value (CSV) files with ambiguous data types and undocumented null values.

`BRSDK` resolves these problems by providing:
1. **Near-zero dynamic heap allocations** during real-time data collection in Lua, preserving sub-millisecond physics determinism.
2. **Standardized metadata sidecars** (`session.json`) containing immutable vehicle configurations, environment parameters, and SDK provenance.
3. **A high-performance Python analysis library** implementing strict Pydantic V2 schema validation and zero-copy Apache Arrow / Polars representations for direct ingestion into scientific workflows and machine learning frameworks.

# State of the field

Researchers utilizing physical simulators have traditionally chosen between high-level autonomous driving platforms and real-time rigid-body engines:

- **CARLA** [@Dosovitskiy:2017] and **AirSim** [@Shah:2018] provide extensive sensor suites and urban environments, but rely primarily on simplified rigid-body vehicle dynamics (such as PhysX), which fail to model structural chassis twisting, tire thermal degradation, or component deformation under extreme limit handling.
- **BeamNG-py** provides a Python interface for orchestrating scenarios and interacting with BeamNG.tech via TCP network sockets. However, transferring telemetry over inter-process network sockets introduces latency and bandwidth bottlenecks that limit extraction frequencies to lower rates (typically 10–50 Hz), preventing researchers from observing transient high-frequency phenomena such as wheel hop, ABS pressure modulation, or suspension shudder.

`BRSDK` was developed rather than contributing directly to client-server frameworks because high-fidelity telemetry extraction must be co-located inside the vehicle's native physics thread. `BRSDK` acts as a specialized data-acquisition pipeline that complements existing scenario managers: it captures state natively inside the Vehicle VM at high frequencies and writes directly to the virtual filesystem, bypassing network overhead completely.

# Software design

The architecture of `BRSDK` is split across two execution environments: the high-frequency vehicle simulation runtime (Lua) and the analytical post-processing environment (Python).

## In-Engine Telemetry Pipeline (Lua)

In BeamNG, execution is isolated across two distinct virtual machines: the Game Engine (GE) VM and the Vehicle VM. The Vehicle VM executes within the 2,000 Hz physics loop but is strictly sandboxed from game engine APIs (e.g., world level names or rendering states). `BRSDK` orchestrates collection across these runtimes:

1. **Bootstrap Phase**: A Game Engine extension (`telemetryLoggerGE.lua`) boots during mod mounting, monitors vehicle spawning, and injects the vehicle extension (`telemetryLogger.lua`) into the Vehicle VM via `queueLuaCommand`.
2. **Decoupled Modular Architecture**: Signal extraction is partitioned into isolated domain modules (`kinematics`, `orientation`, `driverInputs`, `powertrain`, `thermals`, `suspension`, `wheels`, `damage`, and `environment`). Each module pre-allocates static state buffers during initialization.
3. **Signal Registry and Layout Engine**: Modules register metadata (signal name, unit, physical type, category) with a central `Registry`. The `Layout Engine` orders these signals into pre-compiled closure arrays for `O(1)` row evaluation during `updateGFX`.
4. **Zero-Allocation Guarantee**: String concatenations and dynamic table instantiations (`{}`) are eliminated on the hot path. Values are formatted directly into pre-allocated memory buffers flushed periodically to disk, preventing garbage collection invocation.

```
+-------------------------------------------------------------------+
|                     Vehicle Lua VM (2000 Hz)                     |
|                                                                   |
| [Kinematics] [Orientation] [Powertrain] [Wheels] [Suspension] ... |
|       │             │            │         │          │           |
|       └─────────────┴────────────┼─────────┴──────────┘           |
|                                  ▼                                |
|                        [Signal Registry]                          |
|                                  │                                |
|                                  ▼                                |
|                         [Layout Engine]                           |
|                                  │                                |
|                                  ▼                                |
|             [Zero-Allocation Orchestrator: collectRow]            |
|                                  │                                |
|                                  ▼                                |
+----------------------------------┼────────────────────────────────+
                                   ▼
                   +───────────────────────────────+
                   |     Disk / Output Storage     |
                   |  - telemetry_[id]_[ts].csv     |
                   |  - telemetry_[id]_[ts].json    |
                   +───────────────┬───────────────+
                                   ▼
+-------------------------------------------------------------------+
|                        Python SDK (brsdk)                         |
|                                                                   |
|  brsdk.load()                                                     |
|       ├── Pydantic V2 Validation ──► SessionMetadata              |
|       └── Polars Lazy CSV Scan   ──► Arrow-Backed Dataset.df      |
+-------------------------------------------------------------------+
```

## Python Scientific SDK (`brsdk`)

The Python SDK (`python/src/brsdk`) reads, validates, and models the exported telemetry datasets:

- **Immutability & Zero-Copy Computation**: Built in accordance with RFC-0001, the `Dataset` class serves as a lightweight container binding a `polars.DataFrame` to a validated `SessionMetadata` model. Polars utilizes Apache Arrow columnar memory under the hood, enabling multi-threaded queries and zero-copy data exchange with NumPy [@Harris:2020] and PyTorch tensors via DLPack.
- **Strict Metadata Boundary**: Sidecar JSON files are parsed through Pydantic V2 models (`SessionMetadata`, `SimulationMetadata`, `VehicleMetadata`, `SDKMetadata`) [@Pydantic:2024]. Fields inaccessible from the sandboxed Vehicle Lua VM (such as map identifiers or global engine versions) are handled through explicit sentinels (`"unavailable_from_vehicle_lua"`), ensuring robust validation without rejecting genuine empirical runs.

# Research impact statement

`BRSDK` provides reproducible data infrastructure for research in vehicle dynamics, tire friction estimation, and autonomous control. Key capabilities demonstrated include:

- **Empirical Validation**: Successfully tested on extensive real-world BeamNG simulation runs (exceeding 490,000 rows across 86 continuous signals per run) with zero memory leaks and consistent sub-millisecond recording intervals.
- **System Identification**: Enables extraction of suspension compression velocities and dynamic tire slip energy profiles that are inaccessible through standard game interfaces, facilitating physical parameter estimation.
- **Reproducible Data Sharing**: By pairing raw signal arrays with immutable `session.json` sidecars capturing vehicle geometry, mass properties, and simulator builds, datasets generated via `BRSDK` meet Open Science standards for archival and benchmark publishing.

# AI usage disclosure

Generative artificial intelligence tools (Anthropic Claude and Google Gemini) were used during the development of this software for tasks including unit test scaffolding, documentation cross-linking, formatting verification, and drafting portions of the technical text. All software architecture, physics modeling, algorithmic implementations, and experimental verifications were directed, reviewed, validated, and finalized by the human author, who assumes full responsibility for the contents of the software and manuscript.

# Acknowledgements

The author acknowledges BeamNG GmbH for developing the BeamNG simulation platform and supporting academic vehicle dynamics simulation.

# References
