claude_base_url <- "https://api.anthropic.com/v1"
claude_api_version <- "2023-06-01"
claude_default_model <- "claude-sonnet-4-6"
claude_default_max_tokens <- 8192L

#' Build an authenticated base httr2 request
#'
#' @return An `httr2_request` object pre-configured with auth headers, retry
#'   logic for rate-limit (429) and overload (529) responses, and error body
#'   parsing.
#' @noRd
claude_base_request <- function() {
  httr2::request(claude_base_url) |>
    httr2::req_headers(
      "x-api-key" = get_api_key(),
      "anthropic-version" = claude_api_version,
      "content-type" = "application/json"
    ) |>
    httr2::req_retry(
      max_tries = 3L,
      is_transient = function(resp) httr2::resp_status(resp) %in% c(429L, 529L)
    ) |>
    httr2::req_error(
      is_error = function(resp) httr2::resp_status(resp) >= 400L,
      body = claude_error_body
    )
}

#' Extract an error message from a failed Claude API response
#'
#' @param resp An `httr2_response` object.
#' @return A single string describing the error.
#' @noRd
claude_error_body <- function(resp) {
  parsed <- tryCatch(httr2::resp_body_json(resp), error = function(e) NULL)
  parsed$error$message %||% "Unknown API error"
}

#' Send a messages request to the Claude API
#'
#' Performs a synchronous request to the Anthropic Messages API and returns the
#' parsed response. Use [has_tool_calls()] and [extract_tool_calls()] to
#' inspect the response, and [tool_result_message()] to build the next turn.
#'
#' @param messages A list of message objects built with [user_message()] and
#'   [assistant_message()].
#' @param model Claude model ID. Defaults to the `raiddin.model` option or
#'   `"claude-sonnet-4-6"`.
#' @param max_tokens Maximum number of tokens to generate. Defaults to the
#'   `raiddin.max_tokens` option or `8192`.
#' @param tools Optional list of tool definition objects.
#' @param system Optional system prompt string.
#'
#' @return A named list representing the API response, with fields `id`,
#'   `type`, `role`, `content`, `model`, `stop_reason`, and `usage`.
#' @export
chat_completion <- function(
  messages,
  model = getOption("raiddin.model", claude_default_model),
  max_tokens = getOption("raiddin.max_tokens", claude_default_max_tokens),
  tools = NULL,
  system = NULL
) {
  body <- list(model = model, max_tokens = max_tokens, messages = messages)
  if (!is.null(tools)) body$tools <- tools
  if (!is.null(system)) body$system <- system

  resp <- claude_base_request() |>
    httr2::req_url_path_append("messages") |>
    httr2::req_body_json(body) |>
    httr2::req_perform()

  httr2::resp_body_json(resp)
}

#' Send a streaming messages request to the Claude API
#'
#' Like [chat_completion()] but streams the response token by token, calling
#' `on_text` incrementally. Returns the fully assembled response once complete.
#' Only text content is streamed; if `tools` is supplied and the model
#' responds with `tool_use`, call [chat_completion()] instead so tool_use
#' blocks are preserved for [extract_tool_calls()] and
#' [tool_result_message()].
#'
#' @param messages A list of message objects.
#' @param on_text Optional callback `function(delta)` invoked with each text
#'   delta string as it arrives.
#' @param model Claude model ID.
#' @param max_tokens Maximum tokens to generate.
#' @param tools Optional list of tool definition objects.
#' @param system Optional system prompt string.
#'
#' @return A named list with `role`, `content`, and `stop_reason`, mirroring
#'   the structure of a [chat_completion()] response.
#' @export
chat_completion_stream <- function(
  messages,
  on_text = NULL,
  model = getOption("raiddin.model", claude_default_model),
  max_tokens = getOption("raiddin.max_tokens", claude_default_max_tokens),
  tools = NULL,
  system = NULL
) {
  body <- list(
    model = model,
    max_tokens = max_tokens,
    messages = messages,
    stream = TRUE
  )
  if (!is.null(tools)) body$tools <- tools
  if (!is.null(system)) body$system <- system

  req <- claude_base_request() |>
    httr2::req_url_path_append("messages") |>
    httr2::req_body_json(body)

  conn <- httr2::req_perform_connection(req)
  on.exit(close(conn), add = TRUE)

  text_parts <- character(0L)
  current_stop_reason <- NULL

  while (!httr2::resp_stream_is_complete(conn)) {
    lines <- httr2::resp_stream_lines(conn, max_lines = 50L)
    for (line in lines) {
      event <- parse_sse_line(line)
      if (is.null(event)) next
      is_text_delta <- identical(event$type, "content_block_delta") &&
        identical(event$delta$type, "text_delta") &&
        !is.null(event$delta$text)
      if (is_text_delta) {
        text_parts <- c(text_parts, event$delta$text)
        if (!is.null(on_text)) on_text(event$delta$text)
      } else if (identical(event$type, "message_delta")) {
        current_stop_reason <- event$delta$stop_reason
      }
    }
  }

  list(
    type = "message",
    role = "assistant",
    content = list(list(type = "text", text = paste(text_parts, collapse = ""))),
    stop_reason = current_stop_reason
  )
}
