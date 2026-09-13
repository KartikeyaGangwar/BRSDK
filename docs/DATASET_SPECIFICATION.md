# Dataset Specification

BRSDK produces datasets intended for offline machine learning, system identification, and reinforcement learning. For a full breakdown of the signals contained in this dataset, refer to the [Signal Reference](SIGNAL_REFERENCE.md).

## Output Format
- **Format**: CSV (Comma-Separated Values).
- **Encoding**: UTF-8.
- **Header**: Present on the first line.
- **Null Values**: Represented as empty strings (`,,`).

## Session Metadata Sidecar
For every `telemetry_XXX.csv` generated, a sibling `telemetry_XXX_session.json` file is produced. This file contains metadata strictly necessary for dataset reproduction.

### Example Sidecar
```json
{
  "sdk_version": "0.1.0-phase1b",
  "log_hz": 100,
  "wheel_count": 4,
  "beamng_version": "0.32.1",
  "map_name": "gridmap_v2",
  "vehicle_name": "bastion"
}
```

## Loading Datasets (Python)
The official [Python SDK (`brsdk`)](../python/README.md) is the recommended way to load BRSDK datasets. It natively handles the sidecar metadata, validates the schema, and returns a high-performance Polars DataFrame.

## Legacy CSV Layout Compatibility
If BRSDK is configured to use the `legacy_csv` layout, the CSV will be byte-for-byte compatible with telemetry parsers built prior to v0.1.0 modularization. The columns follow strict ordering defined by the [Architecture Layout Engine](ARCHITECTURE.md):

1. Kinematics (Time, Pos, Vel, Acc, GForce)
2. Orientation (Yaw, Pitch, Roll, Angular Velocity)
3. Driver Inputs (Throttle, Brake, Steering, etc.)
4. Powertrain & Thermals
5. Environment & Damage
6. Wheels (Sequential: `wheel0_speed`, `wheel0_slip`... `wheel3_brake_temp`)
