#' @noRd
.tool_execute_r_code <- list(
  name = "execute_r_code",
  description = paste(
    "Execute R code in the user's active R session.",
    "Returns captured stdout, warnings, messages, errors, and any plots.",
    "Prefer 'subprocess' for untrusted or long-running code."
  ),
  input_schema = list(
    type = "object",
    properties = list(
      code = list(
        type = "string",
        description = "R code to execute."
      ),
      session = list(
        type = "string",
        enum = list("main", "subprocess"),
        description = "Session to use: 'main' (default) or 'subprocess' (isolated callr process)."
      )
    ),
    required = list("code")
  )
)

#' @noRd
.tool_get_selected_code <- list(
  name = "get_selected_code",
  description = "Return the text currently selected in the RStudio source editor.",
  input_schema = list(
    type = "object",
    properties = list(),
    required = list()
  )
)

#' @noRd
.tool_get_document_context <- list(
  name = "get_document_context",
  description = paste(
    "Return the full source of the active document and the current cursor position.",
    "Use this to understand surrounding code before suggesting changes."
  ),
  input_schema = list(
    type = "object",
    properties = list(),
    required = list()
  )
)

#' @noRd
.tool_insert_code_to_editor <- list(
  name = "insert_code_to_editor",
  description = "Insert code into the active RStudio editor at the cursor or at the end of the document.",
  input_schema = list(
    type = "object",
    properties = list(
      code = list(
        type = "string",
        description = "Code to insert."
      ),
      position = list(
        type = "string",
        enum = list("cursor", "end"),
        description = "Where to insert: 'cursor' (default) or 'end' of document."
      )
    ),
    required = list("code")
  )
)

#' @noRd
.tool_replace_selection <- list(
  name = "replace_selection",
  description = "Replace the current editor selection with new code.",
  input_schema = list(
    type = "object",
    properties = list(
      new_code = list(
        type = "string",
        description = "The replacement code."
      )
    ),
    required = list("new_code")
  )
)

#' Return the list of all RAiddin tool definitions
#'
#' Provides the complete set of tool schemas to pass to [chat_completion()] or
#' [run_agentic_loop()]. Tools cover code execution, editor inspection, and
#' editor modification.
#'
#' @return A list of tool definition objects suitable for the `tools` argument
#'   of [chat_completion()].
#' @export
raiddin_tools <- function() {
  list(
    .tool_execute_r_code,
    .tool_get_selected_code,
    .tool_get_document_context,
    .tool_insert_code_to_editor,
    .tool_replace_selection
  )
}
