---
plan: P05
title: CI/CD Pipeline
status: not started
---

## Objective
Set up GitHub Actions workflows for automated checking, linting, testing, coverage reporting, and pkgdown site deployment.

## Workflows to create

### R CMD check (`check.yaml`)
- Trigger: push and PR to main/dev
- Matrix: Ubuntu + Windows + macOS, R release + devel
- Steps: install deps, R CMD check --as-cran

### Linting (`lint.yaml`)
- Trigger: push and PR
- Run: lintr::lint_package()
- Fail on any linting errors

### Test coverage (`coverage.yaml`)
- Trigger: push to main/dev
- Run: covr::codecov()
- Upload to Codecov

### pkgdown site (`pkgdown.yaml`)
- Trigger: push to main
- Build and deploy to GitHub Pages

## Dependencies
P02, P04, P15, P16
