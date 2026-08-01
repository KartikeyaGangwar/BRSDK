"""BRSDK metadata sub-package.

Pydantic V2 models that represent the ``session.json`` sidecar produced
by the Lua telemetry framework alongside every CSV recording.

Public surface
--------------
:class:`SessionMetadata` — top-level validated model.

All other classes in this package are internal implementation details.
"""

from __future__ import annotations

from brsdk.metadata.models import SessionMetadata

__all__: list[str] = ["SessionMetadata"]
