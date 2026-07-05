#' @noRd
build_execution_output <- function(stdout = character(0),
                                   stderr = character(0),
                                   plots = list(),
                                   error = NULL,
                                   warnings = character(0),
                                   messages = character(0)) {
  list(
    stdout   = stdout,
    stderr   = stderr,
    plots    = plots,
    error    = error,
    warnings = warnings,
    messages = messages
  )
}
