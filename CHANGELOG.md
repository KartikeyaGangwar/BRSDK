# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
