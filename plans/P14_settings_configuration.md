---
plan: P14
title: User Settings & Configuration
status: completed
---

## Objective
Implement persistent user configuration for model selection, API key setup, approved commands, environment thresholds, and addin preferences.

## Settings storage
- Location: `~/.raiddin/config.yaml`
- Written/read via `R/utils/config.R`
- Never stored in the package directory or committed to git

## Configurable options

| Option | Default | Description |
|---|---|---|
| `model` | `claude-sonnet-4-6` | Claude model to use |
| `api_key_source` | `"env"` | Where to read API key (`"env"` or `"keyring"`) |
| `auto_approve` | `FALSE` | Skip code approval prompts |
| `env_size_threshold_mb` | `50` | Max object size for auto-push to subprocess |
| `always_push` | `[]` | Object names always replicated to subprocess |
| `approved_patterns` | `[]` | Code patterns pre-approved for execution |
| `stream_responses` | `TRUE` | Enable streaming in chat panel |
| `max_tokens` | `8192` | Max tokens per Claude response |

## Setup flow
- `raiddin_setup()`: interactive wizard for first-time configuration
  - Prompts for API key (stored in env or system keyring via `keyring` package)
  - Sets model preference
  - Tests connectivity

## Key files
- `R/utils_config.R`
- `R/utils_setup.R`

## Dependencies
P02
