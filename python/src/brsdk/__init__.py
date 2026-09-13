"""BRSDK Python SDK.

A Python interface for loading, inspecting, and analysing
telemetry datasets produced by the BeamNG Research SDK (BRSDK).

Notes
-----
This package ships a ``py.typed`` marker (PEP 561) so that downstream
consumers can rely on the inline type annotations without installing a
separate stub package.

Examples
--------
>>> import brsdk
>>> ds = brsdk.load("telemetry.csv")   # doctest: +SKIP
>>> print(ds.session.log_hz)           # doctest: +SKIP
100
>>> print(ds.dataframe.head())         # doctest: +SKIP
shape: (5, 47)
...
"""

from __future__ import annotations

# ---------------------------------------------------------------------------
# Version
# ---------------------------------------------------------------------------
__version__: str = "0.1.0"

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
from brsdk._loader import load
from brsdk.core.dataset import Dataset
from brsdk.exceptions import (
    BRSDKError,
    DatasetFormatError,
    DatasetNotFoundError,
    MetadataValidationError,
    SidecarNotFoundError,
)
from brsdk.metadata.models import SessionMetadata

__all__: list[str] = [  # noqa: RUF022
    # Version
    "__version__",
    # Primary entry point
    "load",
    # Core objects
    "Dataset",
    "SessionMetadata",
    # Exceptions
    "BRSDKError",
    "DatasetNotFoundError",
    "SidecarNotFoundError",
    "MetadataValidationError",
    "DatasetFormatError",
]
