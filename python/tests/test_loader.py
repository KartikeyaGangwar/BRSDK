"""Tests for the BRSDK dataset loader, IO layer, and metadata models.

Covers
------
- Phase 1 (Loader): brsdk.load() success and all error paths.
- Phase 2 (Dataset): Dataset object properties.
- Phase 3 (Metadata): SessionMetadata validation against both the
  synthetic fixture format AND the real session.json schema produced by
  the BRSDK Lua framework (schema_version 2).

Key schema facts verified here
-------------------------------
- The Lua framework writes ``vehicle_name`` (not ``vehicle_model``).
- The Lua framework writes ``map_name`` (not ``map``).
- Fields unavailable from the Vehicle VM are written as the sentinel
  string ``"unavailable_from_vehicle_lua"`` — this must NOT cause a
  validation error.
- ``log_hz`` and ``wheel_count`` are always present as integers.
"""

from __future__ import annotations

import json
from pathlib import Path

import polars as pl
from pydantic import ValidationError
import pytest

import brsdk
from brsdk.exceptions import (
    DatasetFormatError,
    DatasetNotFoundError,
    MetadataValidationError,
    SidecarNotFoundError,
)
from brsdk.metadata.models import _UNAVAILABLE, SessionMetadata

# ---------------------------------------------------------------------------
# Shared fixture data — reflects the REAL schema produced by the Lua logger
# ---------------------------------------------------------------------------

REAL_SESSION_JSON: dict[str, object] = {
    # This is a representative subset of the real session.json (schema v2).
    # It intentionally uses the same key names as the Lua framework:
    #   vehicle_name (not vehicle_model), map_name (not map),
    #   beamng_version may be sentinel.
    "sdk_version": "0.1.0-phase1b",
    "logger_version": "0.1.0",
    "schema_version": "2",
    "log_hz": 100,
    "wheel_count": 4,
    "beamng_version": _UNAVAILABLE,
    "map_name": _UNAVAILABLE,
    "vehicle_name": "Ibishu Pessima",
    "vehicle_id": "17801",
    "vehicle_config": "vehicles/midsize/LX_sport_A.pc",
    "vehicle_type": "unknown",
    "physics_rate": 2000,
    "gravity": -9.81,
    "generator": "BRSDK",
    "lua_vm": "Vehicle",
    "dataset_version": "1.0",
}

MINIMAL_CSV: str = "frame_id,simulation_time,vel_x\n1,0.01,10.5\n2,0.02,10.6\n"


@pytest.fixture
def real_session_json() -> dict[str, object]:
    """Return a representative real-format session.json dict."""
    return dict(REAL_SESSION_JSON)


@pytest.fixture
def mock_dataset_files(
    tmp_path: Path,
    real_session_json: dict[str, object],
) -> tuple[Path, Path]:
    """Create a paired CSV and session.json in a temporary directory.

    Uses the REAL schema (vehicle_name, map_name, sentinel values).
    """
    csv_path = tmp_path / "telemetry_001.csv"
    json_path = tmp_path / "telemetry_001_session.json"
    csv_path.write_text(MINIMAL_CSV, encoding="utf-8")
    json_path.write_text(json.dumps(real_session_json), encoding="utf-8")
    return csv_path, json_path


# ---------------------------------------------------------------------------
# Metadata model unit tests (no filesystem access)
# ---------------------------------------------------------------------------


class TestSessionMetadataRealSchema:
    """Verify SessionMetadata parses the real Lua-produced schema correctly."""

    def test_real_schema_loads_without_error(
        self, real_session_json: dict[str, object]
    ) -> None:
        """The real session.json format must parse without raising."""
        meta = SessionMetadata.model_validate(real_session_json)
        assert meta.log_hz == 100
        assert meta.wheel_count == 4

    def test_sentinel_beamng_version_accepted(
        self, real_session_json: dict[str, object]
    ) -> None:
        """beamng_version == sentinel must not raise MetadataValidationError."""
        assert real_session_json["beamng_version"] == _UNAVAILABLE
        meta = SessionMetadata.model_validate(real_session_json)
        assert meta.beamng_version == _UNAVAILABLE
        assert not meta.simulation.beamng_version_is_known

    def test_sentinel_map_name_accepted(
        self, real_session_json: dict[str, object]
    ) -> None:
        """map_name == sentinel must not raise MetadataValidationError."""
        assert real_session_json["map_name"] == _UNAVAILABLE
        meta = SessionMetadata.model_validate(real_session_json)
        assert meta.map_name == _UNAVAILABLE
        assert not meta.simulation.map_name_is_known

    def test_vehicle_name_key_used(self, real_session_json: dict[str, object]) -> None:
        """vehicle_name (not vehicle_model) must be read from the JSON."""
        meta = SessionMetadata.model_validate(real_session_json)
        assert meta.vehicle_name == "Ibishu Pessima"
        assert meta.vehicle_model == "Ibishu Pessima"  # alias must work

    def test_vehicle_name_is_known(self, real_session_json: dict[str, object]) -> None:
        """vehicle_name_is_known must be True when a real name is present."""
        meta = SessionMetadata.model_validate(real_session_json)
        assert meta.vehicle.vehicle_name_is_known

    def test_raw_dict_preserved(self, real_session_json: dict[str, object]) -> None:
        """The raw dict must be stored on the model for advanced access."""
        meta = SessionMetadata.model_validate(real_session_json)
        assert meta.raw.get("generator") == "BRSDK"
        assert meta.raw.get("lua_vm") == "Vehicle"

    def test_blank_map_name_rejected(self) -> None:
        """A genuinely blank map_name (not the sentinel) must raise."""
        bad = dict(REAL_SESSION_JSON)
        bad["map_name"] = ""
        with pytest.raises(ValidationError):
            SessionMetadata.model_validate(bad)

    def test_blank_vehicle_name_rejected(self) -> None:
        """A genuinely blank vehicle_name must raise."""
        bad = dict(REAL_SESSION_JSON)
        bad["vehicle_name"] = ""
        with pytest.raises(ValidationError):
            SessionMetadata.model_validate(bad)

    def test_repr_contains_vehicle_name(
        self, real_session_json: dict[str, object]
    ) -> None:
        """repr() must contain the vehicle name for quick inspection."""
        meta = SessionMetadata.model_validate(real_session_json)
        assert "Ibishu Pessima" in repr(meta)


# ---------------------------------------------------------------------------
# Loader integration tests (filesystem access via tmp_path)
# ---------------------------------------------------------------------------


class TestLoader:
    """Integration tests for brsdk.load()."""

    def test_successful_load(self, mock_dataset_files: tuple[Path, Path]) -> None:
        """brsdk.load() must return a Dataset when given valid real-schema files."""
        csv_path, _ = mock_dataset_files
        dataset = brsdk.load(csv_path)

        assert isinstance(dataset, brsdk.Dataset)
        assert isinstance(dataset.dataframe, pl.DataFrame)
        assert isinstance(dataset.session, brsdk.SessionMetadata)

        # Data shape
        assert dataset.shape == (2, 3)
        assert dataset.columns == ["frame_id", "simulation_time", "vel_x"]

        # Metadata (real schema)
        assert dataset.session.sdk_version == "0.1.0-phase1b"
        assert dataset.session.log_hz == 100
        assert dataset.session.vehicle_name == "Ibishu Pessima"
        assert dataset.session.wheel_count == 4
        assert dataset.session.beamng_version == _UNAVAILABLE
        assert dataset.session.map_name == _UNAVAILABLE

    def test_missing_csv(self, tmp_path: Path) -> None:
        """Loading a non-existent CSV must raise DatasetNotFoundError."""
        with pytest.raises(DatasetNotFoundError, match="Telemetry file not found"):
            brsdk.load(tmp_path / "does_not_exist.csv")

    def test_missing_json(self, tmp_path: Path) -> None:
        """Loading a CSV without its sidecar must raise SidecarNotFoundError."""
        csv_path = tmp_path / "lonely.csv"
        csv_path.write_text(MINIMAL_CSV, encoding="utf-8")
        with pytest.raises(SidecarNotFoundError, match="Session sidecar not found"):
            brsdk.load(csv_path)

    def test_invalid_json(self, mock_dataset_files: tuple[Path, Path]) -> None:
        """A corrupted JSON sidecar must raise MetadataValidationError."""
        csv_path, json_path = mock_dataset_files
        json_path.write_text("{malformed_json: true", encoding="utf-8")
        with pytest.raises(MetadataValidationError, match="not valid JSON"):
            brsdk.load(csv_path)

    def test_metadata_validation_missing_log_hz(
        self, mock_dataset_files: tuple[Path, Path]
    ) -> None:
        """Sidecar missing required log_hz must raise MetadataValidationError."""
        csv_path, json_path = mock_dataset_files
        bad = dict(REAL_SESSION_JSON)
        del bad["log_hz"]
        json_path.write_text(json.dumps(bad), encoding="utf-8")
        with pytest.raises(MetadataValidationError, match="validation failed"):
            brsdk.load(csv_path)

    def test_malformed_csv_empty(self, mock_dataset_files: tuple[Path, Path]) -> None:
        """An empty CSV must raise DatasetFormatError."""
        csv_path, _ = mock_dataset_files
        csv_path.write_text("", encoding="utf-8")
        with pytest.raises(DatasetFormatError, match="empty"):
            brsdk.load(csv_path)

    def test_malformed_csv_missing_columns(
        self, mock_dataset_files: tuple[Path, Path]
    ) -> None:
        """CSV without required columns must raise DatasetFormatError."""
        csv_path, _ = mock_dataset_files
        csv_path.write_text("a,b,c\n1,2,3\n", encoding="utf-8")
        with pytest.raises(DatasetFormatError, match="Missing required BRSDK columns"):
            brsdk.load(csv_path)


# ---------------------------------------------------------------------------
# Dataset class unit tests
# ---------------------------------------------------------------------------


class TestDataset:
    """Unit tests for the Dataset class properties."""

    def test_dataset_properties(self, mock_dataset_files: tuple[Path, Path]) -> None:
        """Dataset must expose all documented properties correctly."""
        csv_path, _ = mock_dataset_files
        dataset = brsdk.load(csv_path)

        assert dataset.path == csv_path.resolve()
        assert len(dataset) == 2
        assert "Dataset(" in repr(dataset)
        assert dataset.metadata["log_hz"] == 100
        assert dataset.metadata["vehicle_model"] == "Ibishu Pessima"
