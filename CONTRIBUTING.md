# Contributing to BRSDK

First off, thank you for considering contributing to the BeamNG Research SDK (BRSDK)! 

## Code Style

### Lua
- **Indentation**: 2 spaces.
- **Variables**: Use `local` for all variables. Global pollution in the Vehicle VM is strictly prohibited.
- **Performance**: The 2000Hz hot path (`updateGFX` -> `collectRow`) must contain **ZERO allocations**. Do not create new tables (`{}`), concatenate strings (`..`), or create closures in the hot path. Pre-allocate state tables during `initialize()`.
- **Modularity**: Domain logic must reside in `brsdk/modules/`. The logger itself must remain a pure orchestrator.

### Python
- **Format**: Follow PEP-8. Use `black` with an 88-character line limit.
- **Types**: Type hints are mandatory for all public functions.

### JSON / Markdown
- **JSON**: 2 spaces, double quotes.
- **Markdown**: Hard wrap at 80 characters.

## Pull Request Process
1. Fork the repo and create your branch from `main`.
2. If you've added code that should be tested, add tests to `verificationRunner.lua`.
3. Ensure your code passes all golden parity tests.
4. Issue that pull request!
