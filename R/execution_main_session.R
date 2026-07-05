#' Execute R code in the main session
#'
#' Runs `code` via [evaluate::evaluate()] in `envir`, capturing text output,
#' warnings, messages, errors, and plots. A new graphics device is opened when
#' the code calls a known plot function.
#'
#' @param code A character(1) string of R code to evaluate.
#' @param envir The environment to evaluate in (default `.GlobalEnv`).
#'
#' @return A named list with elements `stdout`, `stderr`, `plots`, `error`,
#'   `warnings`, and `messages`.
#' @export
execute_main_session <- function(code, envir = .GlobalEnv) {
  capture_plots <- uses_plot_functions(code)
  results <- evaluate::evaluate(
    code,
    envir        = envir,
    new_device   = capture_plots,
    keep_warning = TRUE,
    keep_message = TRUE
  )

  stdout_lines <- character(0)
  warnings_out <- character(0)
  messages_out <- character(0)
  plots <- list()
  error <- NULL

  for (item in results) {
    if (is.character(item)) {
      stdout_lines <- c(stdout_lines, item)
    } else if (inherits(item, "error")) {
      error <- conditionMessage(item)
    } else if (inherits(item, "warning")) {
      warnings_out <- c(warnings_out, conditionMessage(item))
    } else if (inherits(item, "message")) {
      messages_out <- c(messages_out, conditionMessage(item))
    } else if (inherits(item, "recordedplot")) {
      plots <- c(plots, list(recordedplot_to_base64(item)))
    }
  }

  build_execution_output(
    stdout   = stdout_lines,
    stderr   = character(0),
    plots    = plots,
    error    = error,
    warnings = warnings_out,
    messages = messages_out
  )
}
