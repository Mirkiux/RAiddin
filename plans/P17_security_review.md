---
plan: P17
title: Security Review
status: not started
---

## Objective
Audit the full package for security risks: API key handling, arbitrary code execution surface, subprocess sandboxing limits, and user guidance.

## Review areas

### API key handling
- Confirm key never logged, never included in error messages
- Confirm key never written to disk by the package
- Review keyring integration if used

### Code execution risk surface
- Arbitrary R code execution is inherently powerful — document clearly
- Confirm callr subprocess does not inherit unexpected privileges
- Review timeout enforcement (prevent infinite loops)
- Review resource limits (memory, CPU) for subprocess

### Approval system audit
- Confirm approval bypass is only possible via explicit user opt-in
- Review pattern matching for approval rules (no regex injection)

### Network
- Confirm only api.anthropic.com is called
- Confirm no telemetry or data sent elsewhere
- Review SSL/TLS handling (httr2 default is secure)

### Dependency audit
- Run `pak::pkg_deps_tree()` to review full dependency chain
- Check each dependency for known CVEs

## Output
- Security findings document
- Risk-rated issue list
- Updates to `vignettes/security-model.Rmd`

## Dependencies
P06, P07, P08, P09, P11, P14
