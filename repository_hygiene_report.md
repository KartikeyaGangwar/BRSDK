# Repository Hygiene Report

## Deleted Files & Folders
- `scripts/`: **Reason**: Completely unreferenced in the repository documentation and workflow. Safe to delete.
- `lua/vehicle/extensions/telemetryLogger_legacy.lua`: **Reason**: Monolithic legacy file that was fully migrated and deprecated. Obsolete.
- `lua/vehicle/extensions/brsdk/audit/`: **Reason**: AI-generated module/cache ownership and architecture reports. Temporary migration artifacts. Safe to delete.
- `lua/vehicle/extensions/brsdk/explorer/`: **Reason**: Development-only standalone script for discovering BeamNG APIs. Unreferenced by the core logger. Safe to delete.
- `lua/vehicle/extensions/brsdk/schema/`: **Reason**: Development-only standalone scripts for generating markdown schemas. Unreferenced by the core logger. Safe to delete.
- `lua/vehicle/extensions/brsdk/benchmarks/`: **Reason**: Empty folder. Safe to delete.
- `lua/vehicle/extensions/brsdk/golden/`: **Reason**: Empty folder. Safe to delete.
- `lua/vehicle/extensions/brsdk/tests/`: **Reason**: Empty folder. Safe to delete.
- `lua/vehicle/extensions/brsdk/**/*.json`: **Reason**: Removed all AI-generated benchmark reports, capabilities dumps, and verification summary outputs. These were temporary outputs that polluted the source tree. Safe to delete.

## Kept Folders & Files
- `docs/`: **Reason**: Required for core scientific and technical documentation.
- `.github/`: **Reason**: Required for CODEOWNERS and community health.
- `lua/ge/extensions/telemetryLoggerGE.lua`: **Reason**: Required to bootstrap the Vehicle Lua script from GameEngine.
- `lua/vehicle/extensions/telemetryLogger.lua`: **Reason**: Required core orchestrator.
- `lua/vehicle/extensions/brsdk/core/`: **Reason**: Required for configuration, registry, and utilities.
- `lua/vehicle/extensions/brsdk/layout/`: **Reason**: Required for CSV schema ordering.
- `lua/vehicle/extensions/brsdk/modules/`: **Reason**: Required for domain-specific telemetry extraction.
- `lua/vehicle/extensions/brsdk/verification/`: **Reason**: Required and actively referenced in `CONTRIBUTING.md` and `README.md` as the testing suite for PRs.
- Health Files (`README.md`, `LICENSE`, `CITATION.cff`, etc.): **Reason**: Required for open-source scientific repository compliance.

## Final Repository Tree
```text
BRSDK/
├── .github/
│   └── CODEOWNERS
├── docs/
│   ├── API_REFERENCE.md
│   ├── ARCHITECTURE.md
│   ├── DATASET_SPECIFICATION.md
│   ├── REPRODUCIBILITY.md
│   └── SIGNAL_REFERENCE.md
├── lua/
│   ├── ge/
│   │   └── extensions/
│   │       └── telemetryLoggerGE.lua
│   └── vehicle/
│       └── extensions/
│           ├── brsdk/
│           │   ├── core/
│           │   ├── layout/
│           │   ├── modules/
│           │   └── verification/
│           └── telemetryLogger.lua
├── .gitignore
├── CHANGELOG.md
├── CITATION.cff
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── LICENSE
├── NOTICE
├── README.md
├── SECURITY.md
└── repository_hygiene_report.md
```
