# Contributing to RAiddin

## Branching model

| Branch | Purpose |
|---|---|
| `main` | Stable, CRAN-ready |
| `dev` | Integration — target for all PRs |
| `feature/<plan>` | New features |
| `fix/<description>` | Bug fixes |
| `release/<version>` | Release prep |

Open PRs against `dev`, not `main`. `dev` is merged to `main` at release points.

## Setting up pre-commit

All style and quality checks run automatically via [pre-commit](https://pre-commit.com) hooks.

### Install pre-commit

```bash
# via pip
pip install pre-commit

# or via conda
conda install -c conda-forge pre-commit
```

### Install the R hook dependencies

```r
install.packages("precommit")  # lorenzwalthert/precommit
precommit::install_hooks()
```

### Activate hooks for this repo

```bash
pre-commit install
pre-commit install --hook-type commit-msg
```

### Run hooks manually on all files

```bash
pre-commit run --all-files
```

The `pkgdown` hook requires the `pkgdown` R package. Until it is installed (P16), skip it locally:

```bash
SKIP=pkgdown pre-commit run --all-files
```

## Code style

- **Style guide**: [tidyverse style](https://style.tidyverse.org/) enforced by `styler`
- **Line length**: 120 characters maximum
- **Naming**: `snake_case` for all functions and variables
- **No `print()`, `browser()`, or `debug()` calls** in committed code

The `style-files` hook auto-formats your code on every commit. You will rarely need to run `styler` manually.

## Linting

`lintr` runs on every commit via the `lintr` pre-commit hook, using the rules in `.lintr`. Fix all lint errors before pushing. CI enforcement will be added in P05.

## Documentation

- All exported functions must have `roxygen2` documentation (`@param`, `@return`, `@export`)
- The `roxygenize` hook regenerates `man/` automatically on each commit
- Do not edit files in `man/` by hand

## Spell checking

Custom project terms are listed in `inst/WORDLIST`. If the spell-check hook flags a legitimate project-specific word, add it to `WORDLIST` and re-commit.

## Tests

- Tests live in `tests/testthat/`
- Run locally with `devtools::test()`
- Aim for ≥ 80% line coverage (CI enforcement via `covr` will be added in P05)
- Mock all external API calls — tests must pass offline

## Commit messages

Use the format: `type(scope): short description`

Common types: `feat`, `fix`, `docs`, `test`, `refactor`, `ci`

Example: `feat(P06): implement Claude API client with httr2`
