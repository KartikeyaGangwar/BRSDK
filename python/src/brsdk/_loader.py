"""Internal implementation of :func:`brsdk.load`.

This module contains the path resolution, validation, and orchestration
logic that backs the public :func:`brsdk.load` function.

It is intentionally a private module (prefixed with ``_``).  The public
API is re-exported through ``brsdk.__init__``.

Why a separate module?
    Keeping the loader out of ``__init__.py`` means the entry-point module
    stays side-effect-free and fast to import.  The IO and Pydantic
    machinery is only initialised when ``load()`` is actually called.
"""

from __future__ import annotations

from pathlib import Path

from brsdk.core.dataset import Dataset
from brsdk.exceptions import DatasetNotFoundError
from brsdk.io.reader import read_csv, read_sidecar


def load(path: str | Path) -> Dataset:
    """Load a BRSDK telemetry session from disk.

    Locates the CSV, finds the paired ``*_session.json`` sidecar,
    validates both, and returns an immutable :class:`~brsdk.core.Dataset`.

    Parameters
    ----------
    path : str or pathlib.Path
        Path to the telemetry CSV file produced by BRSDK.  Both absolute
        and relative paths are accepted.  The function resolves the path
        before any filesystem access.

    Returns
    -------
    Dataset
        An immutable, validated dataset object whose :attr:`~Dataset.dataframe`
        attribute is a :class:`polars.DataFrame` and whose
        :attr:`~Dataset.session` attribute is a fully typed
        :class:`~brsdk.metadata.models.SessionMetadata` instance.

    Raises
    ------
    DatasetNotFoundError
        If the CSV does not exist at the resolved path.
    SidecarNotFoundError
        If the CSV exists but its ``*_session.json`` sidecar is absent.
    MetadataValidationError
        If the sidecar exists but fails Pydantic schema validation.
    DatasetFormatError
        If the CSV is present but missing required BRSDK columns or is empty.

    Examples
    --------
    >>> import brsdk
    >>> ds = brsdk.load("telemetry_001.csv")        # doctest: +SKIP
    >>> print(ds.session.log_hz)                     # doctest: +SKIP
    100
    >>> print(ds.dataframe.head())                   # doctest: +SKIP
    shape: (5, 47)
    ...
    """
    resolved = Path(path).resolve()

    if not resolved.exists():
        raise DatasetNotFoundError(str(resolved))

    session = read_sidecar(resolved)
    dataframe = read_csv(resolved)

    return Dataset(dataframe=dataframe, session=session, path=resolved)
