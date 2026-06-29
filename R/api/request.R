#' Build a user message object
#'
#' @param content A string or a list of content blocks.
#' @return A named list representing a user message.
#' @export
user_message <- function(content) {
  list(role = "user", content = content)
}

#' Build an assistant message object
#'
#' @param content A string or a list of content blocks.
#' @return A named list representing an assistant message.
#' @export
assistant_message <- function(content) {
  list(role = "assistant", content = content)
}

#' Build a text content block
#'
#' @param text A string.
#' @return A named list representing a text content block.
#' @export
text_block <- function(text) {
  list(type = "text", text = text)
}

#' Build a base64 image content block
#'
#' @param data Base64-encoded image string.
#' @param media_type MIME type of the image (default `"image/png"`).
#' @return A named list representing an image content block.
#' @export
image_block <- function(data, media_type = "image/png") {
  list(
    type = "image",
    source = list(type = "base64", media_type = media_type, data = data)
  )
}

#' Build a tool result message
#'
#' Wraps a tool output so it can be appended to the message history and
#' submitted back to Claude after a `tool_use` response.
#'
#' @param tool_use_id The `id` from the corresponding `tool_use` content block.
#' @param content The tool output: a string, or a list of content blocks.
#'   Pass a list containing an [image_block()] to include plot output.
#' @param is_error Logical. Set to `TRUE` when reporting a tool execution error.
#' @return A user message list wrapping a `tool_result` content block.
#' @export
tool_result_message <- function(tool_use_id, content, is_error = FALSE) {
  block <- list(
    type = "tool_result",
    tool_use_id = tool_use_id,
    content = content
  )
  if (isTRUE(is_error)) block$is_error <- TRUE
  user_message(list(block))
}
