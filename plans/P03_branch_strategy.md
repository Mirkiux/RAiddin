---
plan: P03
title: Branch Strategy & Protection Rules
status: not started
---

## Objective
Define branching model, configure GitHub branch protection rules, and establish PR merge requirements.

## Tasks
- [ ] Define branching model: `main` (stable), `dev` (integration), `feature/*`, `fix/*`, `release/*`
- [ ] Set branch protection on `main`: require PR, require CI pass, no direct push
- [ ] Set branch protection on `dev`: require CI pass
- [ ] Define PR template
- [ ] Configure required reviewers (if applicable)
- [ ] Define squash vs merge commit strategy

## Dependencies
P02
