# Contributing to BRSDK

Contributions to the BeamNG Research SDK (BRSDK) are welcome. This document outlines coding standards and the contribution workflow. 

## Code Style

### Lua
- **Indentation**: 2 spaces.
- **Variables**: Use `local` for all variables. Global pollution in the Vehicle VM is strictly prohibited.
- **Performance**: The 2000Hz hot path (`updateGFX` -> `collectRow`) must contain **ZERO allocations**. Do not create new tables (`{}`), concatenate strings (`..`), or create closures in the hot path. Pre-allocate state tables during `initialize()`.
- **Modularity**: Domain logic must reside in `brsdk/modules/`. The logger itself must remain a pure orchestrator.

### Python
- **Format & Linting**: Follow PEP-8 via [Ruff](https://docs.astral.sh/ruff/) with an 88-character line limit.
- **Types**: Full static typing mandatory (`mypy --strict`).
- **Guidelines**: See detailed instructions in [python/CONTRIBUTING.md](python/CONTRIBUTING.md).

### JSON / Markdown
- **JSON**: 2 spaces, double quotes.
- **Markdown**: Standard GitHub-flavored Markdown.

## Pull Request Process
1. Fork the repo and create your branch from `main`.
2. Ensure all quality gates pass:
   - For Python: `uv run ruff check .`, `uv run mypy src`, and `uv run pytest`.
   - For Lua: verify that telemetry collection remains strictly allocation-free on the 2000Hz hot path.
3. Update relevant documentation and changelogs.
4. Submit a pull request against the `main` branch.
