"""BRSDK IO sub-package.

Provides the CSV reader and JSON sidecar parser that back ``brsdk.load()``.

Public surface
--------------
:func:`read_csv` — parse a BRSDK telemetry CSV into a Polars DataFrame.
:func:`read_sidecar` — parse and validate a ``session.json`` sidecar.
"""

from __future__ import annotations

from brsdk.io.reader import read_csv, read_sidecar

__all__: list[str] = ["read_csv", "read_sidecar"]
