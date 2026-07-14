make_ctx <- function(text = "selected text", contents = c("line1", "line2"),
                     row = 1L, col = 1L, path = "/tmp/test.R") {
  list(
    id = "doc-1",
    path = path,
    contents = contents,
    selection = list(list(
      text = text,
      range = list(
        start = list(row = row, column = col),
        end   = list(row = row, column = col + nchar(text))
      )
    ))
  )
}

test_that("get_selection() returns text and range from editor", {
  local_mocked_bindings(
    isAvailable = function(...) TRUE,
    getSourceEditorContext = function(...) make_ctx("foo bar"),
    .package = "rstudioapi"
  )
  result <- get_selection()
  expect_equal(result$text, "foo bar")
})

test_that("get_document() pastes all lines", {
  local_mocked_bindings(
    isAvailable = function(...) TRUE,
    getSourceEditorContext = function(...) make_ctx(contents = c("a <- 1", "b <- 2")),
    .package = "rstudioapi"
  )
  doc <- get_document()
  expect_equal(doc, "a <- 1\nb <- 2")
})

test_that("get_cursor_position() extracts row and column", {
  local_mocked_bindings(
    isAvailable = function(...) TRUE,
    getSourceEditorContext = function(...) make_ctx(row = 5L, col = 10L),
    .package = "rstudioapi"
  )
  pos <- get_cursor_position()
  expect_equal(pos$row, 5L)
  expect_equal(pos$column, 10L)
})

test_that("get_active_file() returns document path", {
  local_mocked_bindings(
    isAvailable = function(...) TRUE,
    getSourceEditorContext = function(...) make_ctx(path = "/home/user/script.R"),
    .package = "rstudioapi"
  )
  expect_equal(get_active_file(), "/home/user/script.R")
})

test_that("get_active_file() errors on unsaved document", {
  local_mocked_bindings(
    isAvailable = function(...) TRUE,
    getSourceEditorContext = function(...) make_ctx(path = ""),
    .package = "rstudioapi"
  )
  expect_error(get_active_file(), "not been saved")
})

test_that("get_editor_context() errors when RStudio unavailable", {
  local_mocked_bindings(
    isAvailable = function(...) FALSE,
    .package    = "rstudioapi"
  )
  expect_error(RAiddin:::get_editor_context(), "RStudio")
})

test_that("insert_at_cursor() calls rstudioapi::insertText", {
  inserted <- NULL
  local_mocked_bindings(
    isAvailable = function(...) TRUE,
    getSourceEditorContext = function(...) make_ctx(path = "/f.R"),
    insertText = function(text, id) {
      inserted <<- text
      invisible(NULL)
    },
    .package = "rstudioapi"
  )
  insert_at_cursor("x <- 1")
  expect_equal(inserted, "x <- 1")
})

test_that("replace_selection() errors when nothing selected", {
  local_mocked_bindings(
    isAvailable            = function(...) TRUE,
    getSourceEditorContext = function(...) make_ctx(text = ""),
    .package               = "rstudioapi"
  )
  expect_error(replace_selection("new code"), "No code is selected")
})
