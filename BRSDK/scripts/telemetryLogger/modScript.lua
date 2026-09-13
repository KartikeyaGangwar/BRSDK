-- ============================================================================
--  modScript.lua
--
--  Initialization entry point for the BRSDK Game Engine extension.
--  BeamNG automatically executes scripts/<modname>/modScript.lua when an
--  active mod mounts, bootstrapping the GameEngine-side lifecycle without
--  requiring manual console invocation.
--
--  The extension is configured with 'manual' unload mode to preserve state
--  across level and map transitions.
-- ============================================================================

extensions.load('telemetryLoggerGE')

if setExtensionUnloadMode then
  setExtensionUnloadMode('telemetryLoggerGE', 'manual')
end
