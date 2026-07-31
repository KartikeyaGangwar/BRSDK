-- ============================================================================
--  telemetryLogger.lua   (VEHICLE-SIDE extension)
--  BeamNG Research SDK — v1.0.0
--
--  Writes one CSV row per sample at ~100 Hz, plus a session.json sidecar.
--  Loaded into each vehicle's Lua VM by telemetryLoggerGE.lua.
--  Pure orchestrator. Zero physics extraction.
-- ============================================================================

local M = {}

M.dependencies = {
  'brsdk/core/utils',
  'brsdk/core/config',
  'brsdk/core/registry',
  'brsdk/modules/metadata',
  'brsdk/modules/kinematics',
  'brsdk/modules/orientation',
  'brsdk/modules/driverInputs',
  'brsdk/modules/thermals',
  'brsdk/modules/powertrain',
  'brsdk/modules/wheels',
  'brsdk/modules/suspension',
  'brsdk/modules/damage',
  'brsdk/modules/environment'
}

local _utils    = nil
local _cfg      = nil
local _registry = nil
local _metadata = nil
local _kinematics = nil
local _orientation = nil
local _driverInputs = nil
local _thermals = nil
local _powertrain = nil
local _wheels = nil
local _suspension = nil
local _damage = nil
local _environment = nil

local function resolveCoreRefs()
  _utils    = brsdkUtils
  _cfg      = brsdkConfig
  _registry = brsdkRegistry
  _metadata = brsdk_modules_metadata
  _kinematics = brsdk_modules_kinematics
  _orientation = brsdk_modules_orientation
  _driverInputs = brsdk_modules_driverInputs
  _thermals = brsdk_modules_thermals
  _powertrain = brsdk_modules_powertrain
  _wheels = brsdk_modules_wheels
  _suspension = brsdk_modules_suspension
  _damage = brsdk_modules_damage
  _environment = brsdk_modules_environment
end

local safe, fmt, jsonEnc

local function resolveHelpers()
  safe        = (_utils and _utils.safe)           or function(fn, ...) local ok, res = pcall(fn, ...); if ok then return res end end
  fmt         = (_utils and _utils.fmt)            or function(v) return v == nil and '' or tostring(v) end
  jsonEnc     = (_utils and _utils.jsonEncodeSafe) or function(t) return '{}' end
end

local LOG_HZ, LOG_INTERVAL, FLUSH_EVERY_ROWS, OUTPUT_DIR

local function initConfig()
  LOG_HZ           = (_cfg and _cfg.LOG_HZ)           or 100
  LOG_INTERVAL     = (_cfg and _cfg.LOG_INTERVAL)      or 0.01
  FLUSH_EVERY_ROWS = (_cfg and _cfg.FLUSH_EVERY_ROWS)  or 50
  OUTPUT_DIR       = (_cfg and _cfg.OUTPUT_DIR)        or '/telemetry'
end

local logFile          = nil
local logFilePath      = nil
local sessionJsonPath  = nil
local timeAcc          = 0
local rowsSinceFlush   = 0
local sessionStartTime = 0
local headerWritten    = false
local isLogging        = false
local wheelCount       = 0

local totalRowsWritten    = 0
local updateCallCount     = 0
local firstUpdateLogged   = false
local firstRowLogged      = false
local elapsedSinceLastLog = 0

local rowBuf  = {}
local rowBufN = 0

local function rowPush(s)
  rowBufN = rowBufN + 1
  rowBuf[rowBufN] = s
end

local layoutFns = {}

local function countWheels()
  if not wheels or not wheels.wheels then return 0 end
  local n = 0
  while wheels.wheels[n] ~= nil do n = n + 1 end
  return n
end

local function writeSessionJson(meta)
  if not sessionJsonPath then return end
  local jsonStr = jsonEnc(meta)
  local f, err = io.open(sessionJsonPath, 'w')
  if not f then
    local fsOk = pcall(function() f = FS:openFile(sessionJsonPath, 'w') end)
    if not fsOk or not f then return end
  end
  pcall(function() f:write(jsonStr) end)
  pcall(function() f:close() end)
end

local function openNewFile()
  pcall(function() FS:directoryCreate(OUTPUT_DIR) end)
  local stamp = safe(function() return os.date('%Y%m%d_%H%M%S') end) or tostring(safe(function() return os.time() end) or 0)
  local vehId = tostring(safe(function() return obj:getID() end) or 'unknown')

  logFilePath    = OUTPUT_DIR .. '/telemetry_'     .. vehId .. '_' .. stamp .. '.csv'
  sessionJsonPath= OUTPUT_DIR .. '/telemetry_'     .. vehId .. '_' .. stamp .. '_session.json'

  local file, ioErr = nil, nil
  pcall(function()
    local f, e = io.open(logFilePath, 'w')
    file = f ; ioErr = e
  end)

  if not file then
    pcall(function() file = FS:openFile(logFilePath, 'w') end)
    if not file then
      isLogging = false
      return
    end
  end

  logFile    = file
  wheelCount = countWheels()

  if _kinematics then _kinematics.initialize() end
  if _orientation then _orientation.initialize() end
  if _driverInputs then _driverInputs.initialize() end
  if _thermals then _thermals.initialize() end
  if _powertrain then _powertrain.initialize() end
  if _wheels then _wheels.initialize() end
  if _suspension then _suspension.initialize() end
  if _damage then _damage.initialize() end
  if _environment then _environment.initialize() end

  if _registry then
    _registry.clear()
    if _kinematics then _kinematics.registerSignals(_registry) end
    if _orientation then _orientation.registerSignals(_registry) end
    if _driverInputs then _driverInputs.registerSignals(_registry) end
    if _powertrain then _powertrain.registerSignals(_registry) end
    if _thermals then _thermals.registerSignals(_registry) end
    if _damage then _damage.registerSignals(_registry) end
    if _environment then _environment.registerSignals(_registry) end
    if _wheels then _wheels.registerSignals(_registry) end
    if _suspension then _suspension.registerSignals(_registry) end
    
    local layoutEngine = require('brsdk/layout/layoutEngine')
    local layout = layoutEngine.getLayout('legacy_csv', _registry, {wheelCount = wheelCount})
    
    layoutFns = {}
    local headerCols = {}
    for i = 1, #layout do
      headerCols[i] = layout[i].name
      layoutFns[i] = layout[i].fn or function() return nil end
    end
    
    local header = table.concat(headerCols, ',') .. '\n'
    local hOk = pcall(function() logFile:write(header) end)
    if not hOk then
      pcall(function() logFile:close() end)
      logFile = nil ; isLogging = false
      return
    end
    pcall(function() logFile:flush() end)
  end

  headerWritten       = true
  rowsSinceFlush      = 0
  timeAcc             = 0
  elapsedSinceLastLog = 0
  sessionStartTime    = 0
  isLogging           = true
  totalRowsWritten    = 0
  firstRowLogged      = false

  local meta = {}
  if _metadata then
    meta = _metadata.build()
    meta.csv_file = logFilePath
    meta.session_json_file = sessionJsonPath
    meta.wheel_count = wheelCount
    meta.log_hz = LOG_HZ
    meta.log_interval_s = LOG_INTERVAL
    meta.flush_every_rows = FLUSH_EVERY_ROWS
    meta.output_dir = OUTPUT_DIR
  end
  writeSessionJson(meta)
end

local function closeFile()
  if logFile then
    pcall(function() logFile:flush() end)
    pcall(function() logFile:close() end)
  end
  logFile        = nil
  headerWritten  = false
  isLogging      = false
end

local function collectRow(dt, elapsedSinceLastLog)
  rowBufN = 0

  if _kinematics then _kinematics.update(dt, elapsedSinceLastLog, totalRowsWritten + 1, updateCallCount) end
  if _orientation then _orientation.update() end
  if _driverInputs then _driverInputs.update() end
  if _thermals then _thermals.update() end
  if _powertrain then _powertrain.update() end
  if _wheels then _wheels.update() end
  if _suspension then _suspension.update(dt, elapsedSinceLastLog) end
  if _damage then _damage.update() end
  if _environment then _environment.update() end

  for i = 1, #layoutFns do
    local ok, val = pcall(layoutFns[i])
    if ok then
      rowPush(fmt(val))
    else
      rowPush('')
    end
  end

  local storedSize = #rowBuf
  for i = rowBufN + 1, storedSize do rowBuf[i] = nil end
  return rowBuf
end

local function writeRow(dt, elapsedSinceLastLog)
  if not logFile then return end
  local ok, result = pcall(collectRow, dt, elapsedSinceLastLog)
  if not ok then return end

  local wOk, wErr = pcall(function()
    logFile:write(table.concat(rowBuf, ',', 1, rowBufN) .. '\n')
  end)
  if not wOk then
    isLogging = false
    return
  end

  totalRowsWritten = totalRowsWritten + 1
  rowsSinceFlush   = rowsSinceFlush + 1

  if not firstRowLogged then firstRowLogged = true end

  if rowsSinceFlush >= FLUSH_EVERY_ROWS then
    pcall(function() logFile:flush() end)
    rowsSinceFlush = 0
  end
end

local function onExtensionLoaded()
  resolveCoreRefs()
  initConfig()
  resolveHelpers()
  closeFile()
  openNewFile()
end

local function updateGFX(dt)
  if not firstUpdateLogged then firstUpdateLogged = true end
  updateCallCount = updateCallCount + 1
  if not isLogging or not dt or dt <= 0 then return end
  
  timeAcc = timeAcc + dt
  elapsedSinceLastLog = elapsedSinceLastLog + dt
  
  if timeAcc >= LOG_INTERVAL then
    writeRow(dt, elapsedSinceLastLog)
    timeAcc = timeAcc % LOG_INTERVAL
    elapsedSinceLastLog = 0
  end
end

local function onReset()
  closeFile()
  openNewFile()
  firstUpdateLogged = false
  updateCallCount   = 0
end

local function onVehicleReset()
  onReset()
end

local function onExtensionUnloaded()
  closeFile()
end

M.onExtensionLoaded     = onExtensionLoaded
M.onExtensionUnloaded   = onExtensionUnloaded
M.updateGFX             = updateGFX
M.onReset               = onReset
M.onVehicleReset        = onVehicleReset

return M
