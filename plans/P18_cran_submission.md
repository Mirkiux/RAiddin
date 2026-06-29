---
plan: P18
title: CRAN Submission Preparation
status: not started
---

## Objective
Prepare the package for CRAN submission following all CRAN policies and passing all automated checks.

## CRAN policy checklist
- [ ] No calls to `install.packages()` in package code
- [ ] No internet access in tests (mock all API calls)
- [ ] `\dontrun{}` around examples that require API key
- [ ] No writing outside tempdir/R_user_dir without user permission
- [ ] DESCRIPTION `Description` field is a complete sentence, no package name in title
- [ ] All imported packages listed in DESCRIPTION `Imports`
- [ ] LICENSE file matches DESCRIPTION License field
- [ ] NEWS.md follows standard format

## Pre-submission checks
- [ ] `devtools::check(remote = TRUE, manual = TRUE)` — 0 errors, 0 warnings, ≤1 note
- [ ] `devtools::check_win_devel()` — win-builder devel
- [ ] `devtools::check_win_release()` — win-builder release  
- [ ] `rhub::check_for_cran()` — R-hub multi-platform
- [ ] `urlchecker::url_check()` — all URLs resolve
- [ ] Spell check: `spelling::spell_check_package()`

## Submission
- [ ] Update `cran-comments.md` with check results
- [ ] `devtools::release()` submission wizard

## Dependencies
P15, P16, P17
