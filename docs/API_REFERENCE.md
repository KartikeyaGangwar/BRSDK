# Internal API Reference

BRSDK's core internal API revolves around the `Registry` and `Modules`. This reference is intended for researchers looking to extend BRSDK with custom telemetry extraction.

## The Registry (`brsdkRegistry`)
The registry is accessible globally across the vehicle VM.

### `brsdkRegistry.add(metadata, getter_fn)`
Registers a new signal with the logger.
- **`metadata`**: A table containing `name` (required), `unit`, `datatype`, `category`, and `description`.
- **`getter_fn`**: A parameter-less closure that returns the scalar value of the signal. The logger executes this every frame.

## Modules
Any module placed in `brsdk/modules/` should export the following lifecycle hooks:

### `M.initialize()`
Called once when the vehicle spawns or resets. Pre-allocate all state tables here.

### `M.registerSignals(registry)`
Called immediately after `initialize()`. Use this to invoke `registry.add` for every signal your module tracks.

### `M.update(dt, elapsed_since_last_log)`
Called every graphics frame (`updateGFX`). Use this to query BeamNG's C++ APIs (e.g., `obj:getVelocity()`, `electrics.values`) and update your pre-allocated state table. **Do not create new tables or strings in this function.**
