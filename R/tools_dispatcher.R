#' Format an execution result as Claude API content blocks
#'
#' Converts the list returned by [execute_main_session()] or
#' [execute_subprocess()] into content blocks for [tool_result_message()].
#' Stdout, warnings, messages, and errors are joined into one text block;
#' each plot becomes an image block.
#'
#' @param result A named list as returned by the execute functions.
#' @return A list of content blocks (text and/or image blocks).
#' @noRd
format_tool_result <- function(result) {
  parts <- character(0)
  if (length(result$stdout) > 0L) {
    parts <- c(parts, paste(result$stdout, collapse = "\n"))
  }
  if (length(result$warnings) > 0L) {
    parts <- c(parts, paste0("[warning] ", result$warnings))
  }
  if (length(result$messages) > 0L) {
    parts <- c(parts, paste0("[message] ", result$messages))
  }
  if (!is.null(result$error)) {
    parts <- c(parts, paste0("[error] ", result$error))
  }
  blocks <- list()
  if (length(parts) > 0L) {
    blocks <- c(blocks, list(text_block(paste(parts, collapse = "\n"))))
  }
  for (b64 in result$plots) {
    blocks <- c(blocks, list(image_block(b64)))
  }
  if (length(blocks) == 0L) {
    blocks <- list(text_block("(no output)"))
  }
  blocks
}

#' Dispatch a tool_use call to the appropriate R handler
#'
#' Routes a `tool_use` content block (as returned by [extract_tool_calls()])
#' to the corresponding RAiddin function. Execution tools are gated by
#' [check_code_approval()]; when a prompt is required and `on_approval_required`
#' is `NULL` or returns `FALSE`, an error result is returned instead of
#' executing the code.
#'
#' @param tool_call A single `tool_use` block with `name` and `input` fields.
#' @param envir Environment for code execution (default `.GlobalEnv`).
#' @param on_approval_required Optional `function(tool_call)` returning
#'   `logical(1)`. Called when execution requires interactive approval; return
#'   `TRUE` to allow, `FALSE` to deny.
#'
#' @return A named list with:
#'   \describe{
#'     \item{`content`}{A list of content blocks for [tool_result_message()].}
#'     \item{`is_error`}{`logical(1)` — `TRUE` when the tool signalled an error.}
#'   }
#' @noRd
dispatch_tool <- function(tool_call, envir = .GlobalEnv, on_approval_required = NULL) {
  tryCatch(
    .dispatch_inner(tool_call$name, tool_call$input, envir, on_approval_required),
    error = function(e) {
      list(
        content  = list(text_block(paste0("[error] ", conditionMessage(e)))),
        is_error = TRUE
      )
    }
  )
}

#' @noRd
.dispatch_inner <- function(name, input, envir, on_approval_required) {
  switch(name,
    execute_r_code = {
      code <- input$code
      session <- input$session %||% "main"
      approval <- check_code_approval(code)
      if (!approval$approved) {
        callback_approved <- !is.null(on_approval_required) &&
          isTRUE(on_approval_required(list(name = name, input = input)))
        if (!callback_approved) {
          return(list(
            content  = list(text_block("[error] Code execution denied by user.")),
            is_error = TRUE
          ))
        }
      }
      exec_result <- if (identical(session, "subprocess")) {
        execute_subprocess(code, envir = envir)
      } else {
        execute_main_session(code, envir = envir)
      }
      list(content = format_tool_result(exec_result), is_error = FALSE)
    },
    get_selected_code = {
      sel <- get_selection()
      if (!nzchar(sel$text)) {
        return(list(
          content  = list(text_block("[error] No text is currently selected.")),
          is_error = TRUE
        ))
      }
      list(content = list(text_block(sel$text)), is_error = FALSE)
    },
    get_document_context = {
      src <- get_document()
      position <- get_cursor_position()
      out <- paste0(
        "File: ", get_active_file(), "\n",
        "Cursor: row ", position$row, ", column ", position$column, "\n\n",
        src
      )
      list(content = list(text_block(out)), is_error = FALSE)
    },
    insert_code_to_editor = {
      code <- input$code
      position <- input$position %||% "cursor"
      if (identical(position, "end")) {
        insert_at_end(code)
      } else {
        insert_at_cursor(code)
      }
      list(content = list(text_block("Code inserted.")), is_error = FALSE)
    },
    replace_selection = {
      replace_selection(input$new_code)
      list(content = list(text_block("Selection replaced.")), is_error = FALSE)
    },
    list(
      content  = list(text_block(paste0("[error] Unknown tool: ", name))),
      is_error = TRUE
    )
  )
}
