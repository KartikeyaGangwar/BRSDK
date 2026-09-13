# BeamNG Research SDK (BRSDK)

![BRSDK Banner](assets/banner.svg)

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Version](https://img.shields.io/badge/version-0.1.0-green.svg)]()
[![BeamNG](https://img.shields.io/badge/BeamNG.drive-v0.32+-orange.svg)]()
[![BeamNG Tech](https://img.shields.io/badge/BeamNG.tech-v0.32+-orange.svg)]()
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.21729606.svg)](https://doi.org/10.5281/zenodo.21729606)

BRSDK is a deterministic, high-frequency telemetry framework designed for scientific research, reinforcement learning, and autonomous vehicle simulation within **BeamNG.drive** and **BeamNG.tech**.

## Background and Motivation
Standard telemetry implementations often experience garbage collection (GC) latency spikes, non-deterministic physics stepping, and undocumented null values. BRSDK addresses these limitations for researchers requiring reproducible datasets for reinforcement learning and system identification.

## Key Features
- **Zero-Allocation In-Engine Logging**: Samples high-frequency signals with zero dynamic Lua heap allocations during collection, preserving deterministic simulation stepping without garbage collector pauses.
- **Orthogonal Domain Modules**: Modular telemetry architecture covering kinematics, orientation, powertrain, wheels, suspension, damage, and environment.
- **Configurable Layout Engine**: Supports backward-compatible legacy CSV schemas and ordered research layouts.
- **JSON Metadata Sidecars**: Every dataset includes an RFC 8259 `session.json` containing vehicle physics constraints, map parameters, and game versions.
- **Verification Suite**: Automated test suite verifying schema validation, type integrity, and error boundaries.

## Architecture Overview
BRSDK is built on a separation of concerns, operating primarily within the 2000Hz Vehicle Lua physics thread to preserve simulation fidelity:
- **Modules**: Perform high-frequency read-only queries against BeamNG APIs.
- **Registry**: The canonical registry for signal metadata, units, and data types.
- **Layout Engine**: Formats dynamic module signals into an ordered array.
- **Logger**: An I/O orchestrator that writes buffered records to disk via the Virtual File System (VFS).

For full details, see [ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Research Data Pipeline

![Research Pipeline](docs/images/pipeline.svg)

## Installation

BRSDK supports both **BeamNG.drive** (simulation) and **BeamNG.tech** (research platform).

1. Download the latest `BRSDK_v0.1.0.zip` release.
2. Extract the contents into your BeamNG user folder:
   - *BeamNG.drive*: `C:\Users\YourUser\AppData\Local\BeamNG.drive\0.32\mods\unpacked\BRSDK\`
   - *BeamNG.tech*: `C:\Users\YourUser\AppData\Local\BeamNG.tech\0.32\mods\unpacked\BRSDK\`
3. **Critical Folder Structure**: Your extracted mod folder MUST contain both the `lua/` and `scripts/` directories at the root level.
   - `scripts/`: Contains `modScript.lua`. BeamNG's engine automatically discovers files named `modScript.lua` during mod mounting to initialize the GameEngine extension.
   - `lua/`: Contains the actual telemetry payload (`lua/vehicle/extensions/brsdk/`). Without this, the vehicle will have no modules to load.

**How it loads:**
1. BeamNG discovers `scripts/telemetryLogger/modScript.lua` and executes it.
2. `modScript.lua` loads `lua/ge/extensions/telemetryLoggerGE.lua` into the GameEngine VM.
3. `telemetryLoggerGE` observes when a vehicle spawns and uses `queueLuaCommand` to inject the high-frequency logger directly into the sandboxed Vehicle Lua VM.

*Note: The `lua/` directory must not be placed directly in the user folder root; it must reside within an unpacked mod directory to allow `modScript.lua` to initialize.*

## Quick Start
1. Launch BeamNG and load any map and vehicle.
2. The logger will automatically mount and begin recording.
3. Drive the vehicle to generate telemetry.
4. Close the game or reset the vehicle to finalize the files.
5. Retrieve your datasets from the expected output folder: `[BeamNG User Path]/0.32/telemetry/`.

## Output Examples

**Expected CSV Output:** (`telemetry_[ID]_[TIMESTAMP].csv`)
![CSV Example](docs/images/csv_example.png)

**Expected JSON Output:** (`telemetry_[ID]_[TIMESTAMP]_session.json`)
![Session JSON Example](docs/images/session_json_example.png)

## Documentation
Technical documentation and references:
- [Python SDK (`brsdk`)](python/README.md)
- [API Reference](docs/API_REFERENCE.md)
- [Signal Reference](docs/SIGNAL_REFERENCE.md)
- [Dataset Specification](docs/DATASET_SPECIFICATION.md)
- [Reproducibility Guide](docs/REPRODUCIBILITY.md)

## Citation
If you use BRSDK in your published research, please cite it using the provided `CITATION.cff` file, or via the following BibTeX:
```bibtex
@software{singh2026brsdk,
  author  = {Kartikey Singh},
  title   = {BeamNG Research SDK (BRSDK)},
  year    = {2026},
  version = {0.1.0},
  url     = {https://github.com/KartikeyaGangwar/BRSDK},
  license = {Apache-2.0},
  doi     = {10.5281/zenodo.21729606}
}
```
The preferred citation is automatically available through GitHub's
"Cite this repository" feature using the included CITATION.cff file.

## License
BRSDK is released under the **Apache License 2.0**. See the [LICENSE](LICENSE) file for more details.

## Contributing
Please see [CONTRIBUTING.md](CONTRIBUTING.md) and our [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for details on submitting pull requests and reporting issues.

## Acknowledgements
The author acknowledges the BeamNG developers and research community for software support and feedback.
