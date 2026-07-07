test_that(".code_to_function() returns NULL on syntax error", {
  result <- RAiddin:::.code_to_function("if(TRUE {")
  expect_null(result)
})

test_that(".code_to_function() wraps valid code in a function", {
  fn <- RAiddin:::.code_to_function("x + 1")
  expect_type(fn, "closure")
})

test_that("analyze_code_dependencies() returns empty for no globals", {
  deps <- analyze_code_dependencies("1 + 1")
  expect_equal(deps, character(0))
})

test_that("analyze_code_dependencies() finds object references in envir", {
  env <- new.env(parent = emptyenv())
  env$my_var <- 42L
  deps <- analyze_code_dependencies("my_var * 2", envir = env)
  expect_true("my_var" %in% deps)
})

test_that("analyze_code_dependencies() ignores objects not in envir", {
  env <- new.env(parent = emptyenv())
  deps <- analyze_code_dependencies("nonexistent_var", envir = env)
  expect_equal(deps, character(0))
})

test_that("analyze_code_dependencies() returns empty on syntax error", {
  deps <- analyze_code_dependencies("if(TRUE {")
  expect_equal(deps, character(0))
})

test_that("analyze_code_dependencies() finds dot-prefixed names with all.names", {
  env <- new.env(parent = emptyenv())
  env$.hidden <- 1L
  deps <- analyze_code_dependencies(".hidden + 1", envir = env)
  expect_true(".hidden" %in% deps)
})

test_that("uses_plot_functions() returns FALSE for non-plot code", {
  expect_false(uses_plot_functions("x <- 1 + 1"))
  expect_false(uses_plot_functions("mean(c(1,2,3))"))
})

test_that("uses_plot_functions() returns TRUE for base plot", {
  expect_true(uses_plot_functions("plot(1:10)"))
})

test_that("uses_plot_functions() returns TRUE for hist", {
  expect_true(uses_plot_functions("hist(rnorm(100))"))
})

test_that("uses_plot_functions() returns TRUE for ggplot prefix functions", {
  expect_true(uses_plot_functions("ggplot(df, aes(x,y)) + geom_point()"))
})

test_that("uses_plot_functions() returns FALSE on syntax error", {
  expect_false(uses_plot_functions("if(TRUE {"))
})
