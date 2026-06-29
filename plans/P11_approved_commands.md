---
plan: P11
title: Approved Commands System
status: not started
---

## Objective
Implement a code execution approval flow similar to Claude Code's bash command approval, giving users control over what Claude is allowed to run.

## Approval modes
- **Always ask**: every code execution shows an approval prompt (safest)
- **Auto-approve**: Claude runs code without prompting (fastest, for trusted sessions)
- **Pattern-based**: user defines allowed patterns (e.g., "read-only", "no file writes")

## Approval UI
- Modal dialog showing the code block Claude wants to execute
- Buttons: **Approve**, **Deny**, **Always Allow This Pattern**
- For large objects: separate prompt listing object name + size, buttons: **Push**, **Skip**, **Always Push**

## Persistent approved patterns
- Stored in user-level config file: `~/.raiddin/approved_patterns.yaml`
- Patterns matched against code before showing prompt
- Manageable via `raiddin_manage_approvals()` addin

## Session-level "always allow"
- Toggle in chat panel UI (see P13)
- Resets on session restart

## Key files
- `R/execution/approval.R`
- `R/ui/approval_modal.R`
- `R/utils/config.R`

## Dependencies
P02, P13
