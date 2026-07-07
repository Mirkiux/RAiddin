test_that("execute_main_session() validates code argument", {
  expect_error(execute_main_session(123), "`code`")
  expect_error(execute_main_session(c("a", "b")), "`code`")
  expect_error(execute_main_session(NA_character_), "`code`")
})

test_that("execute_main_session() validates envir argument", {
  expect_error(execute_main_session("1", envir = "not_env"), "`envir`")
})

test_that("execute_main_session() captures numeric output", {
  result <- execute_main_session("1 + 1")
  expect_type(result, "list")
  expect_true(any(grepl("2", result$stdout)))
  expect_null(result$error)
})

test_that("execute_main_session() captures character output", {
  result <- execute_main_session('"hello"')
  expect_true(any(grepl("hello", result$stdout)))
})

test_that("execute_main_session() captures warnings", {
  result <- execute_main_session('warning("test warning")')
  expect_true(any(grepl("test warning", result$warnings)))
  expect_null(result$error)
})

test_that("execute_main_session() captures messages", {
  result <- execute_main_session('message("test message")')
  expect_true(any(grepl("test message", result$messages)))
  expect_null(result$error)
})

test_that("execute_main_session() captures errors without stopping", {
  result <- execute_main_session('stop("intentional error")')
  expect_false(is.null(result$error))
  expect_true(grepl("intentional error", result$error))
})

test_that("execute_main_session() returns empty plots for non-plot code", {
  result <- execute_main_session("x <- 1")
  expect_type(result$plots, "list")
  expect_length(result$plots, 0L)
})

test_that("execute_main_session() returns correct structure", {
  result <- execute_main_session("42L")
  expect_named(result, c("stdout", "stderr", "plots", "error", "warnings", "messages"))
})

test_that("execute_main_session() evaluates in supplied environment", {
  env <- new.env(parent = baseenv())
  env$x <- 99L
  result <- execute_main_session("x", envir = env)
  expect_true(any(grepl("99", result$stdout)))
})
