-- ============================================================================
-- brsdk/modules/thermals.lua
--
-- Thermals domain module.
-- Owns engine coolant, oil temperatures, and fuel state.
-- ============================================================================

local M = {}

M.info = {
  name = 'thermals',
  version = '1.0.0',
  api_version = '1',
  sdk_required = '1.0',
  stability = 'stable',
  author = 'BRSDK Team',
  sampling_rate = 'variable',
  category = 'thermals',
  provides = {'coolant_temp_c', 'oil_temp_c', 'fuel_norm'},
  depends = {'registry'},
  experimental = false,
  provenance = 'beamng_native',
  description = 'Core engine thermals and fuel tracking.'
}

M.state = {
  coolant_temp_c = nil,
  oil_temp_c = nil,
  fuel_norm = nil
}

local function elec(name)
  if electrics and electrics.values then
    return electrics.values[name]
  end
  return nil
end

function M.registerSignals(registry)
  if not registry then return end
  
  registry.add({name='coolant_temp_c', unit='C', datatype='float32', category='thermals', description='Engine coolant temperature', provenance='beamng_native'}, function() return M.state.coolant_temp_c end)
  registry.add({name='oil_temp_c', unit='C', datatype='float32', category='thermals', description='Engine oil temperature', provenance='beamng_native'}, function() return M.state.oil_temp_c end)
  registry.add({name='fuel_norm', unit='norm', datatype='float32', category='thermals', description='Fuel tank level', provenance='beamng_native'}, function() return M.state.fuel_norm end)
end

function M.initialize()
  for k, _ in pairs(M.state) do
    M.state[k] = nil
  end
end

function M.update()
  local st = M.state
  st.coolant_temp_c = elec('watertemp') or elec('coolantTemp') or elec('water_temp')
  st.oil_temp_c = elec('oiltemp') or elec('oil_temp')
  st.fuel_norm = elec('fuel')
end

function M.shutdown()
  -- Cleanup
end

function M.collect()
  return M.state
end

brsdk_modules_thermals = M
return M
