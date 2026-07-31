-- ============================================================================
--  telemetryLogger.lua   (VEHICLE-SIDE extension)
--
--  Real-time vehicle telemetry logger for BeamNG.drive v0.38.6 (regular
--  BeamNG.drive, NOT BeamNG.tech, NO BeamNGpy).
--
--  This file lives in each vehicle's own Lua VM ("vehicle Lua"). It is
--  loaded automatically for every spawned vehicle by the companion GE-side
--  extension (lua/ge/extensions/telemetryLoggerGE.lua).
--
--  It writes one CSV row per sample at ~100 Hz to:
--     Documents/BeamNG.drive/<version>/telemetry/telemetry_<id>_<timestamp>.csv
--
--  Every individual reading is wrapped defensively (pcall / nil-checks) so
--  that a value which doesn't exist on a given vehicle / game version is
--  simply written as an empty CSV cell instead of crashing the logger.
-- ============================================================================

local M = {}

-- ---------------------------------------------------------------------------
-- CONFIGURATION
-- ---------------------------------------------------------------------------
local LOG_HZ            = 100          -- target sampling rate
local LOG_INTERVAL       = 1 / LOG_HZ   -- seconds between samples
local FLUSH_EVERY_ROWS    = 50          -- flush to disk roughly every 0.5s @100Hz
local OUTPUT_DIR         = '/telemetry' -- relative to the BeamNG user folder
                                        -- (resolves to Documents/BeamNG.drive/<version>/telemetry)

-- ---------------------------------------------------------------------------
-- STATE
-- ---------------------------------------------------------------------------
local logFile          = nil
local logFilePath       = nil
local timeAcc           = 0
local rowsSinceFlush    = 0
local sessionStartTime  = 0
local prevVelocity      = nil   -- vec3, previous frame velocity (for acceleration)
local prevTime          = nil
local headerWritten     = false
local isLogging         = false
local wheelCount        = 0
local prevSuspTravel    = {}    -- [wheelIndex] = last travel value, for suspension velocity

-- ---------------------------------------------------------------------------
-- SMALL HELPERS
-- ---------------------------------------------------------------------------

-- Calls fn(...) protected by pcall. Returns nil (instead of erroring) if the
-- function, or any API/field it touches, isn't available. Supports up to 3
-- return values, which is enough for everything we read here.
local function safe(fn, ...)
  local ok, a, b, c = pcall(fn, ...)
  if ok then return a, b, c end
  return nil
end

-- Formats any value for a CSV cell. Missing data becomes an empty cell
-- (per spec: "if a variable is unavailable, skip it gracefully").
local function fmt(v)
  if v == nil then
    return ''
  elseif type(v) == 'number' then
    if v ~= v then return '' end        -- NaN guard
    if v == math.huge or v == -math.huge then return '' end
    return string.format('%.6f', v)
  elseif type(v) == 'boolean' then
    return v and '1' or '0'
  else
    -- Strip characters that would break CSV formatting
    return tostring(v):gsub('[,\r\n]', ' ')
  end
end

-- Reads a value out of the electrics bus (electrics.values.*) without
-- throwing if the electrics system or the key isn't present.
local function elec(name)
  if electrics and electrics.values then
    return electrics.values[name]
  end
  return nil
end

-- Counts how many wheels this vehicle has by probing the `wheels.wheels`
-- table (0-indexed by the game).
local function countWheels()
  if not wheels or not wheels.wheels then return 0 end
  local n = 0
  while wheels.wheels[n] ~= nil do
    n = n + 1
  end
  return n
end

-- Best-effort engine device lookup (works across most powertrains).
local function getEngineDevice()
  if not powertrain or not powertrain.getDevice then return nil end
  local dev = safe(powertrain.getDevice, 'mainEngine')
  if dev then return dev end
  -- Fallback: scan all devices for something that looks like an engine
  if powertrain.getDevices then
    local devs = safe(powertrain.getDevices)
    if devs then
      for _, d in pairs(devs) do
        if d and d.type and tostring(d.type):lower():find('engine') then
          return d
        end
      end
    end
  end
  return nil
end

local function getDriveshaftDevice()
  if not powertrain or not powertrain.getDevice then return nil end
  return safe(powertrain.getDevice, 'driveshaft')
end

-- Approximate yaw/pitch/roll (degrees) from the vehicle's forward/up
-- direction vectors. This is a standard approximation used by many BeamNG
-- dashboard mods; treat as "close enough" for research/telemetry purposes.
local function getOrientation()
  local fwd = safe(function() return obj:getDirectionVector() end)
  local up  = safe(function() return obj:getDirectionVectorUp() end)
  if not fwd or not up then return nil, nil, nil end

  local yaw   = math.deg(math.atan2(fwd.x, fwd.y))
  local pitch = math.deg(math.asin(math.max(-1, math.min(1, fwd.z))))

  local right = fwd:cross(up)
  local roll  = math.deg(math.atan2(right.z, up.z))

  return yaw, pitch, roll
end

-- ---------------------------------------------------------------------------
-- FILE / HEADER MANAGEMENT
-- ---------------------------------------------------------------------------

local function buildHeader()
  local cols = {
    'timestamp_unix', 'session_time_s',
    'pos_x', 'pos_y', 'pos_z',
    'vel_x', 'vel_y', 'vel_z', 'speed_mps', 'speed_kph',
    'acc_x', 'acc_y', 'acc_z',
    'gforce_x', 'gforce_y', 'gforce_z',
    'yaw_deg', 'pitch_deg', 'roll_deg',
    'ang_vel_x', 'ang_vel_y', 'ang_vel_z',
    'throttle', 'throttle_input',
    'brake', 'brake_input',
    'clutch', 'clutch_input',
    'parkingbrake',
    'steering', 'steering_input',
    'gear', 'gear_index',
    'rpm', 'engine_load', 'engine_torque_nm', 'engine_power_kw',
    'coolant_temp_c', 'oil_temp_c', 'fuel_norm',
    'driveshaft_broken',
    'airspeed_mps',
  }

  for i = 0, wheelCount - 1 do
    local p = 'wheel' .. i .. '_'
    table.insert(cols, p .. 'speed_mps')
    table.insert(cols, p .. 'angular_velocity')
    table.insert(cols, p .. 'slip')
    table.insert(cols, p .. 'downforce_n')
    table.insert(cols, p .. 'suspension_travel')
    table.insert(cols, p .. 'suspension_velocity')
    table.insert(cols, p .. 'contact')
    table.insert(cols, p .. 'tire_pressure')
    table.insert(cols, p .. 'brake_temp_c')
    table.insert(cols, p .. 'broken')
  end

  return cols
end

-- Opens a fresh CSV file (with a unique, timestamped name) and writes the
-- header row.
local function openNewFile()
  -- make sure the output directory exists (creates parents too, if the
  -- underlying VFS supports mkdir -p semantics)
  safe(function() FS:directoryCreate(OUTPUT_DIR) end)

  local stamp = safe(function() return os.date('%Y%m%d_%H%M%S') end) or tostring(os.time and os.time() or 0)
  local vehId = safe(function() return obj:getId() end) or 'unknown'

  logFilePath = OUTPUT_DIR .. '/telemetry_' .. tostring(vehId) .. '_' .. stamp .. '.csv'

  local file, err = io.open(logFilePath, 'w')
  if not file then
    log('E', 'telemetryLogger', 'Could not open telemetry file "' .. tostring(logFilePath) .. '": ' .. tostring(err))
    isLogging = false
    return
  end

  logFile = file
  wheelCount = countWheels()
  local cols = buildHeader()
  logFile:write(table.concat(cols, ',') .. '\n')
  logFile:flush()

  headerWritten    = true
  rowsSinceFlush   = 0
  timeAcc          = 0
  sessionStartTime = 0
  prevVelocity     = nil
  prevTime         = nil
  prevSuspTravel   = {}
  isLogging        = true

  log('I', 'telemetryLogger', 'Logging telemetry to: ' .. tostring(logFilePath))
end

local function closeFile()
  if logFile then
    safe(function() logFile:flush() end)
    safe(function() logFile:close() end)
    log('I', 'telemetryLogger', 'Closed telemetry file: ' .. tostring(logFilePath))
  end
  logFile = nil
  headerWritten = false
  isLogging = false
end

-- ---------------------------------------------------------------------------
-- SAMPLE COLLECTION
-- ---------------------------------------------------------------------------

local function collectRow(dt)
  local row = {}

  -- --- time -----------------------------------------------------------
  row[#row+1] = fmt(safe(os.time))
  sessionStartTime = sessionStartTime + dt
  row[#row+1] = fmt(sessionStartTime)

  -- --- position ---------------------------------------------------------
  local pos = safe(function() return obj:getPosition() end)
  row[#row+1] = fmt(pos and pos.x)
  row[#row+1] = fmt(pos and pos.y)
  row[#row+1] = fmt(pos and pos.z)

  -- --- velocity / speed ---------------------------------------------------
  local vel = safe(function() return obj:getVelocity() end)
  row[#row+1] = fmt(vel and vel.x)
  row[#row+1] = fmt(vel and vel.y)
  row[#row+1] = fmt(vel and vel.z)
  local speed = vel and math.sqrt((vel.x or 0)^2 + (vel.y or 0)^2 + (vel.z or 0)^2) or nil
  row[#row+1] = fmt(speed)
  row[#row+1] = fmt(speed and speed * 3.6)

  -- --- acceleration & G-force (finite difference of velocity) -------------
  local ax, ay, az = nil, nil, nil
  if vel and prevVelocity and prevTime and dt > 0 then
    ax = (vel.x - prevVelocity.x) / dt
    ay = (vel.y - prevVelocity.y) / dt
    az = (vel.z - prevVelocity.z) / dt
  end
  row[#row+1] = fmt(ax)
  row[#row+1] = fmt(ay)
  row[#row+1] = fmt(az)
  row[#row+1] = fmt(ax and ax / 9.81)
  row[#row+1] = fmt(ay and ay / 9.81)
  row[#row+1] = fmt(az and (az / 9.81))
  if vel then prevVelocity = { x = vel.x, y = vel.y, z = vel.z } end
  prevTime = dt

  -- --- orientation --------------------------------------------------------
  local yaw, pitch, roll = safe(getOrientation)
  row[#row+1] = fmt(yaw)
  row[#row+1] = fmt(pitch)
  row[#row+1] = fmt(roll)

  -- --- angular velocity -----------------------------------------------------
  local angVel = safe(function() return obj:getRotationVelocity() end)
  row[#row+1] = fmt(angVel and angVel.x)
  row[#row+1] = fmt(angVel and angVel.y)
  row[#row+1] = fmt(angVel and angVel.z)

  -- --- driver inputs / electrics bus ---------------------------------------
  row[#row+1] = fmt(elec('throttle'))
  row[#row+1] = fmt(elec('throttle_input'))
  row[#row+1] = fmt(elec('brake'))
  row[#row+1] = fmt(elec('brake_input'))
  row[#row+1] = fmt(elec('clutch'))
  row[#row+1] = fmt(elec('clutch_input'))
  row[#row+1] = fmt(elec('parkingbrake'))
  row[#row+1] = fmt(elec('steering'))
  row[#row+1] = fmt(elec('steering_input'))
  row[#row+1] = fmt(elec('gear'))
  row[#row+1] = fmt(elec('gearIndex'))

  -- --- engine ---------------------------------------------------------------
  row[#row+1] = fmt(elec('rpm') or elec('RPM'))
  row[#row+1] = fmt(elec('engineLoad'))

  local engTorque, engPowerKw = nil, nil
  local engDev = safe(getEngineDevice)
  if engDev then
    local torque = safe(function() return engDev.outputTorque1 end)
    local av     = safe(function() return engDev.outputAV1 end)
    engTorque = torque
    if torque and av then
      engPowerKw = (torque * av) / 1000 -- torque(Nm) * angularVelocity(rad/s) = Watts
    end
  end
  row[#row+1] = fmt(engTorque)
  row[#row+1] = fmt(engPowerKw)

  row[#row+1] = fmt(elec('watertemp') or elec('coolantTemp'))
  row[#row+1] = fmt(elec('oiltemp'))
  row[#row+1] = fmt(elec('fuel'))

  local dsDev = safe(getDriveshaftDevice)
  local dsBroken = dsDev and safe(function() return dsDev.isBroken end)
  row[#row+1] = fmt(dsBroken)

  row[#row+1] = fmt(elec('airspeed'))

  -- --- per-wheel data ---------------------------------------------------------
  for i = 0, wheelCount - 1 do
    local wd = wheels and wheels.wheels and wheels.wheels[i]

    local wSpeed  = wd and safe(function() return wd.wheelSpeed end)
    local wAngVel = wd and safe(function() return wd.angularVelocity end)
    local wSlip   = wd and (safe(function() return wd.slipEnergy end) or safe(function() return wd.lastSlip end))
    local wDown   = wd and (safe(function() return wd.downForceRaw end) or safe(function() return wd.downForce end))
    local wSusp   = wd and (safe(function() return wd.suspensionTravel end) or safe(function() return wd.travel end))
    local wContact= wd and safe(function() return wd.contactMaterialID1 end)
    local wPress  = wd and (safe(function() return wd.tirePressure end) or safe(function() return wd.groundModelPressure end))
    local wBrake  = wd and (safe(function() return wd.brakeSurfaceTemperature end)
                              or safe(function() return wd.brakeTemp end)
                              or safe(function() return wd.brakeCoreTemperature end))
    local wBroken = wd and safe(function() return wd.isBroken end)

    local wSuspVel = nil
    if wSusp then
      if prevSuspTravel[i] and dt > 0 then
        wSuspVel = (wSusp - prevSuspTravel[i]) / dt
      end
      prevSuspTravel[i] = wSusp
    end

    row[#row+1] = fmt(wSpeed)
    row[#row+1] = fmt(wAngVel)
    row[#row+1] = fmt(wSlip)
    row[#row+1] = fmt(wDown)
    row[#row+1] = fmt(wSusp)
    row[#row+1] = fmt(wSuspVel)
    row[#row+1] = fmt(wContact)
    row[#row+1] = fmt(wPress)
    row[#row+1] = fmt(wBrake)
    row[#row+1] = fmt(wBroken)
  end

  return row
end

local function writeRow(dt)
  if not logFile then return end
  local row = collectRow(dt)
  logFile:write(table.concat(row, ',') .. '\n')
  rowsSinceFlush = rowsSinceFlush + 1
  if rowsSinceFlush >= FLUSH_EVERY_ROWS then
    logFile:flush()
    rowsSinceFlush = 0
  end
end

-- ---------------------------------------------------------------------------
-- PUBLIC HOOKS (called automatically by the game / by the GE-side extension)
-- ---------------------------------------------------------------------------

-- Called automatically right after this extension is loaded (by the GE-side
-- extension, once per vehicle spawn). This is our entry point.
local function onExtensionLoaded()
  closeFile()      -- safety: close anything left open from a previous load
  openNewFile()
end

-- Called automatically by the game whenever the player resets the vehicle
-- (default key: I). We close the current file and start a brand-new one so
-- pre-reset and post-reset data never mix in a single file.
local function onReset()
  closeFile()
  openNewFile()
end

-- Also exposed so the GE-side extension can explicitly request a reset via
-- queueLuaCommand, as a redundant safety net.
local function onVehicleReset()
  onReset()
end

-- Called once per physics step. We accumulate dt and only emit a CSV row
-- once we've crossed the 1/100s threshold, giving a stable 100 Hz output
-- regardless of the underlying physics tick rate.
local function update(dt)
  if not isLogging or not dt or dt <= 0 then return end
  timeAcc = timeAcc + dt
  while timeAcc >= LOG_INTERVAL do
    timeAcc = timeAcc - LOG_INTERVAL
    writeRow(LOG_INTERVAL)
  end
end

-- Called automatically when this extension is unloaded (e.g. vehicle
-- deleted/despawned). Make sure the file is flushed and closed cleanly.
local function onExtensionUnloaded()
  closeFile()
end

-- Small debug helper: dump all currently-known electrics.values keys to the
-- console, so you can discover extra fields to add to this script.
local function listAvailableElectrics()
  if electrics and electrics.values then
    for k, v in pairs(electrics.values) do
      print(tostring(k) .. ' = ' .. tostring(v))
    end
  end
end

-- ---------------------------------------------------------------------------
-- PUBLIC INTERFACE
-- ---------------------------------------------------------------------------
M.onExtensionLoaded    = onExtensionLoaded
M.onExtensionUnloaded  = onExtensionUnloaded
M.reset                = onReset
M.onVehicleReset        = onVehicleReset
M.update                = update
M.listAvailableElectrics = listAvailableElectrics

return M
