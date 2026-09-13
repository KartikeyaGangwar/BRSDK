"""Pydantic V2 models for BRSDK ``session.json`` metadata sidecars.

Every CSV recording produced by the BRSDK Lua framework is accompanied by
a ``*_session.json`` file containing metadata about the recording session.
These models validate and provide typed access to that metadata.

Schema Version 2 Reality
------------------------
The Lua telemetry logger runs in the **Vehicle Lua VM**, which is an isolated
sandbox.  Several fields that one might expect (BeamNG version, map name, OS)
are only accessible from the **Game Engine (GE) Lua VM** — a different runtime
that the vehicle extension cannot call.  The logger therefore writes the
sentinel string ``"unavailable_from_vehicle_lua"`` for those fields rather
than omitting them or writing ``null``.

This is intentional, documented, and scientifically correct behaviour.
The sentinel value preserves the distinction between:

- A field that is known to be inaccessible (``"unavailable_from_vehicle_lua"``)
- A field that is truly unknown / missing (``None`` / absent)
- A field with a real value (any other string)

The Python SDK must accept this sentinel without error.  Rejecting it would
prevent every real BeamNG dataset from loading, which is wrong.

Key name mapping (real JSON → model field)
------------------------------------------
The real ``session.json`` uses these keys::

    vehicle_name   → VehicleMetadata.vehicle_name
    map_name       → SimulationMetadata.map_name
    beamng_version → SimulationMetadata.beamng_version  (may be sentinel)
    log_hz         → SimulationMetadata.log_hz
    wheel_count    → VehicleMetadata.wheel_count
    sdk_version    → SDKMetadata.sdk_version

References
----------
Pydantic V2 documentation: https://docs.pydantic.dev/latest/concepts/models/
BRSDK Dataset Specification: docs/DATASET_SPECIFICATION.md
BRSDK Signal Reference: docs/SIGNAL_REFERENCE.md
"""

from __future__ import annotations

from pydantic import BaseModel, Field, field_validator, model_validator

# Sentinel written by the Lua Vehicle VM for fields that are only accessible
# from the GE VM.  The Python SDK must accept this value without error.
_UNAVAILABLE: str = "unavailable_from_vehicle_lua"


def _is_present(value: str) -> bool:
    """Return True if *value* contains meaningful data.

    A value is considered absent (but valid) if it is the known sentinel,
    empty, or whitespace-only.  Such values are accepted but callers can
    check ``session.map_name_is_known`` etc. for human-readable guidance.
    """
    return bool(value.strip()) and value.strip() != _UNAVAILABLE


class SDKMetadata(BaseModel):
    """Metadata about the BRSDK SDK version that produced the dataset.

    Attributes
    ----------
    sdk_version : str
        Semantic version of the BRSDK Lua framework (e.g. ``"0.1.0-phase1b"``).
    logger_version : str
        Version of the logger module.
    schema_version : str
        Schema version of the ``session.json`` format.
    """

    sdk_version: str = Field(
        default=_UNAVAILABLE,
        description="Semantic version of the BRSDK Lua framework.",
        examples=["0.1.0", "0.1.0-phase1b"],
    )
    logger_version: str = Field(
        default=_UNAVAILABLE,
        description="Version of the telemetry logger module.",
    )
    schema_version: str = Field(
        default=_UNAVAILABLE,
        description="Schema version of the session.json format.",
    )

    @field_validator("sdk_version")
    @classmethod
    def sdk_version_not_empty(cls, value: str) -> str:
        """Reject genuinely blank version strings.

        The sentinel ``"unavailable_from_vehicle_lua"`` is accepted —
        it is a real, meaningful value produced by the Lua logger.
        Only an empty or whitespace-only string is invalid.
        """
        if not value.strip():
            msg = "sdk_version must not be blank (use the sentinel if unknown)"
            raise ValueError(msg)
        return value


class SimulationMetadata(BaseModel):
    """Metadata about the BeamNG simulation environment.

    Several fields are inaccessible from the Vehicle Lua VM and will contain
    the sentinel ``"unavailable_from_vehicle_lua"``.  This is expected and
    correct.  See module docstring for details.

    Attributes
    ----------
    beamng_version : str
        BeamNG version string, or the sentinel if unavailable from vehicle VM.
    map_name : str
        Internal BeamNG map identifier, or the sentinel if unavailable.
    log_hz : int
        Target logging frequency in Hz.
    physics_rate : int
        Physics simulation rate (always 2000 for BeamNG).
    gravity : float | str
        Gravitational acceleration (m/s²), or the sentinel if unavailable.
    """

    beamng_version: str = Field(
        default=_UNAVAILABLE,
        description="BeamNG version string (may be sentinel from Vehicle VM).",
    )
    map_name: str = Field(
        default=_UNAVAILABLE,
        description="Internal BeamNG map identifier (may be sentinel from Vehicle VM).",
    )
    log_hz: int = Field(
        ...,
        gt=0,
        le=2000,
        description=(
            "Target logging frequency in Hz. "
            "Must be in the range (0, 2000] — the physics thread ceiling."
        ),
    )
    physics_rate: int = Field(
        default=2000,
        description="BeamNG physics simulation rate (fixed at 2000 Hz).",
    )
    gravity: float | str = Field(
        default=_UNAVAILABLE,
        description="Gravitational acceleration in m/s², or sentinel if unavailable.",
    )

    @field_validator("beamng_version")
    @classmethod
    def beamng_version_not_empty(cls, value: str) -> str:
        """Reject genuinely blank version strings (sentinel is accepted)."""
        if not value.strip():
            msg = (
                "beamng_version must not be blank. "
                f"Use {_UNAVAILABLE!r} if the value cannot be obtained."
            )
            raise ValueError(msg)
        return value

    @field_validator("map_name")
    @classmethod
    def map_name_not_empty(cls, value: str) -> str:
        """Reject genuinely blank map names (sentinel is accepted)."""
        if not value.strip():
            msg = (
                "map_name must not be blank. "
                f"Use {_UNAVAILABLE!r} if the value cannot be obtained."
            )
            raise ValueError(msg)
        return value

    @property
    def map_name_is_known(self) -> bool:
        """Return True if map_name contains a real map identifier."""
        return _is_present(self.map_name)

    @property
    def beamng_version_is_known(self) -> bool:
        """Return True if beamng_version contains a real version string."""
        return _is_present(self.beamng_version)


class VehicleMetadata(BaseModel):
    """Metadata about the vehicle used in the recording session.

    Attributes
    ----------
    vehicle_name : str
        Human-readable vehicle name from the JBeam definition
        (e.g. ``"Ibishu Pessima"``).
    vehicle_id : str
        Internal BeamNG numeric vehicle object ID.
    vehicle_config : str
        Path to the part-config ``.pc`` file used for this vehicle.
    wheel_count : int
        Number of wheels; determines the width of wheel columns in the CSV.
    vehicle_type : str
        Vehicle type from JBeam information, or ``"unknown"``.
    """

    vehicle_name: str = Field(
        default=_UNAVAILABLE,
        description="Human-readable vehicle name from JBeam.",
        examples=["Ibishu Pessima", "Bruckell Bastion"],
    )
    vehicle_id: str = Field(
        default=_UNAVAILABLE,
        description="Internal BeamNG numeric vehicle object ID.",
    )
    vehicle_config: str = Field(
        default=_UNAVAILABLE,
        description="Path to the part-config .pc file.",
    )
    wheel_count: int = Field(
        ...,
        ge=0,
        le=32,
        description=(
            "Number of wheels. Determines the width of the wheel columns. "
            "Must be in [0, 32]."
        ),
    )
    vehicle_type: str = Field(
        default="unknown",
        description="Vehicle type from JBeam information.",
    )

    @field_validator("vehicle_name")
    @classmethod
    def vehicle_name_not_empty(cls, value: str) -> str:
        """Reject genuinely blank vehicle names (sentinel is accepted)."""
        if not value.strip():
            msg = (
                "vehicle_name must not be blank. "
                f"Use {_UNAVAILABLE!r} if the value cannot be obtained."
            )
            raise ValueError(msg)
        return value

    @property
    def vehicle_name_is_known(self) -> bool:
        """Return True if vehicle_name contains a real vehicle name."""
        return _is_present(self.vehicle_name)


class SessionMetadata(BaseModel):
    """Top-level validated model for a BRSDK ``session.json`` sidecar.

    This model is the single object returned by the internal metadata
    parser and exposed as ``Dataset.session``.

    The ``session.json`` produced by BRSDK schema_version ``"2"`` is a flat
    dictionary with 40+ fields.  This model maps the most important fields
    into typed sub-models and exposes convenience properties at the top level.

    Some fields will contain the sentinel ``"unavailable_from_vehicle_lua"``
    because the Lua telemetry runs in the Vehicle VM, which cannot access
    GE-only APIs like ``getCurrentLevelIdentifier()``.  This is expected and
    does not indicate data corruption.  Check the ``*_is_known`` properties
    on sub-models to distinguish sentinel values from real data.

    Attributes
    ----------
    sdk : SDKMetadata
        SDK and logger version information.
    simulation : SimulationMetadata
        Simulation environment information.
    vehicle : VehicleMetadata
        Vehicle information.
    raw : dict
        The complete, unmodified raw dictionary from ``session.json``.
        Gives researchers access to any field not promoted to a typed model.
    """

    sdk: SDKMetadata
    simulation: SimulationMetadata
    vehicle: VehicleMetadata
    raw: dict[str, object] = Field(
        default_factory=dict,
        description="Complete unmodified session.json dict for advanced access.",
    )

    # ------------------------------------------------------------------
    # Convenience properties — top-level shortcuts for the most-accessed
    # fields so callers can write session.log_hz instead of
    # session.simulation.log_hz.
    # ------------------------------------------------------------------

    @property
    def sdk_version(self) -> str:
        """SDK version string."""
        return self.sdk.sdk_version

    @property
    def log_hz(self) -> int:
        """Logging frequency in Hz."""
        return self.simulation.log_hz

    @property
    def beamng_version(self) -> str:
        """BeamNG version string (may be sentinel)."""
        return self.simulation.beamng_version

    @property
    def map_name(self) -> str:
        """Map name (may be sentinel if unavailable from Vehicle VM)."""
        return self.simulation.map_name

    @property
    def vehicle_name(self) -> str:
        """Human-readable vehicle name from JBeam."""
        return self.vehicle.vehicle_name

    @property
    def vehicle_model(self) -> str:
        """Alias for vehicle_name for backwards compatibility."""
        return self.vehicle.vehicle_name

    @property
    def wheel_count(self) -> int:
        """Number of wheels in the recording."""
        return self.vehicle.wheel_count

    @model_validator(mode="before")
    @classmethod
    def _reshape_flat_json(cls, data: object) -> object:
        """Reshape the flat ``session.json`` dict into the nested structure.

        The Lua framework emits a single flat JSON object with 40+ keys.
        This validator transparently lifts the correct keys into the nested
        ``sdk``, ``simulation``, and ``vehicle`` sub-objects.

        Key mapping (real session.json key → sub-model field)
        -------------------------------------------------------
        - ``sdk_version``    → sdk.sdk_version
        - ``logger_version`` → sdk.logger_version
        - ``schema_version`` → sdk.schema_version
        - ``beamng_version`` → simulation.beamng_version
        - ``map_name``       → simulation.map_name   (NOT "map")
        - ``log_hz``         → simulation.log_hz
        - ``physics_rate``   → simulation.physics_rate
        - ``gravity``        → simulation.gravity
        - ``vehicle_name``   → vehicle.vehicle_name   (NOT "vehicle_model")
        - ``vehicle_id``     → vehicle.vehicle_id
        - ``vehicle_config`` → vehicle.vehicle_config
        - ``wheel_count``    → vehicle.wheel_count
        - ``vehicle_type``   → vehicle.vehicle_type

        The complete raw dict is also stored in ``raw`` for researcher access.

        Parameters
        ----------
        data : object
            Raw input — typically the ``dict`` parsed from ``session.json``.

        Returns
        -------
        object
            Reshaped nested dict, or the original data if already nested.
        """
        if not isinstance(data, dict):
            return data

        # If the dict already has the nested keys, it was constructed from
        # Python code (e.g. tests). Pass through unchanged except to preserve raw.
        if "sdk" in data or "simulation" in data or "vehicle" in data:
            return data

        # Real flat format produced by the Lua framework.
        # IMPORTANT: Do NOT use `or _UNAVAILABLE` coercions here.
        # Blank strings must flow through as-is so that field_validators
        # can reject them with a clear error.  Only missing keys default
        # to the sentinel, because an absent key means the Lua writer
        # predates the field — that is expected and valid.
        return {
            "sdk": {
                "sdk_version": data.get("sdk_version", _UNAVAILABLE),
                "logger_version": data.get("logger_version", _UNAVAILABLE),
                "schema_version": data.get("schema_version", _UNAVAILABLE),
            },
            "simulation": {
                # The real key is "map_name", NOT "map".
                "map_name": data.get("map_name", _UNAVAILABLE),
                "beamng_version": data.get("beamng_version", _UNAVAILABLE),
                "log_hz": data.get("log_hz", 0),
                "physics_rate": data.get("physics_rate", 2000),
                "gravity": data.get("gravity", _UNAVAILABLE),
            },
            "vehicle": {
                # The real key is "vehicle_name", NOT "vehicle_model".
                "vehicle_name": data.get("vehicle_name", _UNAVAILABLE),
                "vehicle_id": str(data.get("vehicle_id", _UNAVAILABLE)),
                "vehicle_config": str(data.get("vehicle_config", _UNAVAILABLE)),
                "wheel_count": data.get("wheel_count", 0),
                "vehicle_type": data.get("vehicle_type", "unknown") or "unknown",
            },
            # Preserve the complete raw dict for advanced access.
            "raw": data,
        }

    def __repr__(self) -> str:
        """Return a string representation of the session metadata."""
        return (
            f"SessionMetadata("
            f"sdk_version={self.sdk_version!r}, "
            f"log_hz={self.log_hz}, "
            f"vehicle={self.vehicle_name!r}, "
            f"wheels={self.wheel_count}, "
            f"map_name={self.map_name!r}, "
            f"beamng={self.beamng_version!r})"
        )
