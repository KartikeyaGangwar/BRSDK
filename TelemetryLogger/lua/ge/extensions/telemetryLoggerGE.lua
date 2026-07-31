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
-- ============================================================================

local M = {}

-- Tells one vehicle (by its GE vehicle id) to load the telemetry extension.
-- Loading an already-loaded extension again is safe -- onExtensionLoaded on
-- the vehicle side will simply close the old file and start a new one.
local function injectLogger(vehicleId)
  local veh = be:getObjectByID(vehicleId)
  if not veh then return end
  veh:queueLuaCommand("extensions.load('telemetryLogger')")
end

-- Fired by the game whenever a vehicle finishes spawning.
local function onVehicleSpawned(vehicleId)
  injectLogger(vehicleId)
end

-- Fired by the game whenever a vehicle is reset (e.g. player presses "I").
-- The vehicle-side extension already resets itself via its own `reset` hook,
-- this is just a redundant safety net in case that ever doesn't fire.
local function onVehicleResetted(vehicleId)
  local veh = be:getObjectByID(vehicleId)
  if not veh then return end
  veh:queueLuaCommand("if telemetryLogger and telemetryLogger.onVehicleReset then telemetryLogger.onVehicleReset() end")
end

-- On (re)load of this GE extension, make sure the output folder exists and
-- retroactively inject the logger into any vehicle that's already spawned
-- (useful if the mod gets enabled/reloaded mid-session).
local function onExtensionLoaded()
  pcall(function() FS:directoryCreate('/telemetry') end)

  if be and be.getObjectCount and be.getObject then
    local count = be:getObjectCount()
    for i = 0, count - 1 do
      local veh = be:getObject(i)
      if veh then
        injectLogger(veh:getID())
      end
    end
  end

  log('I', 'telemetryLoggerGE', 'Telemetry Logger GE-side extension loaded.')
end

M.onExtensionLoaded  = onExtensionLoaded
M.onVehicleSpawned   = onVehicleSpawned
M.onVehicleResetted  = onVehicleResetted

return M
