-- ============================================================================
-- brsdk/modules/driverInputs.lua
--
-- Driver Inputs domain module.
-- Owns throttle, brake, steering, clutch, and parking brake values.
-- ============================================================================

local M = {}

M.info = {
  name = 'driverInputs',
  version = '1.0.0',
  author = 'BRSDK Team',
  sampling_rate = 'variable',
  category = 'driver_inputs',
  provides = {'throttle', 'throttle_input', 'brake', 'brake_input', 'steering', 'steering_input', 'clutch', 'clutch_input', 'parkingbrake'},
  depends = {'registry'},
  experimental = false,
  provenance = 'beamng_native',
  description = 'Core driver inputs tracking (throttle, brake, steering, clutch).'
}

M.state = {
  throttle = nil,
  throttle_input = nil,
  brake = nil,
  brake_input = nil,
  steering = nil,
  steering_input = nil,
  clutch = nil,
  clutch_input = nil,
  parkingbrake = nil
}

local function elec(name)
  if electrics and electrics.values then
    return electrics.values[name]
  end
  return nil
end

function M.registerSignals(registry)
  if not registry then return end
  
  registry.add({name='throttle', unit='norm', datatype='float32', category='driver_inputs', description='Actual throttle state', provenance='beamng_native'}, function() return M.state.throttle end)
  registry.add({name='throttle_input', unit='norm', datatype='float32', category='driver_inputs', description='Raw throttle input', provenance='beamng_native'}, function() return M.state.throttle_input end)
  
  registry.add({name='brake', unit='norm', datatype='float32', category='driver_inputs', description='Actual brake state', provenance='beamng_native'}, function() return M.state.brake end)
  registry.add({name='brake_input', unit='norm', datatype='float32', category='driver_inputs', description='Raw brake input', provenance='beamng_native'}, function() return M.state.brake_input end)
  
  registry.add({name='clutch', unit='norm', datatype='float32', category='driver_inputs', description='Actual clutch state', provenance='beamng_native'}, function() return M.state.clutch end)
  registry.add({name='clutch_input', unit='norm', datatype='float32', category='driver_inputs', description='Raw clutch input', provenance='beamng_native'}, function() return M.state.clutch_input end)
  
  registry.add({name='parkingbrake', unit='norm', datatype='float32', category='driver_inputs', description='Parking brake state', provenance='beamng_native'}, function() return M.state.parkingbrake end)
  
  registry.add({name='steering', unit='norm', datatype='float32', category='driver_inputs', description='Actual steering state', provenance='beamng_native'}, function() return M.state.steering end)
  registry.add({name='steering_input', unit='norm', datatype='float32', category='driver_inputs', description='Raw steering input', provenance='beamng_native'}, function() return M.state.steering_input end)
end

function M.initialize()
  for k, _ in pairs(M.state) do
    M.state[k] = nil
  end
end

function M.update()
  local st = M.state
  st.throttle = elec('throttle')
  st.throttle_input = elec('throttle_input')
  st.brake = elec('brake')
  st.brake_input = elec('brake_input')
  st.steering = elec('steering')
  st.steering_input = elec('steering_input')
  st.clutch = elec('clutch')
  st.clutch_input = elec('clutch_input')
  st.parkingbrake = elec('parkingbrake')
end

function M.shutdown()
  -- Cleanup
end

function M.collect()
  return M.state
end

brsdk_modules_driverInputs = M
return M
