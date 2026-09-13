# Security Policy

## Supported Versions

Currently, only the latest release of BRSDK is actively supported with security updates.

| Version | Supported |
| ------- | --------- |
| 0.1.0   | Yes       |
| < 0.1.0 | No        |

## Reporting a Vulnerability

If you discover a security vulnerability within BRSDK, please do not open a public issue. 

Instead, submit a private advisory through GitHub Security Advisories:
https://github.com/KartikeyaGangwar/BRSDK/security/advisories/new

*Note: BRSDK executes entirely within the sandboxed BeamNG Lua Virtual Machine. However, since it performs File I/O for logging, directory traversal bugs or malicious configuration injection vectors are treated as critical.*
