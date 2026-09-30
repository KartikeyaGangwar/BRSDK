# Changelog

All notable changes to the **brsdk Python SDK** are documented in this file.

The format follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).

Version numbers follow the form `MAJOR.MINOR.PATCH`:

- `MAJOR` — incompatible public API change (requires RFC and deprecation period)
- `MINOR` — new backwards-compatible functionality
- `PATCH` — backwards-compatible bug fixes

> **Note**: This changelog covers the Python SDK only. Changes to the Lua
> telemetry scripts are tracked in the root-level
> [CHANGELOG.md](../CHANGELOG.md).

---

## [Unreleased]

_No unreleased changes._

---

## [2.0.1] — 2026-09-30

### Changed

- **Metadata & Authorship Alignment**: Formally synchronized author identity to `Kartikeya Gangwar` with ORCID ([`0009-0009-1973-7532`](https://orcid.org/0009-0009-1973-7532)) across `CITATION.cff`, `paper.md`, `pyproject.toml`, Zenodo metadata sidecars, and package distribution artifacts.
- **Zenodo Automation**: Integrated `.zenodo.json` repository specification for native Zenodo GitHub release integration.

---

## [2.0.0] — 2026-09-13

### Added

- **Core SDK Engine**:
  - `brsdk.load()` one-call entry point for loading telemetry datasets with strict schema validation.
  - `Dataset` immutable abstraction class binding Polars DataFrame with validated metadata.
  - `brsdk.io.reader` supporting lazy parsing via `polars.scan_csv(..., null_values=[""])`.
  - Pydantic V2 metadata models (`SessionMetadata`, `SimulationMetadata`, `VehicleMetadata`, `SDKMetadata`) validating `session.json` sidecars with sentinel handling.
  - Domain-specific exception hierarchy (`BRSDKError`, `DatasetNotFoundError`, `SidecarNotFoundError`, `MetadataValidationError`, `DatasetFormatError`).
- `pyproject.toml` conforming to PEP 517, PEP 518, PEP 621, and PEP 639 (SPDX licence expressions).
- `src/brsdk/py.typed` — PEP 561 marker enabling downstream `mypy` resolution.
- Hatchling build backend with `src/` layout configured.
- Ruff for linting and formatting; Mypy in strict mode; Pytest with 96% test coverage.
- GitHub Actions CI matrix: Ubuntu + Windows × Python 3.10, 3.11, 3.12.
- Optional dependency groups: `ml`, `viz`, `xarray`, `dev`, `all`.
- `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `SUPPORT.md`.
- MkDocs documentation with Material theme.
- `.editorconfig` for cross-editor whitespace normalisation.

### Architecture

- Canonical in-memory representation: **Polars DataFrame** over Apache Arrow memory (per RFC-0001).
- Metadata boundary: **Pydantic V2** strict validation of `session.json`.
- Dependency direction enforced: `io → core → accessors`; no circular imports.

---

[Unreleased]: https://github.com/KartikeyaGangwar/BRSDK/compare/v2.0.1...HEAD
[2.0.1]: https://github.com/KartikeyaGangwar/BRSDK/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/KartikeyaGangwar/BRSDK/releases/tag/v2.0.0
