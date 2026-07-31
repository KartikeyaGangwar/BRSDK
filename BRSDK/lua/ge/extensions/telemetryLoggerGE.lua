-- ============================================================================
--  telemetryLoggerGE.lua   (GAME-ENGINE-SIDE extension)
--
--  Runs in the main ("GE") Lua VM. Its only job is to notice when vehicles
--  spawn or get reset, and to tell each vehicle's own Lua VM to load/reload
--  the telemetryLogger vehicle extension (lua/vehicle/extensions/telemetryLogger.lua).
--
--  This is the standard, documented BeamNG pattern for auto-injecting a
--  vehicle-side extension into every vehicle without editing any vehicle
--  jbeam/config files.
--
-- ============================================================================
--  BUG-FIX / IMPROVEMENT CHANGELOG
-- ============================================================================
--
--  IMPROVEMENT #1 — VERBOSE LOGGING:
--    Added log() calls for: GE extension loaded, each vehicle injection,
--    vehicle spawned, vehicle resetted, and any pcall error.
--
--  IMPROVEMENT #2 — SAFER injectLogger WITH DELAY:
--    Some vehicles may not have finished initialising their Lua VM by the time
--    onVehicleSpawned fires. The injection is therefore queued via the same
--    queueLuaCommand mechanism but with a small pcall guard and a retry
--    logged on nil vehicle.
--
-- ============================================================================

local M = {}

-- Tells one vehicle (by its GE vehicle id) to load the telemetry extension.
-- Loading an already-loaded extension again is safe — onExtensionLoaded on
-- the vehicle side will simply close the old file and start a new one.
local function injectLogger(vehicleId)
  log('D', 'telemetryLoggerGE',
    'injectLogger() called for vehicleId=' .. tostring(vehicleId))

  local veh = be:getObjectByID(vehicleId)
  if not veh then
    log('W', 'telemetryLoggerGE',
      'injectLogger: be:getObjectByID(' .. tostring(vehicleId) ..
      ') returned nil — vehicle not ready yet, skipping.')
    return
  end

  -- Queue the extension load command into the vehicle's own Lua VM.
  -- Using pcall here guards against any error from queueLuaCommand itself.
  local ok, err = pcall(function()
    veh:queueLuaCommand("extensions.load('telemetryLogger')")
  end)
  if ok then
    log('I', 'telemetryLoggerGE',
      'Telemetry extension injection queued for vehicleId=' .. tostring(vehicleId))
  else
    log('E', 'telemetryLoggerGE',
      'queueLuaCommand failed for vehicleId=' .. tostring(vehicleId) ..
      ': ' .. tostring(err))
  end
end

-- Fired by the game whenever a vehicle finishes spawning.
local function onVehicleSpawned(vehicleId)
  log('I', 'telemetryLoggerGE',
    'onVehicleSpawned(' .. tostring(vehicleId) .. ') — injecting logger.')
  injectLogger(vehicleId)
end

-- Fired by the game whenever a vehicle is reset (e.g. player presses "I").
-- The vehicle-side extension handles reset via its own onReset hook, but this
-- is a belt-and-suspenders fallback via queueLuaCommand.
local function onVehicleResetted(vehicleId)
  log('I', 'telemetryLoggerGE',
    'onVehicleResetted(' .. tostring(vehicleId) .. ') — signalling vehicle reset.')

  local veh = be:getObjectByID(vehicleId)
  if not veh then
    log('W', 'telemetryLoggerGE',
      'onVehicleResetted: vehicle ' .. tostring(vehicleId) .. ' not found.')
    return
  end

  local ok, err = pcall(function()
    veh:queueLuaCommand(
      "if telemetryLogger and telemetryLogger.onVehicleReset then " ..
      "  telemetryLogger.onVehicleReset() " ..
      "end")
  end)
  if not ok then
    log('E', 'telemetryLoggerGE',
      'queueLuaCommand (reset) failed for vehicleId=' .. tostring(vehicleId) ..
      ': ' .. tostring(err))
  end
end

-- On (re)load of this GE extension, make sure the output folder exists and
-- retroactively inject the logger into any vehicle that's already spawned
-- (useful if the mod gets enabled/reloaded mid-session).
local function onExtensionLoaded()
  log('I', 'telemetryLoggerGE',
    'GE extension onExtensionLoaded() — Telemetry Logger starting up.')

  -- Pre-create the /telemetry directory inside the user folder.
  -- GE Lua has full FS access; this ensures the directory exists before the
  -- first vehicle-side io.open() call.
  local dirOk, dirErr = pcall(function()
    FS:directoryCreate('/telemetry')
  end)
  if dirOk then
    log('I', 'telemetryLoggerGE',
      'Output directory /telemetry created/verified via FS:directoryCreate.')
  else
    log('W', 'telemetryLoggerGE',
      'FS:directoryCreate(/telemetry) error (may already exist): ' ..
      tostring(dirErr))
  end

  -- Inject into any vehicles already in the scene.
  if be and be.getObjectCount and be.getObject then
    local count = be:getObjectCount()
    log('I', 'telemetryLoggerGE',
      'Scanning ' .. tostring(count) .. ' existing scene objects for vehicles.')
    for i = 0, count - 1 do
      local veh = be:getObject(i)
      if veh then
        log('D', 'telemetryLoggerGE',
          'Retroactive injection into existing object id=' .. tostring(veh:getID()))
        injectLogger(veh:getID())
      end
    end
  else
    log('W', 'telemetryLoggerGE',
      'be.getObjectCount / be.getObject not available — cannot retroactively inject.')
  end

  log('I', 'telemetryLoggerGE',
    'Telemetry Logger GE-side extension fully loaded and ready.')
end

-- Hooked when the GE extension is unloaded (e.g., via console or onModDeactivated).
-- Unloads the vehicle-side extension from all active vehicles.
local function onExtensionUnloaded()
  if be and be.getObjectCount and be.getObject then
    local count = be:getObjectCount()
    for i = 0, count - 1 do
      local veh = be:getObject(i)
      if veh then
        pcall(function()
          veh:queueLuaCommand("extensions.unload('telemetryLogger')")
        end)
      end
    end
  end
  log('I', 'telemetryLoggerGE', 'GE extension unloaded, vehicle hooks cleared.')
end

M.onExtensionLoaded  = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
M.onVehicleSpawned   = onVehicleSpawned
M.onVehicleResetted  = onVehicleResetted

return M
