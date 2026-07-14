test_that("execute_subprocess() validates code argument", {
  expect_error(execute_subprocess(123), "`code`")
  expect_error(execute_subprocess(c("a", "b")), "`code`")
})

test_that("execute_subprocess() validates threshold_mb", {
  expect_error(execute_subprocess("1", threshold_mb = -1), "`threshold_mb`")
  expect_error(execute_subprocess("1", threshold_mb = 0), "`threshold_mb`")
  expect_error(execute_subprocess("1", threshold_mb = "big"), "`threshold_mb`")
})

test_that("execute_subprocess() validates always_push", {
  expect_error(execute_subprocess("1", always_push = 42), "`always_push`")
})

test_that("execute_subprocess() validates timeout_s", {
  expect_error(execute_subprocess("1", timeout_s = 0), "`timeout_s`")
  expect_error(execute_subprocess("1", timeout_s = -1), "`timeout_s`")
  expect_error(execute_subprocess("1", timeout_s = "long"), "`timeout_s`")
})

test_that("execute_subprocess() captures numeric output", {
  skip_on_cran()
  reset_subprocess()
  on.exit(reset_subprocess())
  result <- execute_subprocess("1 + 1")
  expect_true(any(grepl("2", result$stdout)))
  expect_null(result$error)
})

test_that("execute_subprocess() captures errors", {
  skip_on_cran()
  reset_subprocess()
  on.exit(reset_subprocess())
  result <- execute_subprocess('stop("fail")')
  expect_false(is.null(result$error))
  expect_true(grepl("fail", result$error))
})

test_that("execute_subprocess() handles syntax errors gracefully", {
  skip_on_cran()
  reset_subprocess()
  on.exit(reset_subprocess())
  result <- execute_subprocess("if(TRUE {")
  expect_false(is.null(result$error))
})

test_that("execute_subprocess() returns plots list", {
  skip_on_cran()
  reset_subprocess()
  on.exit(reset_subprocess())
  result <- execute_subprocess("x <- 1")
  expect_type(result$plots, "list")
})

test_that("reset_subprocess() is idempotent", {
  expect_no_error(reset_subprocess())
  expect_no_error(reset_subprocess())
})

test_that("execute_subprocess() result has expected names", {
  skip_on_cran()
  reset_subprocess()
  on.exit(reset_subprocess())
  result <- execute_subprocess("TRUE")
  expected_names <- c("stdout", "stderr", "plots", "error", "warnings", "messages", "large")
  expect_true(all(expected_names %in% names(result)))
})
