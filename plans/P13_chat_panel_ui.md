---
plan: P13
title: Chat Panel UI
status: not started
---

## Objective
Build the Shiny-based chat panel as a persistent RStudio Viewer pane gadget with chat history, tool call visualization, inline plots, and streaming display.

## UI components

### Chat history area
- Scrollable message list
- User messages styled differently from Claude messages
- Tool call blocks: collapsible, show tool name + inputs + outputs
- Inline plot thumbnails: rendered from base64, expandable on click
- Code blocks with syntax highlighting

### Input area
- Multi-line text input for user prompt
- Send button + keyboard shortcut (Ctrl+Enter)
- "Use selection" button: appends selected code to prompt
- "Use document" button: appends full document context

### Settings panel (collapsible)
- Model selector dropdown
- Auto-approve toggle (session-level)
- Environment size threshold slider
- Clear conversation button

### Status bar
- Shows current state: Idle / Thinking / Executing code / Waiting for approval
- Token usage counter (cumulative for session)

## Streaming
- Use `httr2` streaming response
- Update chat history incrementally as tokens arrive
- Show spinner during tool execution

## Key files
- `R/ui/chat_panel.R`        # Main gadget function
- `R/ui/components.R`        # Reusable UI components
- `R/ui/approval_modal.R`    # Code approval modal (see P11)
- `inst/shiny/www/styles.css`

## Dependencies
P06, P07, P11, P12
