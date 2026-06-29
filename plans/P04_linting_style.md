---
plan: P04
title: Code Style & Linting Configuration
status: not started
---

## Objective
Configure lintr and styler for consistent code style across the package. Establish the style guide and editor integration.

## Tasks
- [ ] Finalize `.lintr` configuration (line length, naming convention, exclusions)
- [ ] Add `styler` to dev dependencies in DESCRIPTION
- [ ] Create `.styler.R` or configure via `styler::style_pkg()` defaults
- [ ] Add pre-commit hook or CI step to enforce style (see P05)
- [ ] Document style decisions in CONTRIBUTING.md

## Key decisions
- Line length: 120 characters
- Naming: snake_case for functions and variables
- Style guide: tidyverse style (styler default)

## Dependencies
P02
