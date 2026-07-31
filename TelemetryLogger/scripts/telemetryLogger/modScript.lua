-- ============================================================================
--  modScript.lua
--
--  Auto-run entry point for the Telemetry Logger mod. BeamNG executes any
--  scripts/<modname>/modScript.lua found in an active mod automatically, so
--  this is what makes the whole thing "just work" the moment you enable the
--  mod -- no console commands needed.
--
--  We load the GE-side extension and mark it "manual" unload so it survives
--  level/map changes instead of being torn down every time you load a map.
-- ============================================================================

extensions.load('telemetryLoggerGE')

if setExtensionUnloadMode then
  setExtensionUnloadMode('telemetryLoggerGE', 'manual')
end
