test_that("user_message() builds correct structure", {
  msg <- user_message("hello")
  expect_equal(msg$role, "user")
  expect_equal(msg$content, "hello")
})

test_that("assistant_message() builds correct structure", {
  msg <- assistant_message("hi back")
  expect_equal(msg$role, "assistant")
  expect_equal(msg$content, "hi back")
})

test_that("text_block() builds correct structure", {
  b <- text_block("some text")
  expect_equal(b$type, "text")
  expect_equal(b$text, "some text")
})

test_that("image_block() builds correct structure", {
  b <- image_block("abc123")
  expect_equal(b$type, "image")
  expect_equal(b$source$type, "base64")
  expect_equal(b$source$media_type, "image/png")
  expect_equal(b$source$data, "abc123")
})

test_that("image_block() accepts custom media_type", {
  b <- image_block("data", media_type = "image/jpeg")
  expect_equal(b$source$media_type, "image/jpeg")
})

test_that("tool_result_message() wraps content in a user message", {
  msg <- tool_result_message("tool_123", list(text_block("output")))
  expect_equal(msg$role, "user")
  expect_equal(msg$content[[1]]$type, "tool_result")
  expect_equal(msg$content[[1]]$tool_use_id, "tool_123")
  expect_null(msg$content[[1]]$is_error)
})

test_that("tool_result_message() sets is_error when requested", {
  msg <- tool_result_message("id", list(text_block("err")), is_error = TRUE)
  expect_true(msg$content[[1]]$is_error)
})

test_that("stop_reason() extracts stop_reason", {
  resp <- list(stop_reason = "end_turn")
  expect_equal(stop_reason(resp), "end_turn")
})

test_that("has_tool_calls() returns TRUE for tool_use", {
  expect_true(has_tool_calls(list(stop_reason = "tool_use")))
  expect_false(has_tool_calls(list(stop_reason = "end_turn")))
})

test_that("extract_tool_calls() returns only tool_use blocks", {
  resp <- list(content = list(
    list(type = "text", text = "hi"),
    list(type = "tool_use", id = "t1", name = "fn", input = list())
  ))
  calls <- extract_tool_calls(resp)
  expect_length(calls, 1L)
  expect_equal(calls[[1]]$type, "tool_use")
})

test_that("extract_text() concatenates text blocks", {
  resp <- list(content = list(
    list(type = "text", text = "Hello"),
    list(type = "tool_use", id = "x", name = "fn", input = list()),
    list(type = "text", text = " world")
  ))
  expect_equal(extract_text(resp), "Hello world")
})

test_that("parse_sse_line() returns NULL for non-data lines", {
  expect_null(RAiddin:::parse_sse_line("event: message_start"))
  expect_null(RAiddin:::parse_sse_line("data: [DONE]"))
  expect_null(RAiddin:::parse_sse_line(""))
})

test_that("parse_sse_line() parses valid data lines", {
  line <- 'data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"hi"}}'
  result <- RAiddin:::parse_sse_line(line)
  expect_equal(result$type, "content_block_delta")
  expect_equal(result$delta$text, "hi")
})

test_that("chat_completion() calls the API and returns parsed response", {
  fixture <- jsonlite::read_json(
    testthat::test_path("../fixtures/response_end_turn.json")
  )
  httr2::local_mocked_responses(
    httr2::response(
      status_code = 200L,
      headers     = list(`content-type` = "application/json"),
      body        = charToRaw(jsonlite::toJSON(fixture, auto_unbox = TRUE))
    )
  )
  withr::local_envvar(ANTHROPIC_API_KEY = "test-key")
  resp <- chat_completion(list(user_message("hi")))
  expect_equal(resp$stop_reason, "end_turn")
  expect_equal(resp$content[[1]]$text, "Hello, world!")
})
