"""BRSDK custom exception hierarchy.

All exceptions raised by the public API are defined here so that callers
can catch them with a single ``except brsdk.BRSDKError`` clause or handle
specific failure modes individually.

The hierarchy is intentionally flat.  Deep exception trees create coupling
and make ``except`` clauses harder to read.
"""

from __future__ import annotations


class BRSDKError(Exception):
    """Base class for all BRSDK Python SDK errors.

    Catching this class catches every error the SDK can raise.

    Examples
    --------
    >>> try:
    ...     brsdk.load("missing.csv")
    ... except brsdk.BRSDKError as exc:
    ...     print(exc)
    """


class DatasetNotFoundError(BRSDKError, FileNotFoundError):
    """Raised when the telemetry CSV or its sidecar cannot be found on disk.

    Inherits from :class:`FileNotFoundError` so that callers using the
    stdlib exception still catch it.

    Parameters
    ----------
    path : str
        The path that was searched.
    """

    def __init__(self, path: str) -> None:
        self.path = path
        super().__init__(f"Telemetry file not found: {path!r}")


class SidecarNotFoundError(BRSDKError, FileNotFoundError):
    """Raised when the ``*_session.json`` metadata sidecar is missing.

    BRSDK always writes a sidecar alongside the CSV.  Its absence indicates
    an incomplete or corrupted recording session.

    Parameters
    ----------
    csv_path : str
        The CSV that was found.
    expected_sidecar : str
        The sidecar path that was expected but not present.
    """

    def __init__(self, csv_path: str, expected_sidecar: str) -> None:
        self.csv_path = csv_path
        self.expected_sidecar = expected_sidecar
        super().__init__(
            f"Session sidecar not found for {csv_path!r}. "
            f"Expected: {expected_sidecar!r}. "
            "Ensure the recording session completed normally."
        )


class MetadataValidationError(BRSDKError, ValueError):
    """Raised when ``session.json`` exists but fails Pydantic schema validation.

    Inherits from :class:`ValueError` to match the convention used by
    Pydantic itself.

    Parameters
    ----------
    sidecar_path : str
        The sidecar file that failed validation.
    detail : str
        A human-readable summary of the validation failure.
    """

    def __init__(self, sidecar_path: str, detail: str) -> None:
        self.sidecar_path = sidecar_path
        self.detail = detail
        super().__init__(f"Metadata validation failed for {sidecar_path!r}: {detail}")


class DatasetFormatError(BRSDKError, ValueError):
    """Raised when the CSV is parseable but does not conform to BRSDK schema.

    Examples include missing required columns (``frame_id``,
    ``simulation_time``) or a completely empty file.

    Parameters
    ----------
    csv_path : str
        The CSV that failed format validation.
    detail : str
        A human-readable explanation of the format problem.
    """

    def __init__(self, csv_path: str, detail: str) -> None:
        self.csv_path = csv_path
        self.detail = detail
        super().__init__(f"Dataset format error in {csv_path!r}: {detail}")
