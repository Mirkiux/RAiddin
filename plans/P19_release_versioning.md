---
plan: P19
title: Release & Versioning Strategy
status: not started
---

## Objective
Define semantic versioning rules, changelog format, GitHub release process, and CRAN update cadence.

## Versioning scheme
- Development: `0.0.0.9000` (fourth component signals dev)
- CRAN releases: `MAJOR.MINOR.PATCH`
  - MAJOR: breaking API changes
  - MINOR: new features, backward compatible
  - PATCH: bug fixes only

## Release process
1. Ensure all CI checks pass on `dev`
2. Bump version in DESCRIPTION
3. Update `NEWS.md` with release notes
4. Merge `dev` → `main` via PR
5. Tag release: `git tag v1.0.0`
6. Create GitHub Release with NEWS.md content as body
7. Submit to CRAN (see P18)

## NEWS.md format
```
# RAiddin 1.0.0

## New features
* ...

## Bug fixes
* ...

## Breaking changes
* ...
```

## GitHub Releases
- Auto-generate release notes from merged PRs via GitHub Actions on tag push
- Attach source tarball (devtools::build())

## CRAN cadence
- Aim for CRAN releases no more frequently than every 1-2 months
- Bug-fix patches on CRAN only for critical issues

## Dependencies
P15, P16, P17, P18
