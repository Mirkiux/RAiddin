---
plan: P03
title: Branch Strategy & Protection Rules
status: completed
---

## Objective
Define branching model, configure GitHub branch protection rules, and establish PR merge requirements.

## Branching model
| Branch | Purpose | Protection |
|---|---|---|
| `main` | Stable, CRAN-ready | Require PR, no force push, no direct push |
| `dev` | Integration branch | No force push; CI required once P05 lands |
| `feature/*` | New features | No protection |
| `fix/*` | Bug fixes | No protection |
| `release/*` | Release prep | No protection |

## Merge strategy
- `main` ← `dev`: merge commit (preserves history)
- `dev` ← feature/fix: squash merge (clean linear history)
- Rebase merges disabled

## Outcomes
- [x] Branching model defined (above)
- [x] `dev` branch created and pushed
- [x] `main` protection: no force push, no deletions, PR required (0 approvals — solo project), status checks wired in P05
- [x] `dev` protection: no force push, no deletions
- [x] PR template created at `.github/pull_request_template.md`

## Notes
Required status checks on `main` will be activated in P05 once GitHub Actions workflows are deployed. Protection is in place now without blocking the CI-less bootstrap phase.

## Dependencies
P02
