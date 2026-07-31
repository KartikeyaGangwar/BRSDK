-- ============================================================================
--  brsdk/core/registry.lua
--
--  Central column registry for the BeamNG Research SDK (BRSDK).
--
--  The registry stores an ordered list of column definitions. Each entry
--  describes one CSV column: its name and (in Phase 1b+) the function used
--  to read its value. The logger iterates this list to produce the CSV header
--  and (in later phases) to collect row data.
--
--  Phase 1a scope:
--    - Stores column names in insertion order.
--    - fn field is nil for all entries (populated by Explorer in Phase 1b).
--    - The logger still uses hardcoded reads in collectRow(); the registry
--      is used only to generate the CSV header row.
--
--  Phase 1b+ scope:
--    - Explorer populates fn for every discovered variable.
--    - collectRow() becomes registry-driven (no hardcoded reads).
--
--  Loaded by telemetryLogger.lua via:
--    extensions.load('brsdk/core/registry')
--  Then accessible globally as:
--    brsdkRegistry
-- ============================================================================

local M = {}

-- Internal ordered list of entries.
-- Each entry is a table: { name=string, fn=function|nil, index=integer }
-- Internal ordered list of entries.
local entries = {}
-- Name → entry index for O(1) existence checks.
local nameIndex = {}

-- Helper to create a shallow read-only copy
local function copy(t)
  if type(t) ~= 'table' then return t end
  local res = {}
  for k, v in pairs(t) do res[k] = v end
  return res
end

-- ----------------------------------------------------------------------------
-- WRITE API
-- ----------------------------------------------------------------------------

--- Add a column to the registry.
--- Supports legacy string API: M.add("speed", fn)
--- And new metadata object API: M.add({name="speed", unit="m/s", ...})
function M.add(signal, fn)
  local obj = {}
  if type(signal) == 'string' then
    obj.name = signal
    obj.fn = fn
  elseif type(signal) == 'table' then
    obj = copy(signal)
    if fn and not obj.fn then obj.fn = fn end
  else
    log('E', 'brsdk.registry', 'Invalid signal type passed to add()')
    return false
  end

  if not obj.name then
    log('E', 'brsdk.registry', 'Signal missing required field: name')
    return false
  end

  if nameIndex[obj.name] then
    log('D', 'brsdk.registry', 'Column already registered, skipping: ' .. tostring(obj.name))
    return false
  end

  -- Default metadata fields
  obj.display_name = obj.display_name or obj.name
  obj.description = obj.description or 'No description'
  obj.unit = obj.unit or 'unknown'
  obj.datatype = obj.datatype or 'float32'
  obj.category = obj.category or 'uncategorized'
  obj.api_source = obj.api_source or 'unknown'
  obj.api_path = obj.api_path or 'unknown'
  obj.physical_meaning = obj.physical_meaning or 'unknown'
  obj.formula = obj.formula or 'unknown'
  obj.sampling_rate = obj.sampling_rate or 'unknown'
  if obj.default_enabled == nil then obj.default_enabled = true end
  if obj.nullable == nil then obj.nullable = true end
  if obj.export_csv == nil then obj.export_csv = true end
  if obj.export_json == nil then obj.export_json = true end
  if obj.export_binary == nil then obj.export_binary = true end
  obj.python_dtype = obj.python_dtype or 'float32'
  obj.arrow_dtype = obj.arrow_dtype or 'float32'
  obj.ros_type = obj.ros_type or 'std_msgs/Float32'
  obj.version_added = obj.version_added or '1.0'
  obj.deprecated = obj.deprecated or false
  obj.tags = obj.tags or {}

  obj.index = #entries + 1

  entries[#entries + 1] = obj
  nameIndex[obj.name] = obj
  return true
end

function M.remove(name)
  local entry = nameIndex[name]
  if not entry then return false end
  nameIndex[name] = nil
  -- We don't remove from the array to avoid shifting indices, we just mark it removed
  -- Actually, rebuilding the array is safer if we want indices to remain contiguous
  local newEntries = {}
  for i = 1, #entries do
    if entries[i].name ~= name then
      local e = entries[i]
      e.index = #newEntries + 1
      newEntries[#newEntries + 1] = e
    end
  end
  entries = newEntries
  return true
end

function M.clear()
  entries   = {}
  nameIndex = {}
end

function M.setFn(name, fn)
  local entry = nameIndex[name]
  if not entry then return false end
  entry.fn = fn
  return true
end

-- ----------------------------------------------------------------------------
-- READ API
-- ----------------------------------------------------------------------------

function M.getNames()
  return M.getCSVColumns()
end

function M.getCSVColumns()
  local names = {}
  for i = 1, #entries do
    if entries[i].export_csv then
      names[#names + 1] = entries[i].name
    end
  end
  return names
end

function M.count()
  return #entries
end

function M.get(name)
  local entry = nameIndex[name]
  if entry then return copy(entry) end
  return nil
end

function M.getAll()
  local res = {}
  for i = 1, #entries do
    res[i] = copy(entries[i])
  end
  return res
end

function M.getSchema()
  return M.getAll()
end

function M.getEnabledSignals()
  local res = {}
  for i = 1, #entries do
    if entries[i].default_enabled then
      res[#res + 1] = copy(entries[i])
    end
  end
  return res
end

function M.iterate(fn)
  for i = 1, #entries do
    fn(copy(entries[i]))
  end
end

function M.has(name)
  return nameIndex[name] ~= nil
end

function M.collectRow()
  local row = {}
  local rIdx = 1
  for i = 1, #entries do
    local entry = entries[i]
    if entry.export_csv then
      if entry.fn then
        local ok, val = pcall(entry.fn)
        if ok then
          if brsdkUtils then
            row[rIdx] = brsdkUtils.fmt(val)
          else
            row[rIdx] = val == nil and '' or tostring(val)
          end
        else
          row[rIdx] = ''
        end
      else
        row[rIdx] = ''
      end
      rIdx = rIdx + 1
    end
  end
  return row
end

-- ----------------------------------------------------------------------------
-- VALIDATION
-- ----------------------------------------------------------------------------

function M.validate()
  local errors = {}
  local indices = {}
  local names = {}
  
  for i = 1, #entries do
    local e = entries[i]
    if not e.name then table.insert(errors, "Missing name at array index " .. tostring(i)) end
    if e.name then
      if names[e.name] then table.insert(errors, e.name .. ": Duplicate name") end
      names[e.name] = true
    end
    
    if indices[e.index] then table.insert(errors, (e.name or "?") .. ": Duplicate index " .. tostring(e.index)) end
    indices[e.index] = true
    
    if not e.unit or e.unit == 'unknown' then table.insert(errors, (e.name or "?") .. ": Missing unit") end
    if not e.datatype or e.datatype == 'unknown' then table.insert(errors, (e.name or "?") .. ": Missing datatype") end
    if not e.category or e.category == 'unknown' or e.category == 'uncategorized' then table.insert(errors, (e.name or "?") .. ": Invalid category") end
    if not e.description or e.description == 'No description' then table.insert(errors, (e.name or "?") .. ": Missing description") end
    if not e.api_source or e.api_source == 'unknown' then table.insert(errors, (e.name or "?") .. ": Missing API source") end
    if not e.version_added or e.version_added == 'unknown' then table.insert(errors, (e.name or "?") .. ": Invalid version") end
  end
  
  if #errors > 0 then
    for _, err in ipairs(errors) do
      log('W', 'brsdk.registry.validation', err)
    end
    return false, errors
  end
  return true, nil
end

-- Exports have been moved to schema/schemaGenerator.lua, schema/schemaMarkdown.lua

-- ----------------------------------------------------------------------------
-- DEBUG / INSPECTION
-- ----------------------------------------------------------------------------

function M.dump()
  log('I', 'brsdk.registry', 'Registry contains ' .. tostring(#entries) .. ' columns:')
  for i = 1, #entries do
    local e = entries[i]
    log('D', 'brsdk.registry', string.format('  [%03d] %-40s fn=%s cat=%s unit=%s', e.index, e.name, e.fn and 'set' or 'nil', e.category, e.unit))
  end
end

-- ----------------------------------------------------------------------------
-- GLOBAL REGISTRATION
-- ----------------------------------------------------------------------------
brsdkRegistry = M

return M
