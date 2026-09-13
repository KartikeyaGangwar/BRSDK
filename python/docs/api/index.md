# API Reference

This page documents the primary public interfaces provided by the `brsdk` Python package.

---

## Primary Entry Point

### `brsdk.load(path)`

Load a BRSDK telemetry dataset from disk.

```python
import brsdk

dataset = brsdk.load("path/to/telemetry_17801_20260801_135818.csv")
```

**Parameters:**
- `path` (*str* or *pathlib.Path*): Path to the `.csv` telemetry file. The paired `*_session.json` sidecar is automatically discovered in the same directory.

**Returns:**
- `Dataset`: An immutable, validated scientific dataset instance.

**Raises:**
- `DatasetNotFoundError`: If the specified CSV file does not exist.
- `SidecarNotFoundError`: If the corresponding `*_session.json` sidecar is missing.
- `MetadataValidationError`: If the sidecar fails Pydantic schema validation.
- `DatasetFormatError`: If the CSV is empty or missing mandatory header columns.

---

## Core Abstractions

### `brsdk.Dataset`

The top-level container binding the high-performance Polars telemetry DataFrame with validated Pydantic session metadata.

#### Properties:
- `dataframe` (*polars.DataFrame*): The tabular telemetry data with Arrow-backed memory.
- `session` (*SessionMetadata*): Typed, Pydantic-validated session metadata.
- `path` (*pathlib.Path*): Resolved absolute path to the source CSV file.
- `columns` (*list[str]*): List of column names present in the dataset.
- `shape` (*tuple[int, int]*): `(row_count, column_count)` of the dataset.
- `metadata` (*dict[str, Any]*): Reconstructed metadata dictionary for logging or serialization.

---

## Metadata Models

Located in `brsdk.metadata.models`:

### `SessionMetadata`
Top-level metadata container for the recording session:
- `sdk` (*SDKMetadata*): SDK and logger version information.
- `simulation` (*SimulationMetadata*): Simulation environment details (`log_hz`, `physics_rate`, `map_name`, `beamng_version`).
- `vehicle` (*VehicleMetadata*): Vehicle parameters (`vehicle_name`, `wheel_count`, `vehicle_config`, `vehicle_id`).
- `raw` (*dict[str, Any]*): Complete unmodified dictionary from `session.json`.

Convenience properties on `SessionMetadata`:
- `session.sdk_version`: Semantic version string.
- `session.log_hz`: Logging frequency in Hz.
- `session.beamng_version`: BeamNG version (or `"unavailable_from_vehicle_lua"` sentinel).
- `session.map_name`: Map identifier.
- `session.vehicle_name`: Human-readable vehicle model.
- `session.wheel_count`: Number of simulated wheels.

---

## Exceptions

Located in `brsdk.exceptions`:

- `BRSDKError`: Base exception class for all errors raised by BRSDK.
- `DatasetNotFoundError`: Raised when the specified CSV file cannot be located.
- `SidecarNotFoundError`: Raised when the `*_session.json` metadata sidecar is missing.
- `MetadataValidationError`: Raised when metadata fails schema or type constraints.
- `DatasetFormatError`: Raised when the CSV format violates BRSDK standards.
