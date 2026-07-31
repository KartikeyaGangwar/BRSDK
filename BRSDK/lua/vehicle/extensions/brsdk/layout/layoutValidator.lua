-- ============================================================================
-- brsdk/layout/layoutValidator.lua
--
-- Validates a generated layout against the Registry metadata.
-- ============================================================================

local M = {}

function M.validate(layout, registry)
  local report = {
    valid = true,
    total_columns = #layout,
    errors = {},
    warnings = {}
  }
  
  local layoutNames = {}
  local registryHas = {}
  
  -- Gather all registry signals
  local allSignals = registry.getAll()
  for i = 1, #allSignals do
    registryHas[allSignals[i].name] = true
  end
  
  -- Check layout
  for i = 1, #layout do
    local s = layout[i]
    local name = s.name
    
    -- Check duplicates in layout
    if layoutNames[name] then
      table.insert(report.errors, string.format("Column %d '%s': Duplicate signal in layout", i, name))
      report.valid = false
    end
    layoutNames[name] = true
    
    -- Check if signal exists in registry
    if s.missing or not registry.has(name) then
      table.insert(report.errors, string.format("Column %d '%s': Signal present in layout but missing from Registry", i, name))
      report.valid = false
    else
      -- Check deprecation
      local meta = registry.get(name)
      if meta.deprecated then
        table.insert(report.warnings, string.format("Column %d '%s': Signal is deprecated", i, name))
      end
    end
  end
  
  -- Check if registry has signals not in layout (layout mismatch / dropped signals)
  for name, _ in pairs(registryHas) do
    if not layoutNames[name] then
      table.insert(report.warnings, string.format("Registry signal '%s' is not included in this layout", name))
    end
  end
  
  return report
end

return M
