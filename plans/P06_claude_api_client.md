---
plan: P06
title: Claude API Client Layer
status: not started
---

## Objective
Implement an httr2-based Claude API client covering authentication, request/response modeling, error handling, and rate limiting.

## Tasks
- [ ] API key management: read from `ANTHROPIC_API_KEY` env var, fail with informative error if missing
- [ ] Base request builder: set headers, base URL, API version
- [ ] `chat_completion()`: send messages array, return structured response
- [ ] Streaming support: `chat_completion_stream()` with callback for incremental UI updates
- [ ] Tool result submission: send `tool_result` content blocks back to Claude
- [ ] Error handling: HTTP errors, malformed responses, network timeouts
- [ ] Rate limit handling: detect 429, back off and retry
- [ ] Model configuration: allow selecting Claude model (default: claude-sonnet-4-6)

## Key files
- `R/api/client.R`
- `R/api/auth.R`
- `R/api/request.R`
- `R/api/response.R`

## Dependencies
P02
