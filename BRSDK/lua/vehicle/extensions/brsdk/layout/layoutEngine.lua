-- ============================================================================
-- brsdk/layout/layoutEngine.lua
--
-- Independent Signal Layout Engine for BRSDK.
-- Responsible for orchestrating signal ordering for various export formats.
-- Consumes Registry metadata and outputs ordered signal arrays.
-- ============================================================================

local M = {}

-- Define the hardcoded legacy CSV order to guarantee byte-for-byte identical output
local function buildLegacyCSVLayout(wheelCount)
  local cols = {
    'frame_id','graphics_frame','simulation_time','real_time','dt','elapsed_since_last_log',
    'pos_x','pos_y','pos_z',
    'vel_x','vel_y','vel_z','speed_mps','speed_kph',
    'acc_x','acc_y','acc_z',
    'gforce_x','gforce_y','gforce_z',
    'yaw_deg','pitch_deg','roll_deg',
    'ang_vel_roll_rads','ang_vel_pitch_rads','ang_vel_yaw_rads',
    'throttle','throttle_input',
    'brake','brake_input',
    'clutch','clutch_input',
    'parkingbrake',
    'steering','steering_input',
    'gear','gear_index',
    'rpm','engine_load','engine_torque_nm','engine_power_kw',
    'coolant_temp_c','oil_temp_c','fuel_norm',
    'driveshaft_broken','airspeed_mps',
  }
  
  if wheelCount then
    for i = 0, wheelCount - 1 do
      local p = 'wheel' .. i .. '_'
      for _, s in ipairs({
        'speed_mps', 'angular_velocity', 'slip', 'downforce_n',
        'suspension_travel', 'suspension_velocity', 'contact',
        'tire_pressure', 'brake_temp_c', 'broken'
      }) do
        cols[#cols+1] = p .. s
      end
    end
  end
  return cols
end

-- Default Layout: Alphabetical by category
local function buildResearchCSVLayout(registry)
  local signals = registry.getAll()
  table.sort(signals, function(a, b)
    if a.category == b.category then
      return a.name < b.name
    end
    return (a.category or "") < (b.category or "")
  end)
  local cols = {}
  for i = 1, #signals do
    cols[#cols+1] = signals[i].name
  end
  return cols
end

--- Get an ordered array of registry metadata objects for a specific layout
function M.getLayout(layoutName, registry, options)
  local orderedNames = {}
  options = options or {}
  
  if layoutName == 'legacy_csv' then
    orderedNames = buildLegacyCSVLayout(options.wheelCount)
  elseif layoutName == 'research_csv' then
    orderedNames = buildResearchCSVLayout(registry)
  else
    -- Fallback: registry insertion order
    local signals = registry.getAll()
    for i = 1, #signals do
      orderedNames[i] = signals[i].name
    end
  end
  
  local layout = {}
  for i = 1, #orderedNames do
    local sigName = orderedNames[i]
    local meta = registry.get(sigName)
    if meta then
      layout[#layout+1] = meta
    else
      -- If the registry does not contain the signal (e.g. module missing), push a placeholder
      layout[#layout+1] = { name = sigName, missing = true }
    end
  end
  
  return layout
end

return M
