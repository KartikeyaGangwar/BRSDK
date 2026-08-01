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

## [0.1.0] — 2026-08-01

### Added

- **Project bootstrap** (Phase 0): established the `python/` sub-directory
  as the canonical location for the BRSDK Python SDK.
- `pyproject.toml` conforming to PEP 517, PEP 518, PEP 621, and PEP 639
  (SPDX licence expressions).
- `src/brsdk/__init__.py` — public entry point exposing `__version__` and the
  `load()` function signature (implementation deferred to Phase 3).
- `src/brsdk/py.typed` — PEP 561 marker enabling downstream `mypy` resolution.
- Hatchling build backend with `src/` layout configured.
- Ruff for linting and formatting; Mypy in strict mode; Pytest with coverage.
- Pre-commit hook suite: `ruff`, `ruff-format`, `mypy`, and standard file
  hygiene hooks.
- GitHub Actions CI matrix: Ubuntu + Windows × Python 3.10, 3.11, 3.12.
- Optional dependency groups: `ml`, `viz`, `xarray`, `dev`, `all`.
- `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `SUPPORT.md`.
- `docs/index.md` — MkDocs documentation root.
- `.editorconfig` for cross-editor whitespace normalisation.

### Architecture

- Canonical in-memory representation: **Polars DataFrame** over Apache Arrow
  memory (per RFC-0001).
- Metadata boundary: **Pydantic V2** strict validation of `session.json`.
- Dependency direction enforced: `io → core → accessors`; no circular imports.

---

[Unreleased]: https://github.com/beamng-research/brsdk/compare/python-v0.1.0...HEAD
[0.1.0]: https://github.com/beamng-research/brsdk/releases/tag/python-v0.1.0
