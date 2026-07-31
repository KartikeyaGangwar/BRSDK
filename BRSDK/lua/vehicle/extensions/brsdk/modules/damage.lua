-- ============================================================================
-- brsdk/modules/damage.lua
--
-- Damage domain module.
-- Owns driveshaft and wheel breakage states.
-- ============================================================================

local M = {}

M.info = {
  name = 'damage',
  version = '1.0.0',
  api_version = '1',
  sdk_required = '1.0',
  stability = 'stable',
  author = 'BRSDK Team',
  sampling_rate = 'variable',
  category = 'damage',
  provides = {'driveshaft_broken', 'wheel_broken'},
  depends = {'registry'},
  experimental = false,
  provenance = 'beamng_native',
  description = 'Core mechanical damage tracking.'
}

M.state = {
  driveshaft_broken = false,
  wheels = {} -- [wheelIndex] = { is_broken = false }
}

local dsDevCache = nil
local activeWheels = {}
local wheelCount = 0

local function s(fn, ...)
  local ok, res = pcall(fn, ...)
  if ok then return res end
  return nil
end

local function findDriveshaftDevice()
  if not powertrain or not powertrain.getDevice then return nil end
  return s(powertrain.getDevice, 'driveshaft')
end

local function countWheels()
  if not wheels or not wheels.wheels then return 0 end
  local n = 0
  while wheels.wheels[n] ~= nil do n = n + 1 end
  return n
end

function M.registerSignals(registry)
  if not registry then return end
  
  registry.add({name='driveshaft_broken', unit='bool', datatype='boolean', category='damage', description='Driveshaft physical integrity', provenance='beamng_native'}, function() return M.state.driveshaft_broken end)
  
  local nWheels = countWheels()
  for i = 0, nWheels - 1 do
    local p = 'wheel' .. i .. '_'
    registry.add({name=p..'broken', unit='bool', datatype='boolean', category='damage', description='Wheel physical integrity', provenance='beamng_native'}, function() return M.state.wheels[i] and M.state.wheels[i].is_broken end)
  end
end

function M.initialize()
  dsDevCache = findDriveshaftDevice()
  wheelCount = countWheels()
  activeWheels = {}
  
  M.state.driveshaft_broken = false
  M.state.wheels = {}
  
  for i = 0, wheelCount - 1 do
    activeWheels[i] = wheels.wheels[i]
    M.state.wheels[i] = { is_broken = false }
  end
end

function M.update()
  if dsDevCache then
    M.state.driveshaft_broken = s(function() return dsDevCache.isBroken end) or false
  else
    M.state.driveshaft_broken = false
  end
  
  for i = 0, wheelCount - 1 do
    local wd = activeWheels[i]
    if wd then
      M.state.wheels[i].is_broken = s(function() return wd.isBroken end)
    else
      M.state.wheels[i].is_broken = nil
    end
  end
end

function M.shutdown()
  dsDevCache = nil
  activeWheels = {}
  M.state.wheels = {}
  wheelCount = 0
end

function M.collect()
  return M.state
end

brsdk_modules_damage = M
return M
