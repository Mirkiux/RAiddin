test_that("is_auto_approve() returns FALSE by default", {
  reset_session_approvals()
  expect_false(is_auto_approve())
})

test_that("set_auto_approve() changes the flag", {
  reset_session_approvals()
  set_auto_approve(TRUE)
  expect_true(is_auto_approve())
  set_auto_approve(FALSE)
  expect_false(is_auto_approve())
})

test_that("set_auto_approve() rejects non-logical", {
  expect_error(set_auto_approve("yes"), "`value`")
  expect_error(set_auto_approve(NA), "`value`")
  expect_error(set_auto_approve(1L), "`value`")
})

test_that("add_approved_pattern() and get_approved_patterns() round-trip", {
  reset_session_approvals()
  withr::with_tempdir({
    withr::local_envvar(HOME = getwd())
    add_approved_pattern("df %>%")
    pats <- get_approved_patterns()
    expect_true("df %>%" %in% pats)
  })
})

test_that("add_approved_pattern() rejects empty or multiline patterns", {
  expect_error(add_approved_pattern(""), "`pattern`")
  expect_error(add_approved_pattern("a\nb"), "`pattern`")
})

test_that("matches_approved_pattern() returns FALSE with no patterns", {
  reset_session_approvals()
  expect_false(matches_approved_pattern("anything"))
})

test_that("matches_approved_pattern() uses fixed-string matching", {
  reset_session_approvals()
  .approval_state <- RAiddin:::.approval_state
  .approval_state$session_patterns <- c("mean(x)")
  expect_true(matches_approved_pattern("result <- mean(x)"))
  expect_false(matches_approved_pattern("meanx"))
})

test_that("check_code_approval() returns approved=TRUE when auto-approve on", {
  reset_session_approvals()
  set_auto_approve(TRUE)
  result <- check_code_approval("rm(list=ls())")
  expect_true(result$approved)
  expect_equal(result$reason, "auto_approve")
  set_auto_approve(FALSE)
})

test_that("check_code_approval() returns requires_prompt by default", {
  reset_session_approvals()
  result <- check_code_approval("x <- 1")
  expect_false(result$approved)
  expect_equal(result$reason, "requires_prompt")
})

test_that("check_code_approval() validates code argument", {
  expect_error(check_code_approval(42), "`code`")
  expect_error(check_code_approval(c("a", "b")), "`code`")
})

test_that("reset_session_approvals() clears state", {
  set_auto_approve(TRUE)
  reset_session_approvals()
  expect_false(is_auto_approve())
})
