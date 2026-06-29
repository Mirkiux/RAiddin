---
plan: P04
title: Code Style & Linting Configuration
status: partially completed
---

## Objective
Configure lintr and styler for consistent code style across the package. Establish the style guide and editor integration.

## Already in place
`.pre-commit-config.yaml` (committed in P03) uses `lorenzwalthert/precommit` v0.4.3.9026 and covers:
- `style-files`: styler with tidyverse_style on every commit
- `lintr`: runs lintr on every commit (uses `.lintr` config)
- `roxygenize`: regenerates man/ on every commit
- `use-tidy-description`: enforces DESCRIPTION field ordering
- `spell-check`: spellchecks docs (excludes R files, data, CI configs)
- `parsable-R`: syntax check on all .R files
- `no-browser-statement`, `no-print-statement`, `no-debug-statement`
- `deps-in-desc`: verifies all library() calls are in DESCRIPTION
- `readme-rmd-rendered`: enforces README.md is up to date with README.Rmd
- `pkgdown`: validates pkgdown config (skipped in pre-commit.ci)
- General hooks: trailing whitespace, end-of-file fixer, large file check (200 KB), YAML/JSON validation, merge conflict detection

`.lintr` already configured with:
- Line length: 120 characters
- Naming: snake_case
- `commented_code_linter` disabled

## Remaining tasks
- [ ] Add `styler` and `lintr` to `Suggests` in DESCRIPTION (needed for roxygenize hook's additional_dependencies)
- [ ] Add `WORDLIST` file for spell-check custom dictionary (project-specific terms: RAiddin, httr2, callr, rstudioapi, etc.)
- [ ] Create `CONTRIBUTING.md` documenting style decisions and pre-commit setup instructions
- [ ] Verify pre-commit hooks install and run cleanly: `pre-commit run --all-files`

## Key decisions
- Line length: 120 characters
- Naming: snake_case for functions and variables
- Style guide: tidyverse style (styler default)
- Enforcement: pre-commit hooks (local) + CI lint job (P05)

## Dependencies
P02, P03
