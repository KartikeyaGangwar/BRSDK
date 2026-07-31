-- ============================================================================
--  brsdk/modules/metadata.lua
--
--  Extracts all available scientific metadata for the session.json sidecar.
-- ============================================================================

local M = {}

local function safe(fn, ...)
  local ok, res = pcall(fn, ...)
  if ok then return res end
  return nil
end

local function getPowertrainInfo()
  if not powertrain or not powertrain.getDevices then
    return 'unknown', 'unknown', 'unknown', 'unknown'
  end
  local devs = safe(powertrain.getDevices)
  if not devs then
    return 'unknown', 'unknown', 'unknown', 'unknown'
  end

  local engineType = 'unknown'
  local gearboxType = 'unknown'
  local drivetrain = 'unknown'
  local fuel = 'unknown'

  for _, d in pairs(devs) do
    if d.type then
      local t = tostring(d.type):lower()
      if t:find('engine') or t:find('motor') then
        engineType = d.type
      elseif t:find('gearbox') then
        gearboxType = d.type
      elseif t == 'fueltank' or t == 'energystorage' then
        fuel = d.energyType or d.type
      end
    end
  end

  -- Drivetrain guessing (simplified)
  local info = v.data and v.data.information
  if info and info.drivetrain then
    drivetrain = info.drivetrain
  end

  return engineType, gearboxType, drivetrain, fuel
end

local function getWheelRadius()
  if not wheels or not wheels.wheels then return 'unknown' end
  local sum = 0
  local count = 0
  for i=0, 10 do
    local wd = wheels.wheels[i]
    if wd and wd.radius then
      sum = sum + wd.radius
      count = count + 1
    end
  end
  if count > 0 then return sum / count end
  return 'unknown'
end

function M.build()
  local info = v.data and v.data.information or {}
  local eng, gb, dt, f = getPowertrainInfo()

  return {
    -- Vehicle
    vehicle_name        = info.name or safe(function() return v.data.vehicleName end) or 'unknown',
    vehicle_id          = tostring(safe(function() return obj:getID() end) or 'unknown'),
    vehicle_config      = tostring(safe(function() return v.config.partConfigFilename end) or safe(function() return v.config.mainPartName end) or 'unknown'),
    vehicle_type        = info.type or 'unknown',
    vehicle_mass        = safe(function() return obj:getMass() end) or 'unavailable_from_vehicle_lua',
    cg_position         = safe(function() local cg = obj:getCenterOfGravity(); return {x=cg.x, y=cg.y, z=cg.z} end) or 'unavailable_from_vehicle_lua',
    wheelbase           = info.wheelbase or 'unavailable_from_vehicle_lua',
    track_width         = info.trackWidth or 'unavailable_from_vehicle_lua',
    vehicle_dimensions  = info.dimensions or 'unavailable_from_vehicle_lua',
    wheel_radius        = getWheelRadius(),
    drivetrain_type     = dt,
    engine_type         = eng,
    gearbox_type        = gb,
    fuel_type           = f,
    jbeam_information   = info,

    -- Simulation
    beamng_version      = 'unavailable_from_vehicle_lua',
    beamng_build        = 'unavailable_from_vehicle_lua',
    sdk_version         = (brsdkConfig and brsdkConfig.SDK_VERSION) or 'unknown',
    logger_version      = (brsdkConfig and brsdkConfig.LOGGER_VERSION) or 'unknown',
    schema_version      = (brsdkConfig and brsdkConfig.SCHEMA_VERSION) or 'unknown',
    map_name            = 'unavailable_from_vehicle_lua',
    weather             = 'unavailable_from_vehicle_lua',
    gravity             = safe(function() return obj:getGravity() end) or 'unavailable_from_vehicle_lua',
    physics_rate        = 2000, -- BeamNG physics rate is fixed at 2000Hz
    graphics_rate       = 'unavailable_from_vehicle_lua',
    coordinate_system   = {
      up = "+Z",
      forward = "-Y",
      left = "+X",
      rotation_order = "intrinsic_XZY"
    },

    -- Dataset
    dataset_uuid        = 'unavailable_from_vehicle_lua',
    dataset_version     = "1.0",
    creation_timestamp  = safe(function() return os.time() end) or 0,
    creation_iso        = safe(function() return os.date('%Y-%m-%dT%H:%M:%S') end) or 'unknown',
    git_commit          = 'unavailable_from_vehicle_lua',
    generator           = 'BRSDK',
    platform            = 'unavailable_from_vehicle_lua',
    operating_system    = 'unavailable_from_vehicle_lua',
    lua_vm              = 'Vehicle',
  }
end

brsdk_modules_metadata = M
return M
