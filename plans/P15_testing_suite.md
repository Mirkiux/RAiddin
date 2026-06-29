---
plan: P15
title: Testing Suite
status: not started
---

## Objective
Build a comprehensive test suite using testthat, with mocked Claude API responses for unit tests and real execution tests for the code execution engine.

## Test structure

### Unit tests (`tests/testthat/`)

| File | Coverage |
|---|---|
| `test-api-client.R` | Claude API client with mocked httr2 responses |
| `test-tool-definitions.R` | Tool JSON schema validation |
| `test-agentic-loop.R` | Loop logic with mocked API stop conditions |
| `test-execution-main.R` | evaluate-based execution, output capture |
| `test-execution-subprocess.R` | callr r_session lifecycle |
| `test-dependency-analysis.R` | codetools global detection, size filtering |
| `test-plot-capture.R` | PNG device capture, base64 encoding, plot detection heuristic |
| `test-approval.R` | Approval pattern matching logic |
| `test-editor-utils.R` | rstudioapi wrappers (mocked via rstudioapi stubs) |
| `test-config.R` | Config read/write |

### Mocking strategy
- Claude API: mock `httr2::req_perform()` responses with fixture JSON files in `tests/fixtures/`
- rstudioapi: provide stub functions via `local_mocked_bindings()`
- File system: use `withr::local_tempdir()` for plot capture tests

### Coverage target
- Minimum 80% line coverage enforced in CI via covr + Codecov

## Key files
- `tests/testthat/`
- `tests/fixtures/`   # Mock API response JSON files

## Dependencies
P06, P07, P08, P09, P10, P11, P12
