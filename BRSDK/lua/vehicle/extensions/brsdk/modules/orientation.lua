-- ============================================================================
-- brsdk/modules/orientation.lua
--
-- Orientation domain module.
-- Owns yaw, pitch, roll, and angular velocity tracking.
-- ============================================================================

local M = {}

M.info = {
  name = 'orientation',
  version = '1.0.0',
  author = 'BRSDK Team',
  sampling_rate = 'variable',
  provides = {'yaw_deg', 'pitch_deg', 'roll_deg', 'ang_vel_roll_rads', 'ang_vel_pitch_rads', 'ang_vel_yaw_rads'},
  depends = {'registry'},
  experimental = false,
  provenance = 'beamng_native',
  description = 'Core orientation and angular velocity tracking.'
}

M.state = {
  yaw_deg = nil,
  pitch_deg = nil,
  roll_deg = nil,
  ang_vel_roll_rads = nil,
  ang_vel_pitch_rads = nil,
  ang_vel_yaw_rads = nil
}

-- 'rpy' | 'vec3' | 'none'
local angVelAPI = 'none'

local function s(fn)
  local ok, res = pcall(fn)
  if ok then return res end
  return nil
end

local function detectAngVelAPI()
  local ok1 = pcall(function()
    local r, p, y = obj:getRollPitchYawAngularVelocity()
  end)
  if ok1 then
    angVelAPI = 'rpy'
    log('I', 'brsdk.orientation', 'Angular velocity API: rpy')
    return
  end

  local ok2 = pcall(function()
    local av = obj:getAngularVelocity()
    if not av then error('returned nil') end
  end)
  if ok2 then
    angVelAPI = 'vec3'
    log('W', 'brsdk.orientation', 'Angular velocity API: vec3 fallback')
    return
  end

  angVelAPI = 'none'
  log('W', 'brsdk.orientation', 'Angular velocity API: none')
end

local function getOrientationDeg()
  local fwd = s(function() return obj:getDirectionVector() end)
  local up  = s(function() return obj:getDirectionVectorUp() end)
  if not fwd or not up then return nil, nil, nil end
  local yaw   = math.deg(math.atan2(fwd.x, fwd.y))
  local pitch = math.deg(math.asin(math.max(-1, math.min(1, fwd.z))))
  local right = fwd:cross(up)
  local roll  = math.deg(math.atan2(right.z, up.z))
  return yaw, pitch, roll
end

function M.registerSignals(registry)
  if not registry then return end
  
  registry.add({name='yaw_deg', unit='deg', datatype='float32', category='orientation', description='Yaw angle', provenance='computed'}, function() return M.state.yaw_deg end)
  registry.add({name='pitch_deg', unit='deg', datatype='float32', category='orientation', description='Pitch angle', provenance='computed'}, function() return M.state.pitch_deg end)
  registry.add({name='roll_deg', unit='deg', datatype='float32', category='orientation', description='Roll angle', provenance='computed'}, function() return M.state.roll_deg end)
  
  registry.add({name='ang_vel_roll_rads', unit='rad/s', datatype='float32', category='orientation', description='Roll angular velocity', provenance='beamng_native'}, function() return M.state.ang_vel_roll_rads end)
  registry.add({name='ang_vel_pitch_rads', unit='rad/s', datatype='float32', category='orientation', description='Pitch angular velocity', provenance='beamng_native'}, function() return M.state.ang_vel_pitch_rads end)
  registry.add({name='ang_vel_yaw_rads', unit='rad/s', datatype='float32', category='orientation', description='Yaw angular velocity', provenance='beamng_native'}, function() return M.state.ang_vel_yaw_rads end)
end

function M.initialize()
  detectAngVelAPI()
  for k, _ in pairs(M.state) do
    M.state[k] = nil
  end
end

function M.update()
  local st = M.state
  
  st.yaw_deg, st.pitch_deg, st.roll_deg = getOrientationDeg()
  
  if angVelAPI == 'rpy' then
    local ok, r, p, y = pcall(function() return obj:getRollPitchYawAngularVelocity() end)
    if ok then
      st.ang_vel_roll_rads, st.ang_vel_pitch_rads, st.ang_vel_yaw_rads = r, p, y
    else
      st.ang_vel_roll_rads, st.ang_vel_pitch_rads, st.ang_vel_yaw_rads = nil, nil, nil
    end
  elseif angVelAPI == 'vec3' then
    local av = s(function() return obj:getAngularVelocity() end)
    if av then
      st.ang_vel_roll_rads, st.ang_vel_pitch_rads, st.ang_vel_yaw_rads = av.x, av.y, av.z
    else
      st.ang_vel_roll_rads, st.ang_vel_pitch_rads, st.ang_vel_yaw_rads = nil, nil, nil
    end
  else
    st.ang_vel_roll_rads, st.ang_vel_pitch_rads, st.ang_vel_yaw_rads = nil, nil, nil
  end
end

function M.shutdown()
  -- Cleanup
end

function M.collect()
  return M.state
end

brsdk_modules_orientation = M
return M
