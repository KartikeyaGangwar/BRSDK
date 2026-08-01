# Security Policy

## Supported Versions

Currently, only the latest release of BRSDK is actively supported with security updates.

| Version | Supported          |
| ------- | ------------------ |
| 0.1.0   | :white_check_mark: |
| < 0.1.0 | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability within BRSDK, please do NOT open a public issue. 

Instead, send an email detailing the vulnerability to `security@placeholder-domain.com`. All security vulnerabilities will be promptly addressed.

*Note: BRSDK executes entirely within the sandboxed BeamNG Lua Virtual Machine. However, since it performs File I/O for logging, directory traversal bugs or malicious configuration injection vectors are treated as critical.*
