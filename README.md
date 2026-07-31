# BRSDK
BeamNG Research SDK (BRSDK)

## One-line description
A modular, high-performance telemetry extraction framework for scientific research in BeamNG.drive.

## Features
- **Zero-Allocation Hot Path**: Extract thousands of rows per second with absolutely zero Lua garbage collector allocations, guaranteeing perfectly smooth and deterministic physics ticks.
- **Orthogonal Domain Modules**: Separate modules for kinematics, orientation, powertrain, wheels, suspension, damage, and environment.
- **Dynamic Layout Engine**: Swap seamlessly between backward-compatible legacy CSV schemas and alphabetical research layouts.
- **JSON Metadata Sidecars**: Every dataset includes a `session.json` containing immutable vehicle physics constraints, map parameters, and game versions.
- **Automated Verification**: Built-in test suite guarantees byte-for-byte identical output and determinism across module updates.

## Architecture
BRSDK is built on a strict separation of concerns, operating primarily within the 2000Hz Vehicle Lua physics thread to guarantee simulation fidelity:
- **Modules**: Perform high-frequency read-only queries against BeamNG APIs.
- **Registry**: The single source of truth for all column metadata, units, and data types.
- **Layout Engine**: Formats the dynamic module signals into an ordered array.
- **Logger**: A pure IO orchestrator that flushes the buffers to disk.

## Repository layout
```
BRSDK/
├── lua/
│   ├── ge/extensions/
│   │   └── telemetryLoggerGE.lua       # GameEngine extension hook
│   └── vehicle/extensions/
│       ├── brsdk/                      # Core SDK source
│       │   ├── core/                   # Utilities, Config, Registry
│       │   ├── layout/                 # Layout Engine
│       │   └── modules/                # Telemetry domains (kinematics, etc.)
│       └── telemetryLogger.lua         # Vehicle-side orchestrator
└── scripts/
    └── telemetryLogger/
        └── modScript.lua               # Initial BeamNG mod bootstrap
```

## Installation
1. Download the latest `BRSDK_v1.0.0.zip` release.
2. Extract the contents into your BeamNG user folder (e.g., `C:\Users\YourUser\AppData\Local\BeamNG.drive\0.32\mods\unpacked\BRSDK\`).
3. Ensure the structure maintains both the `lua/` and `scripts/` folders in the root of the mod directory.

## Quick Start
1. Launch BeamNG.drive and load any map and vehicle.
2. The `modScript.lua` bootstrap will automatically inject the logger into the vehicle.
3. Telemetry is collected at 100Hz and written to the `telemetry/` folder inside your BeamNG user directory.
4. To modify the logging frequency, edit `lua/vehicle/extensions/brsdk/core/config.lua` and adjust `M.LOG_HZ`.

## Output files
For every session, BRSDK produces two files in the output directory:
- `telemetry_[VEHICLE_ID]_[TIMESTAMP].csv`: The main telemetry dataset.
- `telemetry_[VEHICLE_ID]_[TIMESTAMP]_session.json`: The metadata sidecar.

## CSV schema
The output CSV follows the `legacy_csv` layout by default, exporting 86 columns (46 global vehicle state columns, and 10 columns per wheel for 4 wheels):
- **Kinematics**: `pos_x`, `vel_x`, `acc_x`, `speed_mps`, etc.
- **Orientation**: `yaw_deg`, `pitch_deg`, `roll_deg`, `ang_vel_roll_rads`, etc.
- **Driver Inputs**: `throttle`, `brake`, `steering`, `clutch`, `parkingbrake`, etc.
- **Powertrain/Thermals**: `gear`, `rpm`, `engine_load`, `coolant_temp_c`, etc.
- **Wheels (per wheel)**: `speed_mps`, `slip`, `downforce_n`, `suspension_travel`, `contact`, etc.

*Note: Missing or unsupported sensors (e.g., tire pressure on certain vehicles) will gracefully output as empty columns.*

## session.json schema
A valid RFC 8259 JSON object capturing immutable session parameters, including:
- **Vehicle Data**: `vehicle_config`, `cg_position` (nested object), `wheelbase`.
- **Environment**: `coordinate_system`, `physics_rate`.
- **System**: `creation_timestamp`, `lua_vm`, `jbeam_information`.
*(Any nested BeamNG `jbeam` data is safely serialized, dropping unparseable userdata to ensure valid JSON)*.

## How logging works
1. **Bootstrap**: When the mod is mounted, `scripts/telemetryLogger/modScript.lua` triggers GameEngine initialization.
2. **Injection**: `telemetryLoggerGE` observes spawned vehicles and queues Lua commands to load the logger in the Vehicle VM.
3. **Initialization**: The Vehicle VM loads the core registry, initializes all telemetry modules, and opens the CSV/JSON file handles via the Virtual File System (VFS).
4. **Data Loop**: On every graphical tick (`updateGFX`), the layout engine executes the bound module pointers, populating a row buffer.
5. **Flush**: Data is flushed to disk according to `FLUSH_EVERY_ROWS` to prevent physics blocking.

## BeamNG compatibility
Compatible with BeamNG.drive v0.32+. It uses standard `extensions.load` and `queueLuaCommand` methods to cross VM boundaries, adhering to official modding guidelines.

## Limitations
- **Vehicle VM Sandbox**: Global UI parameters (like global weather or time of day) are inaccessible from the Vehicle Lua VM without GameEngine IPC.
- **Disk I/O**: High-frequency logging (e.g., >200Hz) may cause stutter due to blocking file writes.
- **Unavailable Sensors**: Certain vehicles may lack specific JBEAM nodes (e.g., tire pressure, suspension travel), resulting in empty CSV fields.

## Roadmap
- **v1.1.0 (High Throughput)**: Native support for Apache Arrow and Parquet binary exports directly from Lua via FFI. Python SDK (`brsdk-py`).
- **v1.2.0 (Real-time Bridges)**: Low-latency socket bridge module to stream telemetry directly to ROS2 nodes and OpenAI Gym environments.
- **v1.3.0 (Traffic & World)**: Modules to extract bounding boxes, velocities, and intents of surrounding AI traffic.

## Citation
If you use BRSDK in your published research, please cite it using the provided `CITATION.cff` file, or via the following BibTeX:
```bibtex
@software{BRSDK_2026,
  author = {BRSDK Team},
  title = {BeamNG Research SDK (BRSDK)},
  month = {August},
  year = {2026},
  version = {1.0.0}
}
```

## License
BRSDK is released under the **Apache License 2.0**. See the [LICENSE](LICENSE) file for more details.
