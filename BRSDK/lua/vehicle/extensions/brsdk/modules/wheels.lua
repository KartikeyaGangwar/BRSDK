-- ============================================================================
-- brsdk/modules/wheels.lua
--
-- Wheels domain module.
-- Owns speed, angular velocity, slip, downforce, contact, tire pressure, and brake thermals.
-- Does NOT own suspension or damage.
-- ============================================================================

local M = {}

M.info = {
  name = 'wheels',
  version = '1.0.0',
  api_version = '1',
  sdk_required = '1.0',
  stability = 'stable',
  author = 'BRSDK Team',
  sampling_rate = 'variable',
  category = 'wheels',
  provides = {'speed_mps', 'angular_velocity', 'slip', 'downforce_n', 'contact', 'tire_pressure', 'brake_temp_c'},
  depends = {'registry'},
  experimental = false,
  provenance = 'beamng_native',
  description = 'Core wheel telemetry (excluding suspension and damage).'
}

M.state = {} -- [wheelIndex] = { speed_mps = ..., ... }
local activeWheels = {} -- Cache of wheel references
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
    
    registry.add({name=p..'speed_mps', unit='m/s', datatype='float32', category='wheels', description='Wheel ground speed', provenance='beamng_native'}, function() return M.state[i] and M.state[i].speed_mps end)
    registry.add({name=p..'angular_velocity', unit='rad/s', datatype='float32', category='wheels', description='Wheel angular velocity', provenance='beamng_native'}, function() return M.state[i] and M.state[i].angular_velocity end)
    registry.add({name=p..'slip', unit='ratio', datatype='float32', category='wheels', description='Wheel slip energy', provenance='beamng_native'}, function() return M.state[i] and M.state[i].slip end)
    registry.add({name=p..'downforce_n', unit='N', datatype='float32', category='wheels', description='Wheel downforce (raw)', provenance='beamng_native'}, function() return M.state[i] and M.state[i].downforce_n end)
    registry.add({name=p..'contact', unit='id', datatype='int32', category='wheels', description='Ground contact material ID', provenance='beamng_native'}, function() return M.state[i] and M.state[i].contact end)
    registry.add({name=p..'tire_pressure', unit='Pa', datatype='float32', category='wheels', description='Tire pressure', provenance='beamng_native'}, function() return M.state[i] and M.state[i].tire_pressure end)
    registry.add({name=p..'brake_temp_c', unit='C', datatype='float32', category='wheels', description='Brake surface temperature', provenance='beamng_native'}, function() return M.state[i] and M.state[i].brake_temp_c end)
  end
end

function M.initialize()
  wheelCount = countWheels()
  activeWheels = {}
  M.state = {}
  
  for i = 0, wheelCount - 1 do
    activeWheels[i] = wheels.wheels[i]
    M.state[i] = {
      speed_mps = nil,
      angular_velocity = nil,
      slip = nil,
      downforce_n = nil,
      contact = nil,
      tire_pressure = nil,
      brake_temp_c = nil
    }
  end
end

function M.update()
  for i = 0, wheelCount - 1 do
    local wd = activeWheels[i]
    local st = M.state[i]
    if wd then
      st.speed_mps = s(function() return wd.wheelSpeed end)
      st.angular_velocity = s(function() return wd.angularVelocity end)
      st.slip = s(function() return wd.slipEnergy end) or s(function() return wd.lastSlip end)
      st.downforce_n = s(function() return wd.downForceRaw end) or s(function() return wd.downForce end)
      st.contact = s(function() return wd.contactMaterialID1 end)
      st.tire_pressure = s(function() return wd.tirePressure end) or s(function() return wd.groundModelPressure end)
      st.brake_temp_c = s(function() return wd.brakeSurfaceTemperature end) or s(function() return wd.brakeTemp end) or s(function() return wd.brakeCoreTemperature end)
    else
      st.speed_mps, st.angular_velocity, st.slip, st.downforce_n, st.contact, st.tire_pressure, st.brake_temp_c = nil, nil, nil, nil, nil, nil, nil
    end
  end
end

function M.shutdown()
  activeWheels = {}
  M.state = {}
  wheelCount = 0
end

function M.collect()
  return M.state
end

brsdk_modules_wheels = M
return M
