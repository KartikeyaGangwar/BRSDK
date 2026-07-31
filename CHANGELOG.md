# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-08-01

### Added
- **Visual Assets**: Introduced official BRSDK logo, repository banner, and social preview assets for consistent branding.
- **Architecture Documentation**: Added execution architecture and pipeline workflow SVG diagrams for improved visual understanding.
- **Reference Documentation**: Added exhaustive `SIGNAL_REFERENCE.md` detailing every telemetry column, its units, and nullability behavior.
- **API Reference**: Added `API_REFERENCE.md` outlining the internal Registry and Module system interfaces.

### Changed
- **README**: Restructured `README.md` to focus on quick start, architectural overview, and core features, moving deep technical details to the `docs/` folder.
- **Dataset Specification**: Clarified the JSON metadata sidecar schema and layout compatibility rules in `DATASET_SPECIFICATION.md`.

## [1.0.0] - 2026-08-01

### Added
- **Modular Physics Engine**: Full decoupling of physics extraction into `kinematics`, `orientation`, `driverInputs`, `thermals`, `powertrain`, `wheels`, `suspension`, `damage`, and `environment` modules.
- **Registry**: Centralized metadata registry tracking column names, data types, units, and categories.
- **Layout Engine**: Dynamic CSV layout ordering. Defaults to a byte-for-byte backward compatible `legacy_csv` layout.
- **Verification Suite**: Automated parity testing suite inside `verification/` to ensure determinism and schema integrity.

### Changed
- Refactored `telemetryLogger.lua` into a pure orchestrator. It now performs zero physics calculations.
- Achieved strict zero-allocation in the hot path. The logger now iterates an array of pre-cached closures, reducing GC overhead.

### Removed
- Removed monolithic legacy math and dual-path `MIGRATION_MODE` blocks.
- Stripped unused caching and deprecated fallbacks.

## [1.0.2] - 2026-08-01
- Added official Zenodo DOI
- Updated citation metadata