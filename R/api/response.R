#' Get the stop reason from a Claude API response
#'
#' @param response A parsed API response list as returned by [chat_completion()].
#' @return One of `"end_turn"`, `"tool_use"`, `"max_tokens"`, or
#'   `"stop_sequence"`.
#' @export
stop_reason <- function(response) {
  response$stop_reason
}

#' Check whether a response contains tool calls
#'
#' @param response A parsed API response list.
#' @return `TRUE` if `stop_reason` is `"tool_use"`.
#' @export
has_tool_calls <- function(response) {
  identical(stop_reason(response), "tool_use")
}

#' Extract all tool_use blocks from a Claude API response
#'
#' @param response A parsed API response list.
#' @return A list of `tool_use` content blocks, each with `id`, `name`,
#'   and `input` fields.
#' @export
extract_tool_calls <- function(response) {
  Filter(function(b) identical(b$type, "tool_use"), response$content)
}

#' Extract concatenated text from a Claude API response
#'
#' @param response A parsed API response list.
#' @return A single string with all `text` content blocks concatenated.
#' @export
extract_text <- function(response) {
  blocks <- Filter(function(b) identical(b$type, "text"), response$content)
  paste(vapply(blocks, `[[`, character(1L), "text"), collapse = "")
}

#' Parse a server-sent event data line
#'
#' @param line A single line string from the SSE stream.
#' @return A parsed list, or `NULL` if the line is not a data event.
#' @noRd
parse_sse_line <- function(line) {
  if (!startsWith(line, "data: ")) {
    return(NULL)
  }
  data <- substring(line, 7L)
  if (identical(data, "[DONE]")) {
    return(NULL)
  }
  tryCatch(
    jsonlite::fromJSON(data, simplifyVector = FALSE),
    error = function(e) NULL
  )
}
