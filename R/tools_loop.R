#' Run the RAiddin agentic loop
#'
#' Calls the Claude API with `messages` and `tools`, then handles any
#' `tool_use` turns automatically: each tool call is dispatched via
#' [dispatch_tool()], the results are appended to the conversation, and
#' Claude is called again. The loop stops when Claude returns `end_turn`,
#' when `stop_reason` is not `"tool_use"`, or when `max_turns` is reached.
#'
#' Tool calls are never streamed; [chat_completion()] is used throughout so
#' that `tool_use` content blocks are preserved for dispatch.
#'
#' @param messages A list of message objects built with [user_message()] and
#'   [assistant_message()].
#' @param system Optional system prompt string.
#' @param tools List of tool definitions. Defaults to [raiddin_tools()].
#' @param model Claude model ID. Defaults to the `raiddin.model` option.
#' @param max_tokens Maximum tokens per response. Defaults to the
#'   `raiddin.max_tokens` option.
#' @param envir Environment for code execution tools (default `.GlobalEnv`).
#' @param max_turns Maximum number of tool-use turns before stopping
#'   (default `10L`). Prevents infinite loops if the model keeps calling tools.
#' @param on_approval_required Optional `function(tool_call)` returning
#'   `logical(1)`. Invoked when [check_code_approval()] requires a prompt;
#'   return `TRUE` to allow execution, `FALSE` to deny. When `NULL` (default),
#'   unapproved code is denied automatically.
#'
#' @return A named list with:
#'   \describe{
#'     \item{`response`}{The final Claude API response list.}
#'     \item{`messages`}{Full conversation history including all tool turns.}
#'     \item{`turns`}{Number of tool-use turns completed.}
#'     \item{`hit_limit`}{`logical(1)` — `TRUE` if the loop stopped because
#'       `max_turns` was reached.}
#'   }
#' @export
run_agentic_loop <- function(
  messages,
  system = NULL,
  tools = raiddin_tools(),
  model = getOption("raiddin.model", claude_default_model),
  max_tokens = getOption("raiddin.max_tokens", claude_default_max_tokens),
  envir = .GlobalEnv,
  max_turns = 10L,
  on_approval_required = NULL
) {
  if (!is.list(messages) || length(messages) == 0L) {
    stop("`messages` must be a non-empty list.", call. = FALSE)
  }
  if (!is.numeric(max_turns) || length(max_turns) != 1L || max_turns < 1L) {
    stop("`max_turns` must be a positive numeric(1).", call. = FALSE)
  }
  if (!is.environment(envir)) {
    stop("`envir` must be an environment.", call. = FALSE)
  }

  response <- chat_completion(messages, model, max_tokens, tools, system)
  turns <- 0L

  while (has_tool_calls(response) && turns < as.integer(max_turns)) {
    turns <- turns + 1L
    tool_calls <- extract_tool_calls(response)

    result_blocks <- lapply(tool_calls, function(tc) {
      dr <- dispatch_tool(tc, envir, on_approval_required)
      block <- list(type = "tool_result", tool_use_id = tc$id, content = dr$content)
      if (isTRUE(dr$is_error)) block$is_error <- TRUE
      block
    })

    messages <- c(
      messages,
      list(assistant_message(response$content)),
      list(user_message(result_blocks))
    )
    response <- chat_completion(messages, model, max_tokens, tools, system)
  }

  list(
    response  = response,
    messages  = messages,
    turns     = turns,
    hit_limit = turns >= as.integer(max_turns) && has_tool_calls(response)
  )
}
