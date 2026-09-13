# RFC-0001: Canonical Data Model

**Status**: Approved (Frozen Architecture)  
**Component**: `brsdk-python` v2.0.0  
**Author**: BRSDK Technical Steering Committee  

---

## Motivation

This document defines the **Canonical Data Model** for the BRSDK Python SDK. The specification establishes architectural boundaries, data representations, and serialization protocols capable of handling out-of-core datasets and streaming ingestion without mutating the public API.

---

## 1. What is the canonical in-memory representation?

**Decision**: The canonical representation will be a **Polars DataFrame** explicitly backed by **Apache Arrow** memory, utilizing **DLPack** for tensor zero-copy.

**Alternatives**:
- **Pandas DataFrame**: Rejected. Memory-inefficient, inherently row-based (historically), and relies on NumPy memory which copies data on cast.
- **Xarray Dataset**: Rejected as the primary core. While excellent for climate models (multi-dimensional grids), vehicle telemetry is strictly tabular time-series (1D time, N features). Xarray adds unnecessary overhead for flat tabular data.
- **Raw Apache Arrow Table**: Rejected. Arrow is a passive memory format, not a query engine. It lacks the rich analytical DSL (Domain Specific Language) required by researchers.

**Trade-offs**: We tie our compute engine to Polars, introducing a dependency. However, because Polars uses Arrow memory internally, we can export directly to any Arrow-compliant system.

**Pros**: High performance, multithreaded execution, lazy evaluation out-of-the-box, and true zero-copy exports to PyTorch via DLPack.

---

## 2. Should BRSDK own a Dataset class?

**Decision**: **Yes, as a minimal Facade.**

**Design**:
```python
class Dataset:
    session: SessionMetadata
    dataframe: polars.DataFrame
```
The `Dataset` class merely binds the immutable structural metadata (`session.json`) to the Arrow memory (`dataframe`). It does **not** reimplement mathematical operations.

**Trade-offs**: Prevents monolithic class anti-patterns. By maintaining a lean interface, researchers leverage `.dataframe` directly for analytical operations, utilizing standard Polars paradigms rather than a bespoke wrapper API.

---

## 3. Should Xarray be Core, Optional, Plugin, or Adapter?

**Decision**: **Adapter (Optional)**.

**Why**: Some researchers building Digital Twins might want to map vehicle telemetry onto 3D world grids. We can provide a `dataset.to_xarray()` adapter method, but Xarray will NOT be a core dependency.

---

## 4. Should Polars be Core, Optional, Adapter, or Plugin?

**Decision**: **Core**.

**Why**: Polars provides the active compute engine (lazy query optimization, group-by, windowing) over the passive Arrow memory. It is the only heavy dependency in the core SDK.

---

## 5. How should Arrow fit into the architecture?

**Decision**: **Raw Memory Layer**.

**Architecture Principle**: Arrow is the vocabulary; Polars is the speaker. All data loaded from disk (CSV, Parquet, or future FlatBuffers) is instantly cast into an Arrow memory layout. All Python operations point to this Arrow memory.

---

## 6. Should the Registry from Lua exist in Python?

**Decision**: **Yes, but dynamically synchronized.**

**Why**: Hardcoding the registry in Python would create synchronization drift relative to the Lua runtime. 
The Python `SignalRegistry` is instantiated dynamically by parsing `session.json`, ensuring consistent schema mapping between the engine and the SDK.

---

## 7. Design the Complete Adapter System (Backends)

**Decision**: Decouple physical I/O from the Canonical Model via `typing.Protocol`.

**Design**:
```python
class DataReader(Protocol):
    def read(self, uri: str) -> polars.LazyFrame: ...
    def metadata(self, uri: str) -> dict: ...
```
- **CSV**: Implements `DataReader` using `polars.scan_csv()`.
- **Arrow IPC / Parquet**: Implements `DataReader` using `polars.scan_parquet()`.
- **UDP (Future)**: Implements a streaming reader that populates an Arrow memory buffer.

This ensures the `brsdk.load()` public API remains stable regardless of storage format.

---

## 8. Protocol Interfaces vs. Abstract Base Classes

**Decision**: **`typing.Protocol` (Structural Subtyping / Duck Typing)**.

**Why**: Using Python protocols decouples interface specifications from concrete class hierarchies, allowing third parties (such as alternative simulator integrations) to implement compatible readers without subclassing internal SDK classes.

---

## 9. Dependency Direction (Zero Circular Dependencies)

**Decision**: A strict, one-way dependency graph.

`Core Models (Metadata/Protocols) <-- Parsers (IO) <-- Orchestrator (brsdk.load) <-- Accessors (ML/Viz)`

- ML integrations (`Torch`, `Minari`) depend on `brsdk.core`.
- `brsdk.core` has no dependency on PyTorch or Matplotlib.

---

## 10. Internal Object Model (Immutability & Ownership)

**Decision**:
- **Immutable Objects**: `Dataset`, `SessionMetadata`, `polars.DataFrame`. 
- **Ownership**: The OS page cache (via memory mapping) manages raw buffers; Polars references them. 
- **Immutability Principle**: Once `brsdk.load()` executes, the telemetry state is immutable. Preprocessing transformations (`window`, `normalize`) return a *new* `Dataset` instance.

---

## 11. Design Extension Points

**Decision**: **Polars Namespace Extensions**.

**Why**: Because the canonical data model relies on Polars, external packages can register custom accessors (`@pl.api.register_dataframe_namespace("custom")`), integrating directly with BRSDK datasets without bespoke plugin scaffolding.

---

## 12. Scalability and Risk Assessment

| Scenario | Assessment |
| :--- | :--- |
| **100 GB Datasets** | **PASS**. Polars `LazyFrame` utilizes out-of-core streaming and Arrow memory mapping. |
| **Real-Time Inference** | **PASS**. Arrow memory buffers are accessible via DLPack directly to PyTorch without inter-process copy overhead. |
| **Physics-Informed Neural Networks** | **PASS**. Preservation of `dt` and `simulation_time` supports numerical differentiation of kinematic variables. |
| **Real Vehicles / Other Simulators** | **PASS**. The `DataReader` Protocol allows substituting data acquisition backends without altering analytics pipelines. |
| **Maintenance Cost** | **LOW**. Delegating execution to Polars and metadata validation to Pydantic keeps the SDK surface area concise. |

---

## Status & Verdict

**APPROVED BY STEERING COMMITTEE**.  
The Canonical Data Model is locked. Implementation is authorized to proceed based on this specification.
