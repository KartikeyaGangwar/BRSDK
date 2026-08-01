# Contributing to brsdk-python

Thank you for considering a contribution to the BRSDK Python SDK.
This document defines the standards every contribution must meet.
There are no exceptions — these rules protect the scientific reproducibility
of every researcher who depends on this library.

---

## Table of Contents

1. [Before You Start](#before-you-start)
2. [Development Environment](#development-environment)
3. [Code Standards](#code-standards)
4. [Testing Standards](#testing-standards)
5. [Commit Standards](#commit-standards)
6. [Pull Request Process](#pull-request-process)
7. [Architecture Rules](#architecture-rules)

---

## Before You Start

- Read [RFC-0001](docs/rfcs/rfc-0001-canonical-data-model.md).
  It is the authoritative data model. Do not propose alternatives in a PR.
- Check the issue tracker before opening a new issue.
- For major features or API changes, open an issue for discussion before writing
  any code. Unilateral API additions will not be merged.

---

## Development Environment

This project uses [`uv`](https://github.com/astral-sh/uv) for dependency
management. Do not use bare `pip` or `conda` for this repository.

```bash
# 1. Clone the repository
git clone https://github.com/beamng-research/brsdk.git
cd brsdk/python

# 2. Create the development virtual environment with all extras
uv sync --extra dev

# 3. Install pre-commit hooks (mandatory, run once per clone)
uv run pre-commit install

# 4. Verify the environment is healthy
uv run pytest
uv run mypy src/brsdk
uv run ruff check src/ tests/
```

All four commands must exit with code `0` before submitting a pull request.

---

## Code Standards

### Language

All Python source code targets **Python 3.10+** in compliance with
[Scientific Python SPEC 0](https://scientific-python.org/specs/spec-0000/).
Do not use syntax, standard-library APIs, or third-party features that require
Python 3.11 or later without first updating `requires-python` via an RFC.

### Formatting and Linting

This project uses [Ruff](https://docs.astral.sh/ruff/) as its sole formatting
and linting tool. `black`, `flake8`, `isort`, and `pyupgrade` are **not** used.

- **Line length**: 88 characters (configured in `pyproject.toml`).
- **Docstring style**: NumPy convention (configured via `pydocstyle` Ruff rule).
- **Import order**: enforced by Ruff's `I` rule set (isort-compatible).

Run the full lint suite:

```bash
uv run ruff check --fix src/ tests/
uv run ruff format src/ tests/
```

Both must produce zero warnings or errors. The pre-commit hooks enforce this
automatically before each commit.

### Type Annotations

Every public function, method, and class must carry full type annotations.
Every private helper must carry type annotations unless the type is trivially
inferred by Mypy without ambiguity.

This project runs `mypy --strict`. There are no exceptions.
Do not use `# type: ignore` comments without an accompanying comment explaining
why the suppression is necessary and when it can be removed.

```bash
# Type-check the package
uv run mypy src/brsdk
```

### Docstrings

Every public module, class, and function requires a NumPy-style docstring with
`Parameters`, `Returns`, and `Raises` sections where applicable.
Private helpers require a one-line summary docstring at minimum.

Example:

```python
def load(path: str | Path) -> Dataset:
    """Load a BRSDK telemetry session from disk.

    Parameters
    ----------
    path : str or Path
        Path to the telemetry CSV file. The paired ``*_session.json``
        sidecar is discovered automatically in the same directory.

    Returns
    -------
    Dataset
        A validated, immutable dataset object backed by a Polars DataFrame.

    Raises
    ------
    FileNotFoundError
        If ``path`` does not exist on disk.
    MetadataValidationError
        If the paired ``session.json`` fails Pydantic schema validation.
    DatasetFormatError
        If the CSV does not contain the required timestamp columns.
    """
```

---

## Testing Standards

### Framework

Tests use [pytest](https://docs.pytest.org) with
[hypothesis](https://hypothesis.readthedocs.io) for property-based testing.

### Coverage

The CI gate enforces **90% line coverage** minimum. New code that lowers
coverage below the threshold will not be merged.

### Rules

1. **No mocking of I/O.** Tests that require a file on disk must write a real
   temporary file using pytest's `tmp_path` fixture. This ensures we test the
   actual OS I/O path, not a mock.
2. **Property-based tests for all validation boundaries.** Every Pydantic model
   must have at least one Hypothesis test that generates random invalid inputs
   and verifies `ValidationError` is raised.
3. **Golden dataset tests.** The `tests/data/` directory contains a committed
   minimal golden CSV and session JSON (`golden_v1.csv`, `golden_v1_session.json`).
   These files are frozen. Any change to the output format requires updating the
   golden files with an explicit commit comment.
4. **No tests marked `skip` without an open GitHub issue reference** explaining
   when the skip can be removed.

```bash
# Run tests with coverage
uv run pytest --cov=brsdk --cov-report=term-missing tests/
```

---

## Commit Standards

This project follows
[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

```
<type>(<scope>): <short summary>

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`.

Examples:

```
feat(io): add Parquet reader via polars.scan_parquet
fix(metadata): reject negative log_hz values in SessionMetadata
docs(api): add NumPy docstring to brsdk.load()
test(metadata): add Hypothesis tests for VehicleMetadata
```

**Scope** refers to the module or layer affected
(`io`, `metadata`, `core`, `accessors`, `ml`, `viz`, `ci`, `docs`).

---

## Pull Request Process

1. Fork the repository and create a branch from `main`.
   Branch name convention: `<type>/<short-description>`
   (e.g., `feat/parquet-reader`, `fix/metadata-log-hz`).
2. Make your changes.
3. Verify the full quality gate passes locally:
   ```bash
   uv run ruff check src/ tests/
   uv run ruff format --check src/ tests/
   uv run mypy src/brsdk
   uv run pytest --cov=brsdk tests/
   ```
4. Update `CHANGELOG.md` under the `[Unreleased]` section.
5. Open a pull request against `main`. Fill in the PR template completely.
6. CI must pass on all matrix targets (Ubuntu + Windows, Python 3.10–3.12)
   before review will begin.
7. At least one maintainer approval is required before merge.

---

## Architecture Rules

These rules are non-negotiable. Violations will be rejected at review.

| Rule | Reason |
|------|--------|
| Do not add new public API without an RFC | Stability guarantee for downstream researchers |
| Do not import `torch`, `matplotlib`, or `xarray` in `brsdk.core` | Keeps the core install lightweight |
| Do not add `pandas` as a core dependency | Polars is the canonical compute engine per RFC-0001 |
| Do not use `Any` in typed code without a `# noqa` explanation | Silent `Any` propagation defeats Mypy strict |
| Do not commit dataset files (`.csv`, `.parquet`, `.arrow`) | Data lives in a separate repository |
| Do not use `assert` for runtime validation | Use `if ... raise` with explicit exception types |
