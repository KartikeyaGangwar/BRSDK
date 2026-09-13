"""CSV and JSON sidecar readers for BRSDK telemetry datasets.

This module is the only place in the SDK that performs filesystem I/O.
All path resolution, existence checks, and file parsing are centralised
here so that the rest of the codebase remains pure in-memory logic.

Design decisions
----------------
- **Polars ``scan_csv``**: We use the lazy API (``scan_csv``) and collect
  immediately.  This gives Polars the opportunity to optimise the parse
  plan (e.g. column projection) even though we currently request all
  columns.  When selective column loading is added in a future release,
  the call site will not need to change.
- **UTF-8 only**: BRSDK Lua emits UTF-8.  We do not attempt chardet-style
  encoding sniffing, which would add a runtime dependency and introduce
  ambiguity in scientific datasets.
- **Null representation**: BRSDK represents missing values as empty fields
  (``,,``).  Polars ``scan_csv`` maps those to ``null`` by default, which
  is the correct Arrow representation.
- **No silent coercion**: ``infer_schema_length=10000`` gives Polars enough
  rows to pick the correct dtype.  We do not force all columns to strings
  and then re-cast; that would discard Polars' dtype optimisation.

References
----------
Polars CSV reader: https://docs.pola.rs/api/python/stable/reference/io.html#polars.scan_csv
Pydantic V2 model parsing: https://docs.pydantic.dev/latest/concepts/models/#model-methods-and-properties
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import polars as pl
from pydantic import ValidationError

from brsdk.exceptions import (
    DatasetFormatError,
    MetadataValidationError,
    SidecarNotFoundError,
)
from brsdk.metadata.models import SessionMetadata

# Columns that MUST be present in every BRSDK CSV.  Their absence indicates
# a fundamentally corrupt or non-BRSDK file.  See Signal Reference §Core Kinematics.
_REQUIRED_COLUMNS: frozenset[str] = frozenset({"frame_id", "simulation_time"})


def _resolve_sidecar(csv_path: Path) -> Path:
    """Derive the expected ``session.json`` sidecar path from the CSV path.

    BRSDK names sidecars by replacing the ``.csv`` suffix with
    ``_session.json``.  For example::

        telemetry_001_20240801.csv  →  telemetry_001_20240801_session.json

    Parameters
    ----------
    csv_path : Path
        Resolved, existing path to the telemetry CSV.

    Returns
    -------
    Path
        Expected sidecar path (may or may not exist on disk).
    """
    return csv_path.with_name(csv_path.stem + "_session.json")


def read_sidecar(csv_path: Path) -> SessionMetadata:
    """Parse and validate the ``session.json`` sidecar for a given CSV.

    Parameters
    ----------
    csv_path : Path
        Resolved, existing path to the telemetry CSV.  The sidecar is
        expected at ``<stem>_session.json`` in the same directory.

    Returns
    -------
    SessionMetadata
        A fully validated Pydantic model representing the session.

    Raises
    ------
    SidecarNotFoundError
        If the expected ``_session.json`` file is not present.
    MetadataValidationError
        If the sidecar is present but fails Pydantic schema validation,
        or if it is not valid JSON.
    """
    sidecar_path = _resolve_sidecar(csv_path)

    if not sidecar_path.exists():
        raise SidecarNotFoundError(
            csv_path=str(csv_path),
            expected_sidecar=str(sidecar_path),
        )

    try:
        raw: Any = json.loads(sidecar_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise MetadataValidationError(
            sidecar_path=str(sidecar_path),
            detail=f"File is not valid JSON: {exc}",
        ) from exc

    try:
        return SessionMetadata.model_validate(raw)
    except ValidationError as exc:
        # Pydantic's str(exc) produces a clear, multi-line error report.
        raise MetadataValidationError(
            sidecar_path=str(sidecar_path),
            detail=str(exc),
        ) from exc


def read_csv(csv_path: Path) -> pl.DataFrame:
    """Parse a BRSDK telemetry CSV into a Polars DataFrame.

    Parameters
    ----------
    csv_path : Path
        Resolved, existing path to the telemetry CSV.

    Returns
    -------
    polars.DataFrame
        A fully typed Polars DataFrame.  Missing values (``,,`` in the
        CSV) are represented as ``null`` in the DataFrame.

    Raises
    ------
    DatasetFormatError
        If the CSV is empty, unparseable, or missing required BRSDK columns.

    Notes
    -----
    ``scan_csv`` is used instead of ``read_csv`` to enable future lazy
    evaluation and column projection optimisations.  The result is
    ``collect()``-ed immediately so callers receive an eager DataFrame.
    """
    try:
        lazy: pl.LazyFrame = pl.scan_csv(
            csv_path,
            encoding="utf8",
            # Allow Polars to infer dtypes from the first 10 000 rows.
            # BRSDK sessions can be long; 10 000 rows is sufficient for
            # all production vehicle configurations.
            infer_schema_length=10_000,
            # Empty fields (,,) become null in Arrow — the correct representation
            # for BRSDK nullable signals (see Signal Reference).
            null_values=[""],
            # The CSV always has a header row.
            has_header=True,
            # Ignore lines that Polars cannot parse rather than crashing on
            # isolated corrupted rows.  The caller can inspect nulls afterward.
            ignore_errors=True,
        )
        df: pl.DataFrame = lazy.collect()
    except Exception as exc:
        raise DatasetFormatError(
            csv_path=str(csv_path),
            detail=f"Polars could not parse the CSV: {exc}",
        ) from exc

    if df.is_empty():
        raise DatasetFormatError(
            csv_path=str(csv_path),
            detail="The CSV is empty (no data rows).",
        )

    missing = _REQUIRED_COLUMNS - set(df.columns)
    if missing:
        raise DatasetFormatError(
            csv_path=str(csv_path),
            detail=(
                f"Missing required BRSDK columns: {sorted(missing)}. "
                "Ensure the file was produced by BRSDK ≥ 0.1.0."
            ),
        )

    return df
