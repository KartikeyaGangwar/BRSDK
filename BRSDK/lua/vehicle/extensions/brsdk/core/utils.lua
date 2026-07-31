-- ============================================================================
--  brsdk/core/utils.lua
--
--  Shared utility functions for the BeamNG Research SDK (BRSDK).
--  Zero dependencies — this is the lowest layer of the SDK.
--
--  Accessible globally as: brsdkUtils
--
--  Phase 1b additions:
--    - jsonEncodeSafe(): safe JSON serialisation with built-in fallback.
-- ============================================================================

local M = {}

-- ----------------------------------------------------------------------------
-- SAFE CALL UTILITIES
-- ----------------------------------------------------------------------------

--- Calls fn(...) inside pcall.
--- Returns up to 3 return values on success, nil on error.
--- Use for reads where silent failure (empty CSV cell) is acceptable.
function M.safe(fn, ...)
  local ok, a, b, c = pcall(fn, ...)
  if ok then return a, b, c end
  return nil
end

--- Calls fn(...) inside pcall; logs a W-level warning on failure.
--- apiName: printed in the warning so the broken call is identifiable.
--- Returns up to 3 return values on success, nil on error.
function M.safeVerbose(apiName, fn, ...)
  local ok, a, b, c = pcall(fn, ...)
  if ok then return a, b, c end
  log('W', 'brsdk.utils',
    'API call failed [' .. tostring(apiName) .. ']: ' .. tostring(a))
  return nil
end

-- ----------------------------------------------------------------------------
-- CSV FORMATTING
-- ----------------------------------------------------------------------------

--- Formats any value as a CSV cell string.
---   nil / NaN / ±Inf  →  '' (empty cell, never crashes)
---   number             →  '%.6f'
---   boolean            →  '1' or '0'
---   string             →  commas, quotes, newlines stripped
---   other              →  tostring(), stripped
function M.fmt(v)
  if v == nil then
    return ''
  elseif type(v) == 'number' then
    if v ~= v then return '' end                          -- NaN
    if v == math.huge or v == -math.huge then return '' end
    return string.format('%.6f', v)
  elseif type(v) == 'boolean' then
    return v and '1' or '0'
  else
    return tostring(v):gsub('[,\r\n"]', ' ')
  end
end

-- ----------------------------------------------------------------------------
-- VEHICLE GLOBAL ACCESSORS
-- ----------------------------------------------------------------------------

--- Read one key from electrics.values without throwing.
--- Returns nil if the bus is not yet available.
function M.elec(name)
  if electrics and electrics.values then
    return electrics.values[name]
  end
  return nil
end

--- Try multiple key names in electrics.values; return first non-nil match.
--- Useful for keys that changed name across BeamNG versions.
--- Example: M.elecAny('watertemp', 'coolantTemp', 'water_temp')
function M.elecAny(...)
  if not electrics or not electrics.values then return nil end
  for i = 1, select('#', ...) do
    local v = electrics.values[select(i, ...)]
    if v ~= nil then return v end
  end
  return nil
end

-- ----------------------------------------------------------------------------
-- JSON SERIALISATION
-- ----------------------------------------------------------------------------

--- Serialise a table to a JSON object string.
---
--- Strategy (two-pass, most-to-least capable):
---   1. Try BeamNG's built-in jsonEncode() — handles nested tables correctly.
---   2. Fall back to a minimal hand-written serialiser that handles flat tables
---      containing strings, numbers, and booleans.  Nested tables in the
---      fallback path are rendered as their tostring() value.
---
--- This function never throws; on complete failure it returns '{}' plus a
--- log entry.
function M.jsonEncodeSafe(t)
  local ok, result = pcall(jsonEncode, t)
  if ok and type(result) == 'string' then return result end

  local function encode(val)
    local tv = type(val)
    if tv == 'string' then
      local s = val:gsub('\\', '\\\\')
                 :gsub('"',  '\\"')
                 :gsub('\r', '\\r')
                 :gsub('\n', '\\n')
                 :gsub('\t', '\\t')
      return '"' .. s .. '"'
    elseif tv == 'number' then
      if val ~= val or val == math.huge or val == -math.huge then
        return 'null'
      else
        return string.format('%.10g', val)
      end
    elseif tv == 'boolean' then
      return val and 'true' or 'false'
    elseif val == nil then
      return 'null'
    elseif tv == 'table' then
      local parts = {}
      -- Check if array
      local is_array = true
      local max_k = 0
      for k, _ in pairs(val) do
        if type(k) == 'number' and k > 0 and math.floor(k) == k then
          if k > max_k then max_k = k end
        else
          is_array = false
          break
        end
      end
      -- Lua tables might have holes, but for JSON array heuristics we check if contiguous
      local count = 0
      for _ in pairs(val) do count = count + 1 end
      if is_array and max_k == count then
        for i = 1, max_k do
          parts[#parts + 1] = encode(val[i])
        end
        return '[' .. table.concat(parts, ',') .. ']'
      else
        for k, v in pairs(val) do
          local k_str = '"' .. tostring(k):gsub('"', '\\"') .. '"'
          parts[#parts + 1] = k_str .. ':' .. encode(v)
        end
        return '{' .. table.concat(parts, ',') .. '}'
      end
    else
      return '"' .. tostring(val):gsub('"', '\\"') .. '"'
    end
  end

  local res = encode(t)
  if res == '{}' or res == '[]' then
    log('W', 'brsdk.utils', 'jsonEncodeSafe: empty table')
  end
  return res
end

-- ----------------------------------------------------------------------------
-- GLOBAL REGISTRATION
-- ----------------------------------------------------------------------------
brsdkUtils = M

return M
