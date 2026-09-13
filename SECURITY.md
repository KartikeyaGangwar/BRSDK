# Security Policy

## Supported Versions

Currently, only the latest release of BRSDK is actively supported with security updates.

| Version | Supported |
| ------- | --------- |
| 2.0.0   | Yes       |
| < 2.0.0 | No        |

## Reporting a Vulnerability

If you discover a security vulnerability within BRSDK, please do not open a public issue. 

Please report vulnerabilities privately via GitHub Security Advisories:
https://github.com/KartikeyaGangwar/BRSDK/security/advisories/new

Alternatively, contact the maintainer directly at `kartikeysingh525@protonmail.com`.

*Note: BRSDK executes entirely within the sandboxed BeamNG Lua Virtual Machine. However, since it performs File I/O for logging, directory traversal bugs or malicious configuration injection vectors are treated as critical.*
