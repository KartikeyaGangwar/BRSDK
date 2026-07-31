-- ============================================================================
-- brsdk/modules/powertrain.lua
--
-- Powertrain domain module.
-- Owns gear, RPM, engine load, torque, and power.
-- ============================================================================

local M = {}

M.info = {
  name = 'powertrain',
  version = '1.0.0',
  api_version = '1',
  sdk_required = '1.0',
  stability = 'stable',
  author = 'BRSDK Team',
  sampling_rate = 'variable',
  category = 'powertrain',
  provides = {'gear', 'gear_index', 'rpm', 'engine_load', 'engine_torque_nm', 'engine_power_kw'},
  depends = {'registry'},
  experimental = false,
  provenance = 'beamng_native',
  description = 'Core engine and transmission telemetry.'
}

M.state = {
  gear = nil,
  gear_index = nil,
  rpm = nil,
  engine_load = nil,
  engine_torque_nm = nil,
  engine_power_kw = nil
}

local engDevCache = nil

local function s(fn, ...)
  local ok, res = pcall(fn, ...)
  if ok then return res end
  return nil
end

local function elec(name)
  if electrics and electrics.values then
    return electrics.values[name]
  end
  return nil
end

local function findEngineDevice()
  if not powertrain or not powertrain.getDevice then return nil end
  local dev = s(powertrain.getDevice, 'mainEngine')
  if dev then return dev end
  if powertrain.getDevices then
    local devs = s(powertrain.getDevices)
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

function M.registerSignals(registry)
  if not registry then return end
  
  registry.add({name='gear', unit='str', datatype='string', category='powertrain', description='Current gear name', provenance='beamng_native'}, function() return M.state.gear end)
  registry.add({name='gear_index', unit='idx', datatype='int32', category='powertrain', description='Current gear index', provenance='beamng_native'}, function() return M.state.gear_index end)
  registry.add({name='rpm', unit='rpm', datatype='float32', category='powertrain', description='Engine shaft RPM', provenance='beamng_native'}, function() return M.state.rpm end)
  registry.add({name='engine_load', unit='norm', datatype='float32', category='powertrain', description='Normalized engine load (0-1)', provenance='beamng_native'}, function() return M.state.engine_load end)
  registry.add({name='engine_torque_nm', unit='Nm', datatype='float32', category='powertrain', description='Engine output torque', provenance='beamng_native'}, function() return M.state.engine_torque_nm end)
  registry.add({name='engine_power_kw', unit='kW', datatype='float32', category='powertrain', description='Engine output power', provenance='computed'}, function() return M.state.engine_power_kw end)
end

function M.initialize()
  engDevCache = findEngineDevice()
  for k, _ in pairs(M.state) do
    M.state[k] = nil
  end
end

function M.update()
  local st = M.state
  
  st.gear = elec('gear')
  st.gear_index = elec('gearIndex')
  st.rpm = elec('rpm') or elec('rpmTacho') or elec('RPM')
  st.engine_load = elec('engineLoad')
  
  if engDevCache then
    local tq = s(function() return engDevCache.outputTorque1 end)
    local av = s(function() return engDevCache.outputAV1 end)
    
    st.engine_torque_nm = tq
    if tq and av then
      st.engine_power_kw = (tq * av) / 1000
    else
      st.engine_power_kw = nil
    end
  else
    st.engine_torque_nm = nil
    st.engine_power_kw = nil
  end
end

function M.shutdown()
  engDevCache = nil
end

function M.collect()
  return M.state
end

brsdk_modules_powertrain = M
return M
