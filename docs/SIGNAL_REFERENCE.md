# BRSDK Signal Reference

This document provides an exhaustive, field-level breakdown of the BRSDK `v1.0.1` telemetry dataset schema, defaulting to the `legacy_csv` layout.

BRSDK operates primarily as a read-only bridge to the 2000Hz Vehicle Lua physics engine. The exact list of signals exported depends on your layout engine profile, but the core engine behaviors and nullability rules apply universally.

## Core Kinematics (`kinematics`)

| Signal Name | Module | BeamNG API | Unit | Nullable? | Documentation / Explanation |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `frame_id` | `kinematics` | Internal `updateCallCount` | count | No | Dataset row index. Never blank. |
| `graphics_frame` | `kinematics` | Internal `totalRowsWritten` | count | No | Engine frame counter. Never blank. |
| `simulation_time` | `kinematics` | `obj:getSimTime()` | s | No | Simulation time perfectly synced to the physics tick. |
| `real_time` | `kinematics` | `os.clock()` | s | No | Wall clock time (host machine). |
| `dt` | `kinematics` | Internal Delta | s | No | Time between the current and previous sample. |
| `elapsed_since_last_log` | `kinematics` | Internal Accumulator | s | No | Time elapsed since the last CSV row was flushed. |
| `pos_x/y/z` | `kinematics` | `obj:getPosition()` | m | No | Global vehicle CG coordinates relative to the map origin. |
| `vel_x/y/z` | `kinematics` | `obj:getVelocity()` | m/s | No | Global vehicle velocity vector. |
| `speed_mps` | `kinematics` | Derived from Velocity | m/s | No | Speed magnitude. |
| `speed_kph` | `kinematics` | Derived from Velocity | km/h | No | Speed magnitude. |
| `acc_x/y/z` | `kinematics` | Derived (Finite Diff) | m/s² | No | Global acceleration derived from `vel_x/y/z` over `elapsed_since_last_log`. |
| `gforce_x/y/z` | `kinematics` | Derived | g | No | Acceleration divided by 9.81. |

## Orientation (`orientation`)

| Signal Name | Module | BeamNG API | Unit | Nullable? | Documentation / Explanation |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `yaw_deg`, `pitch_deg`, `roll_deg` | `orientation` | `obj:getRollPitchYaw()` | deg | No | Euler angles relative to world coordinates. |
| `ang_vel_roll_rads`, `ang_vel_pitch_rads`, `ang_vel_yaw_rads` | `orientation` | `obj:getRollPitchYawAngularVelocity()` | rad/s | No | Angular rates around local vehicle axes. |

## Driver Inputs (`driverInputs`)

| Signal Name | Module | BeamNG API | Unit | Nullable? | Documentation / Explanation |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `throttle`, `brake`, `clutch`, `parkingbrake`, `steering` | `driverInputs` | `electrics.values[name]` | norm | No | Output states of the driver inputs (0.0 to 1.0, or -1.0 to 1.0 for steering). |
| `throttle_input`, `brake_input`, `clutch_input`, `steering_input` | `driverInputs` | `electrics.values[name_input]` | norm | Yes | Raw HID inputs. Nullable if driving assists intercept input and the raw tag is unavailable. |

## Powertrain & Thermals (`powertrain`, `thermals`)

| Signal Name | Module | BeamNG API | Unit | Nullable? | Documentation / Explanation |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `gear` | `powertrain` | `electrics.values.gear` | str | Yes | String representation (e.g. "N", "1", "D"). Nil if no transmission is equipped. |
| `gear_index` | `powertrain` | `electrics.values.gearIndex` | idx | Yes | Integer representation (e.g. 0, 1). Nil if no transmission is equipped. |
| `rpm` | `powertrain` | `electrics.values.rpm` | rpm | Yes | Engine shaft RPM. Nil if no engine is equipped. |
| `engine_load` | `powertrain` | `electrics.values.engineLoad` | norm | Yes | 0.0 to 1.0. Nil if no engine is equipped. |
| `engine_torque_nm` | `powertrain` | `device.outputTorque1` | Nm | Yes | Raw torque from mainEngine device. Nil if device is unavailable. |
| `engine_power_kw` | `powertrain` | Computed (`Torque * AV`) | kW | Yes | Nil if torque or angular velocity are nil. |
| `coolant_temp_c` | `thermals` | `electrics.values.watertemp` | C | Yes | Radiator water temperature. Nil if thermal simulation is omitted. |
| `oil_temp_c` | `thermals` | `electrics.values.oiltemp` | C | Yes | Engine oil temperature. Nil if thermal simulation is omitted. |
| `fuel_norm` | `thermals` | `electrics.values.fuel` | norm | Yes | Fuel tank level (0.0 to 1.0). Nil if vehicle uses no fuel logic (e.g., simple props). |

## Damage (`damage`)

| Signal Name | Module | BeamNG API | Unit | Nullable? | Documentation / Explanation |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `driveshaft_broken` | `damage` | `electrics.values.driveshaft` | bool | Yes | 1 or 0 flag. Nil if vehicle lacks a physical driveshaft node. |

## Environment (`environment`)

| Signal Name | Module | BeamNG API | Unit | Nullable? | Documentation / Explanation |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `airspeed_mps` | `environment` | `electrics.values.airspeed` | m/s | Yes | True airspeed. Differs from ground speed due to wind. |

## Wheels (`wheels`, `suspension`)

*Note: Wheel columns are dynamically generated for however many wheels `wheels.wheels` returns (e.g., `wheel0_...`, `wheel1_...`).*

| Signal Name | Module | BeamNG API | Unit | Nullable? | Documentation / Explanation |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `wheelX_speed_mps` | `wheels` | `wd.wheelSpeed` | m/s | No | Ground speed magnitude of the wheel. |
| `wheelX_angular_velocity` | `wheels` | `wd.angularVelocity` | rad/s | No | Spin rate of the wheel. |
| `wheelX_slip` | `wheels` | `wd.slipEnergy` or `wd.lastSlip` | ratio | No | Relative slip energy. |
| `wheelX_downforce_n` | `wheels` | `wd.downForceRaw` | N | No | Vertical load on the wheel nodes. |
| `wheelX_contact` | `wheels` | `wd.contactMaterialID1` | id | No | **Engine-Assigned Dynamic ID**. Always an integer. `-1` universally means "Air" (no contact). Positive integers (e.g. `0`, `3`, `10`) dynamically map to surface properties via `particles.getMaterialsParticlesTable()`. They are map-dependent. **Do not treat positive integers as fixed constants.** |
| `wheelX_tire_pressure` | `wheels` | `wd.tirePressure` | Pa | **Yes** | Some legacy or arcade vehicles lack native tire pressure simulations. If `tirePressure` is missing from the API `wd` table, this exports as blank. This is expected behavior. |
| `wheelX_brake_temp_c` | `wheels` | `wd.brakeSurfaceTemperature` | C | **Yes** | Requires the vehicle's `JBeam` to explicitly equip thermal brake pads. If thermal simulation is off, this is blank. |
| `wheelX_broken` | `damage` | `wd.isBroken` | bool | No | 1 if the wheel has snapped off its axle, 0 otherwise. |
| `wheelX_suspension_travel` | `suspension` | `wd.suspensionTravel` or `wd.travel` | m | **Yes** | Suspension travel relies on explicit `suspensionTravel` tags in the `JBeam` definition. If a vehicle has a rigid axle, arcade physics, or an older JBeam standard, BeamNG does not calculate travel, returning `nil`. BRSDK correctly exports this as blank. |
| `wheelX_suspension_velocity`| `suspension` | Computed | m/s | **Yes** | Computed via `(travel - prev_travel) / elapsed`. Because it mathematically relies on `suspension_travel`, it will be legitimately blank if `suspension_travel` is blank. |

---
*Undocumented Engine Internals: BRSDK faithfully passes through any `nil` values directly from the BeamNG physics thread. We do not invent proxy data for vehicles missing complex node sensors.*
