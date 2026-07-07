test_that("raiddin_tools() returns a list of 5 definitions", {
  tools <- raiddin_tools()
  expect_type(tools, "list")
  expect_length(tools, 5L)
})

test_that("each tool has name, description, and input_schema", {
  for (tool in raiddin_tools()) {
    expect_true(!is.null(tool$name))
    expect_true(!is.null(tool$description))
    expect_equal(tool$input_schema$type, "object")
    expect_true(!is.null(tool$input_schema$properties))
    expect_true(!is.null(tool$input_schema$required))
  }
})

test_that("tool names match expected set", {
  names_found <- vapply(raiddin_tools(), `[[`, character(1L), "name")
  expect_setequal(
    names_found,
    c(
      "execute_r_code", "get_selected_code", "get_document_context",
      "insert_code_to_editor", "replace_selection"
    )
  )
})

test_that("execute_r_code requires 'code'", {
  tool <- Filter(function(t) t$name == "execute_r_code", raiddin_tools())[[1]]
  expect_true("code" %in% tool$input_schema$required)
})

test_that("replace_selection requires 'new_code'", {
  tool <- Filter(function(t) t$name == "replace_selection", raiddin_tools())[[1]]
  expect_true("new_code" %in% tool$input_schema$required)
})

test_that("insert_code_to_editor requires 'code'", {
  tool <- Filter(function(t) t$name == "insert_code_to_editor", raiddin_tools())[[1]]
  expect_true("code" %in% tool$input_schema$required)
})

test_that("execute_r_code session property has correct enum values", {
  tool <- Filter(function(t) t$name == "execute_r_code", raiddin_tools())[[1]]
  session_prop <- tool$input_schema$properties$session
  expect_true(all(c("main", "subprocess") %in% session_prop$enum))
})
