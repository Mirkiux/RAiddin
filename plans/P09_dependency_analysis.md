---
plan: P09
title: Dependency Analysis & Environment Replication
status: not started
---

## Objective
Implement the hybrid environment strategy: use codetools to identify required objects, lobstr to measure sizes, and selectively push objects into the callr subprocess.

## Strategy (in order of application)

1. **Static analysis**: `codetools::findGlobals(as.function(parse(text = code)))` to extract names referenced by the code.
2. **Filter to existing env objects**: intersect found globals with `ls(envir = .GlobalEnv)`.
3. **Size check**: `lobstr::obj_size()` on each candidate object.
   - Small objects (< threshold, default 50 MB): auto-push to r_session.
   - Large objects (>= threshold): show approval prompt to user (see P11).
4. **Push to subprocess**: `r_session$call(function(obj, name) assign(name, obj, envir = .GlobalEnv), args = list(obj, name))`.

## Plot detection heuristic
- Use `codetools::findGlobals()` to check if code references any known plot functions (`plot`, `ggplot`, `hist`, `barplot`, `boxplot`, etc.).
- If no plot function detected: skip PNG device setup entirely — avoids sending empty base64 image blocks to Claude, saving tokens.

## Configuration
- `raiddin_options$env_size_threshold`: max object size for auto-push (default 50 MB)
- `raiddin_options$always_push`: character vector of object names to always replicate

## Key files
- `R/execution/dependency_analysis.R`
- `R/execution/env_replication.R`

## Dependencies
P08
