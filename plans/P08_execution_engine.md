---
plan: P08
title: Code Execution Engine
status: not started
---

## Objective
Implement the hybrid execution model: evaluate::evaluate() for user-selected code (main session), callr::r_session for Claude-generated code (isolated subprocess).

## Execution paths

### Path A — User code (main session)
- Use `evaluate::evaluate()` with `new_device = TRUE`
- Captures: stdout, stderr, messages, warnings, errors, plots
- Runs in current global environment (full access to user objects)
- Output structured as list: `$stdout`, `$stderr`, `$plots`, `$error`

### Path B — Claude-generated code (subprocess)
- Use `callr::r_session` (persistent across conversation)
- Objects pushed into subprocess via dependency analysis (see P09)
- Same structured output returned via IPC
- Session reset option between conversations

## Plot capture
- Before execution: open PNG device to tempfile
- After execution: `dev.off()`, read PNG, base64 encode
- Only run plot capture if `codetools::findGlobals()` or heuristic detects plot function calls (saves tokens by not sending empty image blocks to Claude)
- Pass plots as `image` content blocks in Claude API messages

## Key files
- `R/execution/main_session.R`   # Path A: evaluate-based
- `R/execution/subprocess.R`     # Path B: callr r_session
- `R/execution/plot_capture.R`   # PNG device + base64 encoding
- `R/execution/output.R`         # Structured output builder

## Dependencies
P02, P09
