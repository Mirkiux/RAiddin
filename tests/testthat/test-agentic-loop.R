make_end_turn_response <- function(text = "Done.") {
  list(
    role        = "assistant",
    content     = list(list(type = "text", text = text)),
    stop_reason = "end_turn",
    usage       = list(input_tokens = 5L, output_tokens = 3L)
  )
}

make_tool_use_response <- function(tool_id = "t1", code = "1+1") {
  list(
    role = "assistant",
    content = list(
      list(type = "text", text = "Running code."),
      list(
        type = "tool_use", id = tool_id, name = "execute_r_code",
        input = list(code = code, session = "main")
      )
    ),
    stop_reason = "tool_use",
    usage = list(input_tokens = 10L, output_tokens = 8L)
  )
}

test_that("run_agentic_loop() validates messages", {
  expect_error(run_agentic_loop(list()), "`messages`")
  expect_error(run_agentic_loop("not a list"), "`messages`")
})

test_that("run_agentic_loop() validates max_turns", {
  msgs <- list(user_message("hi"))
  expect_error(run_agentic_loop(msgs, max_turns = 0), "`max_turns`")
  expect_error(run_agentic_loop(msgs, max_turns = NA), "`max_turns`")
  expect_error(run_agentic_loop(msgs, max_turns = Inf), "`max_turns`")
  expect_error(run_agentic_loop(msgs, max_turns = -1), "`max_turns`")
})

test_that("run_agentic_loop() validates envir", {
  msgs <- list(user_message("hi"))
  expect_error(run_agentic_loop(msgs, envir = "not an env"), "`envir`")
})

test_that("run_agentic_loop() stops immediately on end_turn", {
  calls <- 0L
  local_mocked_bindings(
    chat_completion = function(...) {
      calls <<- calls + 1L
      make_end_turn_response()
    },
    .package = "RAiddin"
  )
  result <- run_agentic_loop(list(user_message("hi")))
  expect_equal(calls, 1L)
  expect_equal(result$turns, 0L)
  expect_false(result$hit_limit)
  expect_equal(stop_reason(result$response), "end_turn")
})

test_that("run_agentic_loop() handles one tool-use turn", {
  responses <- list(
    make_tool_use_response("tid1", "2 + 2"),
    make_end_turn_response("4")
  )
  idx <- 0L
  local_mocked_bindings(
    chat_completion = function(...) {
      idx <<- idx + 1L
      responses[[idx]]
    },
    .package = "RAiddin"
  )
  local_mocked_bindings(
    check_code_approval = function(code) list(approved = TRUE, reason = "auto_approve"),
    .package = "RAiddin"
  )
  local_mocked_bindings(
    execute_main_session = function(code, ...) {
      build_execution_output(stdout = "4", stderr = character(0))
    },
    .package = "RAiddin"
  )
  result <- run_agentic_loop(list(user_message("what is 2+2?")))
  expect_equal(result$turns, 1L)
  expect_equal(stop_reason(result$response), "end_turn")
})

test_that("run_agentic_loop() stops at max_turns", {
  local_mocked_bindings(
    chat_completion = function(...) make_tool_use_response(),
    .package = "RAiddin"
  )
  local_mocked_bindings(
    check_code_approval = function(...) list(approved = TRUE, reason = "auto_approve"),
    .package = "RAiddin"
  )
  local_mocked_bindings(
    execute_main_session = function(...) build_execution_output(),
    .package = "RAiddin"
  )
  result <- run_agentic_loop(list(user_message("hi")), max_turns = 2L)
  expect_equal(result$turns, 2L)
  expect_true(result$hit_limit)
})
