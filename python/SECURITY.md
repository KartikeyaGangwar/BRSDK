# Security Policy

## Scope

This security policy covers the **brsdk Python SDK** (`pip install brsdk`).

It does not cover:

- The Lua telemetry scripts inside BeamNG.drive
  (those are governed by the main [BRSDK Security Policy](../SECURITY.md)).
- Third-party dependencies (report those directly to their maintainers).
- BeamNG.drive itself (report to [BeamNG GmbH](https://www.beamng.com)).

---

## Supported Versions

Only the latest published minor release receives security patches.

| Version  | Supported          |
| -------- | ------------------ |
| 0.1.x    | Yes (current)      |
| < 0.1.0  | No                 |

Once a new minor version is published (e.g., 0.2.0), the previous minor
(0.1.x) enters end-of-life unless a critical vulnerability requires a
back-port.

---

## Threat Model

The BRSDK Python SDK is a **data-loading library**. It reads files from the
local filesystem and returns in-memory data structures. It does not:

- Open network sockets
- Execute arbitrary code from dataset files
- Deserialise untrusted pickled Python objects
- Access credentials or secrets

The primary security surface is **file parsing**:

| Attack vector | Mitigated by |
|---------------|-------------|
| Malformed CSV causing memory exhaustion | PyArrow parser limits; process-level OS limits |
| Malformed JSON (`session.json`) causing code injection | Pydantic V2 strict validation; no `eval()` or `exec()` used |
| Path traversal via `brsdk.load()` argument | `pathlib.Path.resolve()` used internally |
| Supply-chain attack via dependencies | SBOM generated at release; Trusted Publishing via OIDC |

---

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Please disclose privately using one of these channels:

1. **GitHub Private Security Advisory** (preferred):
   Navigate to the repository → Security → Advisories → New draft advisory.

2. **Email**: Send a detailed report to the maintainers. Include in your report:
   - A description of the vulnerability and its potential impact
   - Steps to reproduce (minimal reproducible example if possible)
   - The version of `brsdk` you tested against
   - Your Python version and operating system

We will acknowledge receipt within **72 hours** and aim to publish a fix within
**14 days** for critical issues and **30 days** for moderate issues.

---

## Disclosure Policy

We follow the
[CERT/CC 45-day coordinated disclosure](https://resources.sei.cmu.edu/library/asset-view.cfm?assetid=538483)
timeline. Once a fix is released we will:

1. Publish a GitHub Security Advisory (CVE requested if severity ≥ Medium).
2. Release a patch version to PyPI.
3. Add an entry to `CHANGELOG.md` under the patch release.

---

## Dependency Management

All dependencies are pinned in the `uv.lock` file committed to the repository.
Dependabot is configured to open pull requests for dependency updates weekly.
Security updates from Dependabot are treated as high-priority and merged within
7 days of opening.
