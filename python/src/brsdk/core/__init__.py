"""BRSDK core sub-package.

Contains the :class:`~brsdk.core.dataset.Dataset` class — the primary
object returned by :func:`brsdk.load`.

Public surface
--------------
:class:`Dataset` — immutable telemetry dataset.
"""

from __future__ import annotations

from brsdk.core.dataset import Dataset

__all__: list[str] = ["Dataset"]
