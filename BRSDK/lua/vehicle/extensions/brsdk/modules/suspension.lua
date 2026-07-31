-- ============================================================================
-- brsdk/modules/suspension.lua
--
-- Suspension domain module.
-- Owns suspension travel and derived velocity.
-- ============================================================================

local M = {}

M.info = {
  name = 'suspension',
  version = '1.0.0',
  api_version = '1',
  sdk_required = '1.0',
  stability = 'stable',
  author = 'BRSDK Team',
  sampling_rate = 'variable',
  category = 'suspension',
  provides = {'suspension_travel', 'suspension_velocity'},
  depends = {'registry'},
  experimental = false,
  provenance = 'beamng_native',
  description = 'Wheel suspension travel and velocity tracking.'
}

M.state = {}
M.metadata = {}

local activeWheels = {}
local prevSuspTravel = {}
local wheelCount = 0

local function s(fn)
  local ok, res = pcall(fn)
  if ok then return res end
  return nil
end

local function countWheels()
  if not wheels or not wheels.wheels then return 0 end
  local n = 0
  while wheels.wheels[n] ~= nil do n = n + 1 end
  return n
end

function M.registerSignals(registry)
  if not registry then return end
  local nWheels = countWheels()
  
  for i = 0, nWheels - 1 do
    local p = 'wheel' .. i .. '_'
    registry.add({name=p..'suspension_travel', unit='m', datatype='float32', category='suspension', description='Suspension travel distance', provenance='beamng_native'}, function() return M.state[i] and M.state[i].suspension_travel end)
    registry.add({name=p..'suspension_velocity', unit='m/s', datatype='float32', category='suspension', description='Suspension compression velocity', provenance='computed'}, function() return M.state[i] and M.state[i].suspension_velocity end)
  end
end

function M.initialize()
  wheelCount = countWheels()
  activeWheels = {}
  prevSuspTravel = {}
  M.state = {}
  M.metadata = {}
  
  for i = 0, wheelCount - 1 do
    activeWheels[i] = wheels.wheels[i]
    prevSuspTravel[i] = nil
    M.state[i] = {
      suspension_travel = nil,
      suspension_velocity = nil
    }
    M.metadata[i] = {
      travel_unit = "m",
      velocity_unit = "m/s",
      travel_reference = "wheels.wheels[i].suspensionTravel",
      velocity_method = "finite_difference"
    }
  end
end

function M.update(dtSim, elapsedSinceLastLog)
  elapsedSinceLastLog = elapsedSinceLastLog or 0
  for i = 0, wheelCount - 1 do
    local wd = activeWheels[i]
    local st = M.state[i]
    if wd then
      local wSusp = s(function() return wd.suspensionTravel end) or s(function() return wd.travel end)
      st.suspension_travel = wSusp
      
      local wSuspVel = nil
      if wSusp then
        if prevSuspTravel[i] and elapsedSinceLastLog > 0 then
          wSuspVel = (wSusp - prevSuspTravel[i]) / elapsedSinceLastLog
        end
        prevSuspTravel[i] = wSusp
      end
      st.suspension_velocity = wSuspVel
    else
      st.suspension_travel = nil
      st.suspension_velocity = nil
    end
  end
end

function M.shutdown()
  activeWheels = {}
  prevSuspTravel = {}
  M.state = {}
  M.metadata = {}
  wheelCount = 0
end

function M.collect()
  return M.state
end

brsdk_modules_suspension = M
return M
