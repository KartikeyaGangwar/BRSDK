# Signal Reference

The BRSDK tracks hundreds of physical parameters natively. The exact list of signals exported to your CSV depends on the selected `Layout Engine` profile.

For a complete and interactive list of signals, simply inspect the `session.json` sidecar generated alongside your CSV datasets. The sidecar contains the full metadata schema (names, units, data types, physical meanings) active during that specific recording session.

## Core Categories

### Kinematics
- **Time**: `simulation_time`, `real_time`, `dt`, `elapsed_since_last_log`
- **Position & Velocity**: `pos_x/y/z`, `vel_x/y/z`, `speed_mps`
- **Acceleration**: `acc_x/y/z`, `gforce_x/y/z`

### Orientation
- **Angles**: `yaw_deg`, `pitch_deg`, `roll_deg`
- **Rates**: `ang_vel_roll_rads`, `ang_vel_pitch_rads`, `ang_vel_yaw_rads`

### Driver Inputs
- `throttle`, `brake`, `clutch`, `steering`

### Powertrain & Thermals
- `gear`, `rpm`, `engine_load`, `engine_torque_nm`, `engine_power_kw`
- `coolant_temp_c`, `oil_temp_c`, `fuel_norm`

### Wheels (Per Wheel)
- `speed_mps`, `angular_velocity`, `slip`, `downforce_n`, `suspension_travel`, `suspension_velocity`, `contact`, `tire_pressure`, `brake_temp_c`, `broken`
