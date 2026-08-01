"""BRSDK Dataset — the primary user-facing object.

A :class:`Dataset` encapsulates a fully loaded, validated BRSDK telemetry
session.  It is the object returned by :func:`brsdk.load`.

Design decisions
----------------
- **Immutability**: The class uses ``__slots__`` and all public attributes
  are read-only properties.  Scientific datasets should not be mutated in
  place; researchers should derive new DataFrames via Polars expressions.
- **No copy on construction**: The Polars DataFrame is stored directly —
  no ``df.clone()`` is performed.  Callers already own the DataFrame from
  the reader.
- **Lazy accessor namespace**: The ``ml`` and ``viz`` accessor objects are
  imported inside the property so that the heavy optional dependencies
  (PyTorch, Matplotlib) are not loaded until first access.

References
----------
Polars DataFrame API: https://docs.pola.rs/api/python/stable/reference/dataframe/index.html
"""

from __future__ import annotations

from pathlib import Path
from typing import TYPE_CHECKING, Any

import polars as pl

from brsdk.metadata.models import SessionMetadata

if TYPE_CHECKING:
    pass


class Dataset:
    """An immutable, fully validated BRSDK telemetry dataset.

    Obtain an instance via :func:`brsdk.load` rather than constructing
    this class directly.

    Parameters
    ----------
    dataframe : polars.DataFrame
        The telemetry signal data parsed from the CSV.
    session : SessionMetadata
        The validated Pydantic model parsed from ``session.json``.
    path : pathlib.Path
        Resolved path to the source CSV on disk.

    Attributes
    ----------
    dataframe : polars.DataFrame
        The raw signal DataFrame.  All BRSDK nullable signals are
        represented as Arrow ``null`` (Polars ``None``).
    session : SessionMetadata
        Validated session metadata.
    path : pathlib.Path
        Resolved path to the source CSV.
    columns : list[str]
        Column names of the DataFrame (shortcut for ``dataframe.columns``).
    shape : tuple[int, int]
        ``(n_rows, n_cols)`` tuple.
    metadata : dict[str, Any]
        Raw metadata dictionary reconstructed from the session model,
        useful for serialisation and debugging.

    Examples
    --------
    >>> import brsdk
    >>> ds = brsdk.load("telemetry_001.csv")  # doctest: +SKIP
    >>> print(ds.session)                      # doctest: +SKIP
    SessionMetadata(sdk_version='1.0.1', log_hz=100, ...)
    >>> print(ds.dataframe.head())             # doctest: +SKIP
    shape: (5, 47)
    ...
    """

    __slots__ = ("_dataframe", "_path", "_session")

    def __init__(
        self,
        dataframe: pl.DataFrame,
        session: SessionMetadata,
        path: Path,
    ) -> None:
        self._dataframe: pl.DataFrame = dataframe
        self._session: SessionMetadata = session
        self._path: Path = path

    # ------------------------------------------------------------------
    # Core properties
    # ------------------------------------------------------------------

    @property
    def dataframe(self) -> pl.DataFrame:
        """Polars DataFrame containing all telemetry signals."""
        return self._dataframe

    @property
    def session(self) -> SessionMetadata:
        """Validated Pydantic metadata model for this recording session."""
        return self._session

    @property
    def path(self) -> Path:
        """Resolved path to the source telemetry CSV on disk."""
        return self._path

    @property
    def columns(self) -> list[str]:
        """Column names of the telemetry DataFrame.

        Equivalent to ``dataset.dataframe.columns``.
        """
        return self._dataframe.columns

    @property
    def shape(self) -> tuple[int, int]:
        """Shape of the DataFrame as ``(n_rows, n_cols)``.

        Equivalent to ``dataset.dataframe.shape``.
        """
        return self._dataframe.shape

    @property
    def metadata(self) -> dict[str, Any]:
        """Flat metadata dictionary reconstructed from the session model.

        Useful for serialising the session back to JSON or logging.

        Returns
        -------
        dict[str, Any]
            A plain Python dictionary with the most-used session fields.
            ``vehicle_model`` is an alias for ``vehicle_name`` for
            backwards compatibility with the original API design.
        """
        return {
            "sdk_version": self._session.sdk_version,
            "log_hz": self._session.log_hz,
            "wheel_count": self._session.wheel_count,
            "beamng_version": self._session.beamng_version,
            "map_name": self._session.map_name,
            "vehicle_name": self._session.vehicle_name,
            # Alias kept for backwards compatibility.
            "vehicle_model": self._session.vehicle_name,
        }

    # ------------------------------------------------------------------
    # Dunder methods
    # ------------------------------------------------------------------

    def __repr__(self) -> str:
        """Return a string representation of the dataset."""
        n_rows, n_cols = self._dataframe.shape
        return (
            f"Dataset("
            f"path={self._path.name!r}, "
            f"rows={n_rows}, "
            f"cols={n_cols}, "
            f"session={self._session!r})"
        )

    def __len__(self) -> int:
        """Return the number of rows in the DataFrame."""
        return self._dataframe.height
