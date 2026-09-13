# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-08-01

### Added
- **Python SDK**: Initial release of the `brsdk` Python package for loading, validating, and analysing telemetry datasets via Polars and Pydantic.
- **Modular Physics Engine**: Full decoupling of physics extraction into `kinematics`, `orientation`, `driverInputs`, `thermals`, `powertrain`, `wheels`, `suspension`, `damage`, and `environment` modules.
- **Registry**: Centralized metadata registry tracking column names, data types, units, and categories.
- **Layout Engine**: Dynamic CSV layout ordering. Defaults to a byte-for-byte backward compatible `legacy_csv` layout.
- **Visual Assets**: Added BRSDK vector logo, banner, and preview diagrams.
- **Architecture Documentation**: Added execution architecture and pipeline workflow SVG diagrams.
- **Reference Documentation**: Added `SIGNAL_REFERENCE.md` specifying telemetry columns, units, and nullability properties.
- **API Reference**: Added `API_REFERENCE.md` outlining the internal Registry and Module system interfaces.
- **Citation**: Added official Zenodo DOI and `CITATION.cff` metadata.

### Changed
- **README**: Restructured `README.md` to summarize quick start, architecture, and core modules, organizing extended documentation under `docs/`.
- **Dataset Specification**: Clarified the JSON metadata sidecar schema and layout compatibility rules in `DATASET_SPECIFICATION.md`.
- **Logger**: Refactored `telemetryLogger.lua` into a pure orchestrator. It now performs zero physics calculations.
- **Performance**: Avoided dynamic memory allocations during logging iterations by evaluating pre-allocated closures, minimizing Lua garbage collector pauses.

### Removed
- Removed monolithic legacy math and dual-path `MIGRATION_MODE` blocks.
- Stripped unused caching and deprecated fallbacks.