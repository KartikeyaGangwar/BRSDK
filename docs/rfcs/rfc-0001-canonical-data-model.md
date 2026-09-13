# RFC-0001: Canonical Data Model

**Status**: Approved (Frozen Architecture)  
**Component**: `brsdk-python` v0.1.0  
**Author**: BRSDK Technical Steering Committee  

---

## Motivation

BRSDK is transitioning from a passive Lua logging script into a production-grade scientific framework for Autonomous Driving and Reinforcement Learning. We must establish a **Canonical Data Model** for the Python SDK that will survive for the next 10 years. It must effortlessly scale from 1MB offline CSVs to 100GB out-of-core datasets, and eventually support live streaming for Real-Time Inference, all without breaking the public API.

---

## 1. What is the canonical in-memory representation?

**Decision**: The canonical representation will be a **Polars DataFrame** explicitly backed by **Apache Arrow** memory, utilizing **DLPack** for tensor zero-copy.

**Alternatives**:
- **Pandas DataFrame**: Rejected. Memory-inefficient, inherently row-based (historically), and relies on NumPy memory which copies data on cast.
- **Xarray Dataset**: Rejected as the primary core. While excellent for climate models (multi-dimensional grids), vehicle telemetry is strictly tabular time-series (1D time, N features). Xarray adds unnecessary overhead for flat tabular data.
- **Raw Apache Arrow Table**: Rejected. Arrow is a passive memory format, not a query engine. It lacks the rich analytical DSL (Domain Specific Language) required by researchers.

**Trade-offs**: We tie our compute engine to Polars, introducing a dependency. However, because Polars uses Arrow memory under the hood, we can instantly export to any Arrow-compliant system.

**Pros**: High performance, multithreaded execution, lazy evaluation out-of-the-box, and true zero-copy exports to PyTorch via DLPack.

---

## 2. Should BRSDK own a Dataset class?

**Decision**: **Yes, but it must be an ultra-thin Facade.**

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

**Why**: Hardcoding the registry in Python guarantees it will drift from the Lua implementation over the next 10 years. 
The Python `SignalRegistry` is instantiated dynamically at runtime by parsing the `session.json` (which the Lua Layout Engine emits). This guarantees perfect synchronization between the engine and the SDK.

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

This ensures the `brsdk.load()` public API never changes, regardless of where the data comes from.

---

## 8. Protocol Interfaces vs. Abstract Base Classes

**Decision**: **`typing.Protocol` (Structural Subtyping / Duck Typing)**.

**Why**: Scikit-learn succeeded because of its flat, duck-typed API (`fit`, `predict`), avoiding complex class hierarchies. Using Protocols allows third parties (like CARLA or Chrono researchers) to write a reader for their simulator without having to subclass an internal BRSDK class.

---

## 9. Dependency Direction (Zero Circular Dependencies)

**Decision**: A strict, one-way dependency graph.

`Core Models (Metadata/Protocols) <-- Parsers (IO) <-- Orchestrator (brsdk.load) <-- Accessors (ML/Viz)`

- ML integrations (`Torch`, `Minari`) depend on `brsdk.core`.
- `brsdk.core` knows absolutely nothing about Torch or Matplotlib.

---

## 10. Internal Object Model (Immutability & Ownership)

**Decision**:
- **Immutable Objects**: `Dataset`, `SessionMetadata`, `polars.DataFrame`. 
- **Ownership**: The OS page cache (via memory mapping) owns the data. Polars only references it. 
- **Immutability Principle**: Once `brsdk.load()` executes, the telemetry is mathematically frozen. Any preprocessing (`window`, `normalize`) returns a *new* `Dataset` object.

---

## 11. Design Extension Points

**Decision**: **Polars Namespace Extensions**.

**Why**: Because our canonical data model relies on Polars, third parties can write new plugins by registering standard Polars accessors (`@pl.api.register_dataframe_namespace("my_plugin")`), instantly making them compatible with BRSDK dataframes. We do not need to invent a proprietary plugin system.

---

## 12. 10-Year Evaluation Risk Assessment

| Scenario | Assessment |
| :--- | :--- |
| **100 GB Datasets** | **PASS**. Polars `LazyFrame` uses out-of-core streaming and Arrow `mmap`. Only chunks are loaded into RAM. |
| **Real-Time Inference** | **PASS**. Arrow memory can be shared via DLPack directly to PyTorch on a GPU with 0 latency. |
| **Physics-Informed Neural Networks** | **PASS**. The strict preservation of `dt` and `simulation_time` allows perfect physics derivatives. |
| **Real Vehicles / Other Simulators** | **PASS**. The `DataReader` Protocol allows replacing the BeamNG IO backend without breaking ML pipelines. |
| **Maintenance Cost** | **LOW**. By delegating computation to Polars and metadata validation to Pydantic, the BRSDK-specific codebase remains lightweight. |

---

## Status & Verdict

**APPROVED BY STEERING COMMITTEE**.  
The Canonical Data Model is locked. Implementation is authorized to proceed based on this specification.
