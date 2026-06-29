---
plan: P07
title: Tool Definitions & Agentic Loop
status: not started
---

## Objective
Define all tools exposed to Claude via the API and implement the agentic loop that runs until Claude returns `end_turn`.

## Tools to define (JSON schema + R handler)

| Tool | Description |
|---|---|
| `execute_r_code` | Execute R code, return stdout/stderr/plots |
| `get_selected_code` | Return currently selected text in RStudio editor |
| `get_document_context` | Return full source of active document + cursor position |
| `insert_code_to_editor` | Insert code at cursor or end of document |
| `replace_selection` | Replace current selection with new code |

## Agentic loop logic
```
call_claude(messages, tools)
  while stop_reason == "tool_use":
    for each tool_call in response:
      result = dispatch_tool(tool_call)       # R executes the tool
      approval = request_approval(tool_call)  # if required (see P11)
    messages += [assistant_msg, tool_results]
    response = call_claude(messages, tools)
  return final response
```

## Key files
- `R/tools/definitions.R`   # JSON schemas for all tools
- `R/tools/dispatcher.R`    # Routes tool_use calls to R handlers
- `R/tools/loop.R`          # Agentic loop implementation

## Dependencies
P06, P08, P11, P12
