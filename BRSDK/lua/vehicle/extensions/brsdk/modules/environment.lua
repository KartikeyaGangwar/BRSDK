-- ============================================================================
-- brsdk/modules/environment.lua
--
-- Environment domain module.
-- Owns environmental physics states (airspeed, etc).
-- ============================================================================

local M = {}

M.info = {
  name = 'environment',
  version = '1.0.0',
  api_version = '1',
  sdk_required = '1.0',
  stability = 'stable',
  author = 'BRSDK Team',
  sampling_rate = 'variable',
  category = 'environment',
  provides = {'airspeed_mps'},
  depends = {'registry'},
  experimental = false,
  provenance = 'beamng_native',
  description = 'Local environmental conditions and relative physics.'
}

M.state = {
  airspeed_mps = nil
}

function M.registerSignals(registry)
  if not registry then return end
  registry.add({name='airspeed_mps', unit='m/s', datatype='float32', category='environment', description='Vehicle airspeed', provenance='beamng_native'}, function() return M.state.airspeed_mps end)
end

function M.initialize()
  M.state.airspeed_mps = nil
end

function M.update()
  if electrics and electrics.values then
    M.state.airspeed_mps = electrics.values.airspeed
  else
    M.state.airspeed_mps = nil
  end
end

function M.shutdown()
  M.state.airspeed_mps = nil
end

function M.collect()
  return M.state
end

brsdk_modules_environment = M
return M
