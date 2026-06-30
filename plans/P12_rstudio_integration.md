---
plan: P12
title: RStudio Editor Integrations
status: completed
---

## Objective
Implement all rstudioapi interactions for reading from and writing to the RStudio editor.

## Functions to implement

| Function | rstudioapi call | Description |
|---|---|---|
| `get_selection()` | `getSourceEditorContext()$selection` | Return selected text + range |
| `get_document()` | `getSourceEditorContext()$contents` | Return full document source |
| `get_cursor_position()` | `getSourceEditorContext()$selection[[1]]$range` | Return cursor row/col |
| `insert_at_cursor()` | `insertText(text)` | Insert text at current cursor |
| `replace_selection()` | `modifyRange(range, text)` | Replace selected range |
| `insert_at_end()` | `insertText(location, text)` | Append to document end |
| `get_active_file()` | `getSourceEditorContext()$path` | Return active file path |

All functions implemented in [R/utils/editor.R](../R/utils/editor.R).

## Edge cases
- [x] No active editor: fail gracefully with informative message
- [x] No selection when selection is required: prompt user to select code first
- [x] Read-only documents: detect and warn before attempting write operations

## Key files
- `R/utils/editor.R`

## Dependencies
P02
