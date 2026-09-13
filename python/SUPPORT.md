# Support

## Before Asking for Help

Please search the following resources before opening an issue:

1. [Documentation](https://KartikeyaGangwar.github.io/BRSDK) — API reference,
   tutorials, and architecture specs.
2. [GitHub Issues](https://github.com/KartikeyaGangwar/BRSDK/issues) — closed
   issues often contain the answer.
3. [CHANGELOG.md](CHANGELOG.md) — the problem may already be fixed in a newer
   version.

---

## How to Get Help

| Channel | Use for |
|---------|---------|
| [GitHub Discussions](https://github.com/KartikeyaGangwar/BRSDK/discussions) | General questions, research workflow help, feature ideas |
| [GitHub Issues](https://github.com/KartikeyaGangwar/BRSDK/issues/new) | Confirmed bugs and missing documentation |
| [GitHub Security Advisories](https://github.com/KartikeyaGangwar/BRSDK/security) | Vulnerability reports (do **not** use public issues) |

**Commercial support is not available.**
BRSDK is maintained on a volunteer basis by researchers.
Response times are best-effort.

---

## Filing a Bug Report

A good bug report includes:

```
brsdk version  : (output of `python -c "import brsdk; print(brsdk.__version__)"`)
Python version : (output of `python --version`)
OS             : (e.g. Windows 11, Ubuntu 24.04)
Polars version : (output of `python -c "import polars; print(polars.__version__)"`)
PyArrow version: (output of `python -c "import pyarrow; print(pyarrow.__version__)"`)

Steps to reproduce:
1.
2.

Expected behaviour:

Actual behaviour:

Minimal reproducible example (no external dataset files — generate synthetic data):
```

Reports without a minimal reproducible example may be closed without
investigation.

---

## Filing a Feature Request

Before requesting a new feature:

- Check that it is not already covered by a planned release in
  [CHANGELOG.md](CHANGELOG.md) or an open issue.
- Consider whether it belongs in `brsdk` itself or in a downstream library
  that extends `brsdk` via the reader/exporter protocol.
- API additions require an RFC. See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Version Support

Only the **latest published minor version** receives support.
If you are on an older version, please upgrade before filing a report:

```bash
pip install --upgrade brsdk
# or
uv add brsdk
```
