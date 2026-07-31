-- ============================================================================
-- brsdk/core/migrationValidator.lua
--
-- Automatically compares old monolithic logic against new modular logic.
-- Reports differences larger than 1e-9 tolerance.
-- ============================================================================

local M = {}

local TOLERANCE = 1e-9

local mismatches = {}
local total_samples = 0
local failed_samples = 0

function M.validate(signalName, oldVal, newVal, frameNumber)
  total_samples = total_samples + 1
  
  if oldVal == newVal then return true end
  if type(oldVal) ~= type(newVal) then
    if not (oldVal == nil and newVal == '') and not (oldVal == '' and newVal == nil) then
      local err = string.format("Type mismatch: %s vs %s", type(oldVal), type(newVal))
      M.reportMismatch(signalName, oldVal, newVal, err, nil, frameNumber)
      return false
    end
  end
  
  if type(oldVal) == 'number' and type(newVal) == 'number' then
    local absErr = math.abs(oldVal - newVal)
    if absErr > TOLERANCE then
      local relErr = (oldVal ~= 0) and (absErr / math.abs(oldVal)) or absErr
      M.reportMismatch(signalName, oldVal, newVal, absErr, relErr, frameNumber)
      return false
    end
    return true
  end
  
  -- If strings or other types don't match
  if tostring(oldVal) ~= tostring(newVal) then
    M.reportMismatch(signalName, tostring(oldVal), tostring(newVal), "String mismatch", nil, frameNumber)
    return false
  end
  
  return true
end

function M.reportMismatch(signalName, oldVal, newVal, absErr, relErr, frameNumber)
  failed_samples = failed_samples + 1
  local errObj = {
    signal = signalName,
    old_value = oldVal,
    new_value = newVal,
    absolute_error = absErr,
    relative_error = relErr,
    frame_number = frameNumber
  }
  table.insert(mismatches, errObj)
  
  log('E', 'migrationValidator', string.format("FAIL %s | old=%s new=%s | absErr=%s | frame=%s", 
    signalName, tostring(oldVal), tostring(newVal), tostring(absErr), tostring(frameNumber)))
end

function M.exportReport(filePath)
  local report = {
    total_samples = total_samples,
    failed_samples = failed_samples,
    mismatches = mismatches
  }
  
  local jsonStr
  if type(jsonEncode) == 'function' then
    jsonStr = jsonEncode(report)
  elseif type(jsonEnc) == 'function' then
    jsonStr = jsonEnc(report)
  else
    jsonStr = "{ \"error\": \"JSON encode missing\" }"
  end
  
  local f = io.open(filePath, 'w')
  if f then
    f:write(jsonStr)
    f:close()
  end
end

brsdk_core_migrationValidator = M
return M
