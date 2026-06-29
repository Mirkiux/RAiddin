---
plan: P06
title: Claude API Client Layer
status: completed
---

## Objective
Implement an httr2-based Claude API client covering authentication, request/response modeling, error handling, and rate limiting.

## Tasks
- [x] API key management: read from `ANTHROPIC_API_KEY` env var, fail with informative error if missing
- [x] Base request builder: set headers, base URL, API version
- [x] `chat_completion()`: send messages array, return structured response
- [x] Streaming support: `chat_completion_stream()` with callback for incremental UI updates
- [x] Tool result submission: send `tool_result` content blocks back to Claude
- [x] Error handling: HTTP errors, malformed responses, network timeouts
- [x] Rate limit handling: detect 429/529, back off and retry (max 3 tries)
- [x] Model configuration: allow selecting Claude model via `raiddin.model` option (default: claude-sonnet-4-6)

## Key files
- `R/api/client.R`
- `R/api/auth.R`
- `R/api/request.R`
- `R/api/response.R`

## Dependencies
P02
