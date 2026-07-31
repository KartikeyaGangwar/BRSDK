# Telemetry Logger — BeamNG.drive v0.38.6 mod

Real-time vehicle telemetry logger for **regular BeamNG.drive (Steam)** — no
BeamNG.tech, no BeamNGpy. Pure Lua, runs entirely inside the game.

Logs ~100 Hz CSV telemetry for every vehicle you spawn (or drive) to:

```
Documents/BeamNG.drive/<version>/telemetry/telemetry_<vehicleId>_<timestamp>.csv
```

## Folder structure

```
TelemetryLogger/
├── lua/
│   ├── ge/
│   │   └── extensions/
│   │       └── telemetryLoggerGE.lua      <- game-engine side, injects logger into vehicles
│   └── vehicle/
│       └── extensions/
│           └── telemetryLogger.lua        <- the actual logger (runs per-vehicle)
└── scripts/
    └── telemetryLogger/
        └── modScript.lua                  <- auto-run entry point
```

## Installation

1. Locate your BeamNG.drive **user folder**. By default:
   `Documents\BeamNG.drive\0.38\` (open it quickly from the game launcher:
   *"Manage User Folder" → "Open User Folder"*).
2. Inside that user folder, go to (or create) the `mods` folder, then create
   an `unpacked` subfolder if it doesn't already exist:
   ```
   Documents\BeamNG.drive\0.38\mods\unpacked\
   ```
3. Copy the whole `TelemetryLogger` folder (the one containing `lua/` and
   `scripts/`) into `mods\unpacked\`, so you end up with:
   ```
   Documents\BeamNG.drive\0.38\mods\unpacked\TelemetryLogger\lua\...
   Documents\BeamNG.drive\0.38\mods\unpacked\TelemetryLogger\scripts\...
   ```
   *(Alternatively, zip the `TelemetryLogger` folder's **contents** — not the
   folder itself — into `TelemetryLogger.zip` and drop that zip into the
   regular `mods` folder instead of `mods\unpacked`. Either works.)*
4. Start BeamNG.drive. Open the in-game **Mods** menu (or the "unpacked
   mods" dev list) and make sure "Telemetry Logger" / `TelemetryLogger` is
   enabled.
5. Load into any map and spawn a vehicle. Logging starts automatically —
   no console commands needed.
6. Check `Documents\BeamNG.drive\0.38\telemetry\` for the generated CSV
   file(s). A new file is created every time a vehicle spawns and every
   time it's reset (press **I**), so pre-/post-reset data never mix.

> The exact `0.38` subfolder name matches whatever version folder your game
> is currently using inside `Documents\BeamNG.drive\`. If BeamNG updates to
> `0.39` etc., a new version folder (and therefore a new `telemetry` folder
> inside it) will be used automatically — no changes needed in the mod.

## How it works

- **`lua/ge/extensions/telemetryLoggerGE.lua`** runs in the main game Lua VM.
  It listens for `onVehicleSpawned` / `onVehicleResetted` and tells each
  vehicle's own Lua VM to load `telemetryLogger`.
- **`lua/vehicle/extensions/telemetryLogger.lua`** runs *inside* each
  vehicle's Lua VM. On load it opens a new timestamped CSV file, writes a
  header row, and then accumulates physics-tick `dt` to emit one row every
  1/100th of a second — a stable 100 Hz regardless of the underlying physics
  tick rate.
- **`scripts/telemetryLogger/modScript.lua`** is BeamNG's standard mod
  auto-run entry point; it loads the GE extension the moment the mod is
  active, so you never have to type a console command.
- Every single field read (position, electrics bus, wheel data, engine
  device, etc.) is wrapped defensively. If a particular value doesn't exist
  on a given vehicle or game version, that CSV cell is simply left empty
  instead of crashing the logger.

## Logged columns

`timestamp_unix, session_time_s, pos_x/y/z, vel_x/y/z, speed_mps, speed_kph,
acc_x/y/z, gforce_x/y/z, yaw_deg, pitch_deg, roll_deg, ang_vel_x/y/z,
throttle, throttle_input, brake, brake_input, clutch, clutch_input,
parkingbrake, steering, steering_input, gear, gear_index, rpm, engine_load,
engine_torque_nm, engine_power_kw, coolant_temp_c, oil_temp_c, fuel_norm,
driveshaft_broken, airspeed_mps`, plus **per wheel** (`wheel0_`, `wheel1_`,
… — count auto-detected per vehicle): `speed_mps, angular_velocity, slip,
downforce_n, suspension_travel, suspension_velocity, contact, tire_pressure,
brake_temp_c, broken`.

Fields marked as best-effort in the source (suspension travel/velocity, tire
pressure, brake temperature, engine torque/power, driveshaft status) depend
on the specific vehicle's jbeam/powertrain setup and BeamNG version. If a
vehicle doesn't expose them, those columns will simply be empty (`""`) for
that vehicle rather than causing an error.

## Extending it

Run this in the vehicle Lua console (F11 → Console, VEHICLE Lua tab) while
sitting in a car to print every currently-known `electrics.values` key —
handy for discovering more fields to add:

```lua
telemetryLogger.listAvailableElectrics()
```

Then add `elec('yourFieldName')` calls (and matching header columns) inside
`collectRow()` in `telemetryLogger.lua`.

## Performance notes

- 100 Hz CSV logging with ~60+ columns per row is lightweight but not free.
  If you notice a performance impact on lower-end hardware, lower `LOG_HZ`
  at the top of `telemetryLogger.lua` (e.g. to 60 or 30).
- Rows are flushed to disk every 50 rows (~0.5s at 100 Hz) rather than every
  single row, to reduce disk I/O overhead while still bounding data loss on
  a crash to well under a second.

## Uninstalling

Delete (or disable via the in-game Mods menu) the `TelemetryLogger` folder
from `mods\unpacked\` (or the zip from `mods\`). Previously logged CSV files
in `telemetry\` are left untouched.
