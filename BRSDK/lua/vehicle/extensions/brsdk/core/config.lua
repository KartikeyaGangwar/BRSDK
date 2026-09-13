-- ============================================================================
--  brsdk/core/config.lua
--
--  Master configuration for the BeamNG Research SDK (BRSDK).
--  Edit values here to change SDK behaviour without touching any other file.
--
--  Accessible globally as: brsdkConfig
--
--  Phase 1b additions:
--    - SDK_VERSION, SCHEMA_VERSION, LOGGER_VERSION for dataset provenance.
-- ============================================================================

local M = {}

-- ----------------------------------------------------------------------------
-- VERSION IDENTIFIERS
--
-- These are written into every session.json so that a dataset can always be
-- traced back to the exact SDK build that produced it.
--
-- Increment rules:
--   SDK_VERSION    — semantic version of the whole SDK (major.minor.patch)
--   SCHEMA_VERSION — integer; bump whenever the CSV column layout changes
--                    (column added, removed, renamed, or reordered)
--   LOGGER_VERSION — semantic version of the logger module specifically
-- ----------------------------------------------------------------------------

M.SDK_VERSION    = '2.0.0'           -- overall SDK release
M.SCHEMA_VERSION = '2'               -- bumped: ang_vel columns renamed in 1a
M.LOGGER_VERSION = '2.0.0'           -- telemetryLogger.lua release

-- ----------------------------------------------------------------------------
-- LOGGER SETTINGS
-- ----------------------------------------------------------------------------

--- Target sample rate in Hz. The logger emits one CSV row per interval.
--- The effective maximum is min(LOG_HZ, fps) because updateGFX drives timing.
--- 100 Hz is the recommended default for most research applications.
M.LOG_HZ = 100

--- Derived sample interval in seconds. Computed from LOG_HZ.
--- Do NOT edit this directly — change LOG_HZ above.
M.LOG_INTERVAL = 1 / M.LOG_HZ

--- Rows accumulated between logFile:flush() calls.
--- Lower = more crash-durability, higher = better I/O throughput.
--- At 100 Hz, 50 rows = one flush every 0.5 s.
M.FLUSH_EVERY_ROWS = 50

--- Output directory for all telemetry files.
--- A leading '/' is relative to the BeamNG user folder:
---   Windows → Documents/BeamNG.drive/<version>/
M.OUTPUT_DIR = '/telemetry'

-- ----------------------------------------------------------------------------
-- DEVELOPER / DEBUG SETTINGS
-- ----------------------------------------------------------------------------

--- Emit extra log('D', ...) progress lines while logging.
M.VERBOSE = false

--- When VERBOSE is true, emit a progress line every N rows.
M.VERBOSE_EVERY_N_ROWS = 100

-- ----------------------------------------------------------------------------
-- FUTURE PHASE PLACEHOLDERS
-- Pre-declared so Phase 2+ modules can read config without adding new keys.
-- All set to disabled/false for Phase 1.
-- ----------------------------------------------------------------------------

M.EXPLORER = {
  ENABLED      = false,
  MAX_DEPTH    = 6,
  PROBE_FUNCS  = false,
  WRITE_SCHEMA = false,
}

M.PROFILER = {
  ENABLED      = false,
  DURATION_S   = 30,
  SAMPLE_HZ    = 50,
  WRITE_REPORT = false,
}

M.STREAM = {
  ENABLED  = false,
  HOST     = '127.0.0.1',
  PORT     = 4567,
  PROTOCOL = 'udp',
}

-- ----------------------------------------------------------------------------
-- GLOBAL REGISTRATION
-- ----------------------------------------------------------------------------
brsdkConfig = M

return M
