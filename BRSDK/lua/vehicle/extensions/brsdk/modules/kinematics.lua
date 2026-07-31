-- ============================================================================
-- brsdk/modules/kinematics.lua
--
-- Kinematics domain module.
-- Owns position, velocity, acceleration, and time tracking.
-- ============================================================================

local M = {}

M.info = {
  name = 'kinematics',
  version = '1.0.0',
  author = 'BRSDK Team',
  sampling_rate = 'variable',
  provides = {'time', 'position', 'velocity', 'speed', 'acceleration', 'gforce'},
  depends = {'registry'},
  experimental = false,
  description = 'Core kinematics and time tracking for the telemetry dataset.'
}

-- Pre-allocated state to avoid GC allocations during update()
M.state = {
  frame_id = 0,
  graphics_frame = 0,
  simulation_time = 0,
  real_time = 0,
  dt = 0,
  elapsed_since_last_log = 0,
  
  pos_x = 0, pos_y = 0, pos_z = 0,
  vel_x = 0, vel_y = 0, vel_z = 0,
  speed_mps = 0, speed_kph = 0,
  
  acc_x = 0, acc_y = 0, acc_z = 0,
  gforce_x = 0, gforce_y = 0, gforce_z = 0
}

-- Internal tracking for finite difference
local prevVelocity = { x = 0, y = 0, z = 0 }

function M.registerSignals(registry)
  if not registry then return end
  
  local function reg(name, unit, datatype, desc, fn)
    registry.add({
      name = name,
      unit = unit,
      datatype = datatype,
      category = 'kinematics',
      description = desc,
      provenance = 'beamng_native'
    }, fn)
  end
  
  reg('frame_id', 'count', 'uint32', 'Dataset row index', function() return M.state.frame_id end)
  reg('graphics_frame', 'count', 'uint32', 'Engine frame counter', function() return M.state.graphics_frame end)
  reg('simulation_time', 's', 'float64', 'Simulation time', function() return M.state.simulation_time end)
  reg('real_time', 's', 'float64', 'Wall clock time', function() return M.state.real_time end)
  reg('dt', 's', 'float32', 'Delta time between graphics frames', function() return M.state.dt end)
  reg('elapsed_since_last_log', 's', 'float32', 'Time since last recorded sample', function() return M.state.elapsed_since_last_log end)
  
  reg('pos_x', 'm', 'float32', 'World X position', function() return M.state.pos_x end)
  reg('pos_y', 'm', 'float32', 'World Y position', function() return M.state.pos_y end)
  reg('pos_z', 'm', 'float32', 'World Z position', function() return M.state.pos_z end)
  
  reg('vel_x', 'm/s', 'float32', 'World X velocity', function() return M.state.vel_x end)
  reg('vel_y', 'm/s', 'float32', 'World Y velocity', function() return M.state.vel_y end)
  reg('vel_z', 'm/s', 'float32', 'World Z velocity', function() return M.state.vel_z end)
  
  registry.add({name='speed_mps', unit='m/s', datatype='float32', category='kinematics', description='Speed magnitude', provenance='computed'}, function() return M.state.speed_mps end)
  registry.add({name='speed_kph', unit='km/h', datatype='float32', category='kinematics', description='Speed magnitude', provenance='computed'}, function() return M.state.speed_kph end)
  
  registry.add({name='acc_x', unit='m/s^2', datatype='float32', category='kinematics', description='X acceleration', provenance='derived'}, function() return M.state.acc_x end)
  registry.add({name='acc_y', unit='m/s^2', datatype='float32', category='kinematics', description='Y acceleration', provenance='derived'}, function() return M.state.acc_y end)
  registry.add({name='acc_z', unit='m/s^2', datatype='float32', category='kinematics', description='Z acceleration', provenance='derived'}, function() return M.state.acc_z end)
  
  registry.add({name='gforce_x', unit='g', datatype='float32', category='kinematics', description='X G-Force', provenance='derived'}, function() return M.state.gforce_x end)
  registry.add({name='gforce_y', unit='g', datatype='float32', category='kinematics', description='Y G-Force', provenance='derived'}, function() return M.state.gforce_y end)
  registry.add({name='gforce_z', unit='g', datatype='float32', category='kinematics', description='Z G-Force', provenance='derived'}, function() return M.state.gforce_z end)
end

function M.initialize()
  prevVelocity.x, prevVelocity.y, prevVelocity.z = 0, 0, 0
  for k, _ in pairs(M.state) do
    M.state[k] = nil
  end
end

-- Safely call an object method
local function s(fn)
  local ok, res = pcall(fn)
  if ok then return res end
  return nil
end

function M.update(dt, elapsed, frameId, gfxFrame)
  local st = M.state
  
  st.frame_id = frameId
  st.graphics_frame = gfxFrame
  st.simulation_time = s(function() return obj:getSimTime() end)
  st.real_time = s(function() return os.clock() end)
  st.dt = dt
  st.elapsed_since_last_log = elapsed
  
  local pos = s(function() return obj:getPosition() end)
  if pos then
    st.pos_x, st.pos_y, st.pos_z = pos.x, pos.y, pos.z
  else
    st.pos_x, st.pos_y, st.pos_z = nil, nil, nil
  end
  
  local vel = s(function() return obj:getVelocity() end)
  if vel then
    st.vel_x, st.vel_y, st.vel_z = vel.x, vel.y, vel.z
    st.speed_mps = math.sqrt(vel.x^2 + vel.y^2 + vel.z^2)
    st.speed_kph = st.speed_mps * 3.6
  else
    st.vel_x, st.vel_y, st.vel_z, st.speed_mps, st.speed_kph = nil, nil, nil, nil, nil
  end
  
  if vel and prevVelocity and elapsed and elapsed > 0 then
    st.acc_x = (vel.x - prevVelocity.x) / elapsed
    st.acc_y = (vel.y - prevVelocity.y) / elapsed
    st.acc_z = (vel.z - prevVelocity.z) / elapsed
    st.gforce_x = st.acc_x / 9.81
    st.gforce_y = st.acc_y / 9.81
    st.gforce_z = st.acc_z / 9.81
  else
    st.acc_x, st.acc_y, st.acc_z, st.gforce_x, st.gforce_y, st.gforce_z = nil, nil, nil, nil, nil, nil
  end
  
  if vel then
    prevVelocity.x, prevVelocity.y, prevVelocity.z = vel.x, vel.y, vel.z
  end
end

function M.shutdown()
  -- Cleanup
end

function M.collect()
  return M.state
end

brsdk_modules_kinematics = M
return M
