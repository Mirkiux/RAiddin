---
plan: P05
title: CI/CD Pipeline
status: completed
---

## Objective
Set up GitHub Actions workflows mirroring the featkit pattern: CI checks, docs deployment,
auto-tagging on version bumps, and automated GitHub Release + r-universe publishing.

## Package repository

CRAN is the official R package repository but submission is always **manual** (reviewed by
humans, takes days). It cannot be automated the way PyPI can.

The automated publish target is **r-universe** (`r-universe.dev`): a GitHub-connected
registry that auto-builds source and binary packages from every push to `main`. Once
registered, packages are installable via:

```r
install.packages("RAiddin", repos = "https://mirkiux.r-universe.dev")
```

CRAN submission remains a separate manual process covered in P18.

## r-universe registration (one-time setup)
- Create `https://github.com/Mirkiux/Mirkiux` repository (your r-universe namespace)
- Add a `packages.json` pointing to this repo
- r-universe picks it up automatically and rebuilds on every push to `main`

## Workflows implemented

| File | Trigger | Purpose |
|---|---|---|
| `check.yaml` | push/PR → main, dev | R CMD check matrix (Ubuntu/Windows/macOS × release/devel) |
| `lint.yaml` | push/PR → main, dev | lintr::lint_package() |
| `coverage.yaml` | push → main, dev | covr + Codecov upload |
| `pkgdown.yaml` | push → main | build and deploy pkgdown site to GitHub Pages |
| `auto-tag.yaml` | push → main (DESCRIPTION changed) | detect version bump, create git tag |
| `release.yaml` | tag push `v*` | build tarball, R CMD check --as-cran, create GitHub Release |

## Required secrets
| Secret | Purpose |
|---|---|
| `RELEASE_TOKEN` | PAT (`contents:write`) — tag push from auto-tag.yaml must trigger release.yaml |
| `CODECOV_TOKEN` | Codecov upload authentication |

## Status check wiring (P03 follow-up)
After first successful CI run, add required status checks to `main` branch protection:
- `R CMD check (ubuntu-latest, release)`
- `Lint`

## Notes
- Development versions (4-component, e.g., `0.0.0.9000`) are skipped by auto-tag.yaml
- r-universe auto-detects new `main` pushes — no extra CI step needed
- `pkgdown` hook failure documented in CONTRIBUTING.md is resolved: pkgdown runs in CI

## Dependencies
P02, P04, P15, P16
