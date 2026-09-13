# Academic Reproducibility

Reproducibility is a core tenet of the BRSDK framework. This document outlines how to ensure your simulated datasets are deterministic and scientifically valid.

## Determinism in BeamNG
BeamNG's physics engine ticks at a fixed 2000Hz interval. However, because telemetry is often requested at a lower frequency (e.g., 100Hz) within the graphics thread (`updateGFX`), frame drops can cause slight variations in sampling intervals.

BRSDK mitigates this by logging the exact `elapsed_since_last_log` and `dt` values per row (see [Signal Reference](SIGNAL_REFERENCE.md)). Offline interpolation should use `elapsed_since_last_log` rather than assuming a perfect 0.01s delta.

## Zero-Allocation Guarantee
Garbage Collection (GC) latency spikes in Lua can introduce micro-pauses that disrupt simulation fidelity. As detailed in the [Architecture overview](ARCHITECTURE.md), BRSDK is architected to eliminate dynamic heap allocations during the extraction and logging loop (`collectRow`). 

To verify this locally:
1. Enable Lua debug profiling in the BeamNG console.
2. Run BRSDK for 10,000 frames.
3. Observe that GC byte count remains perfectly flat.

## Version Pinning
When publishing a paper, you **must** cite the exact version of BRSDK used (refer to our [Citation format](../README.md#citation)), as the internal math of the layout modules can change between major releases. Always store the `session.json` alongside your published CSVs (see [Dataset Specification](DATASET_SPECIFICATION.md)), as it contains the exact game version and configuration used during extraction.
