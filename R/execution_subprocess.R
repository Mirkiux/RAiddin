# Session-level subprocess state. Not exported.
.subprocess_state <- new.env(parent = emptyenv())
.subprocess_state$session <- NULL

# Runner function sent to the callr subprocess. Environment is stripped to
# baseenv() so callr can serialize it without capturing the RAiddin namespace.
.subprocess_runner <- local({
  f <- function(code, capture_plots) {
    warnings_out <- character(0)
    messages_out <- character(0)
    stdout_out <- character(0)
    error_out <- NULL

    parsed <- tryCatch(parse(text = code), error = function(e) e)
    if (inherits(parsed, "error")) {
      return(list(
        stdout       = character(0),
        stderr       = character(0),
        warnings     = character(0),
        messages     = character(0),
        error        = conditionMessage(parsed),
        png_raw_list = list()
      ))
    }

    png_base <- NULL
    if (capture_plots) {
      png_base <- tempfile()
      grDevices::png(paste0(png_base, "%03d.png"))
    }

    for (expr in as.list(parsed)) {
      if (!is.null(error_out)) break
      withCallingHandlers(
        tryCatch(
          {
            out <- utils::capture.output(eval(expr, envir = .GlobalEnv))
            stdout_out <- c(stdout_out, out)
          },
          error = function(e) {
            error_out <<- conditionMessage(e)
          }
        ),
        warning = function(w) {
          warnings_out <<- c(warnings_out, conditionMessage(w))
          invokeRestart("muffleWarning")
        },
        message = function(m) {
          messages_out <<- c(messages_out, conditionMessage(m))
          invokeRestart("muffleMessage")
        }
      )
    }

    png_raw_list <- list()
    if (capture_plots && !is.null(png_base)) {
      grDevices::dev.off()
      plot_files <- sort(Sys.glob(paste0(png_base, "*.png")))
      for (pf in plot_files) {
        if (file.size(pf) > 0L) {
          png_raw_list <- c(png_raw_list, list(readBin(pf, "raw", file.size(pf))))
        }
      }
      unlink(plot_files)
    }

    list(
      stdout       = stdout_out,
      stderr       = character(0),
      warnings     = warnings_out,
      messages     = messages_out,
      error        = error_out,
      png_raw_list = png_raw_list
    )
  }
  environment(f) <- baseenv()
  f
})

#' Reset the persistent callr subprocess
#'
#' Kills the current subprocess (if alive) and clears the stored session.
#' The next call to [execute_subprocess()] starts a fresh R session.
#'
#' @return Invisible `NULL`.
#' @export
reset_subprocess <- function() {
  if (!is.null(.subprocess_state$session)) {
    tryCatch(.subprocess_state$session$close(), error = function(e) NULL)
    .subprocess_state$session <- NULL
  }
  invisible(NULL)
}

#' Execute R code in an isolated callr subprocess
#'
#' Runs `code` in a persistent background R session, replicating the objects
#' from `envir` that the code references. Objects larger than `threshold_mb`
#' are not pushed; their names are returned in `$large` so callers can decide
#' what to do (e.g., prompt the user).
#'
#' @param code A character(1) string of R code to evaluate.
#' @param envir The environment to replicate objects from (default `.GlobalEnv`).
#' @param threshold_mb Numeric; objects above this size (in MB) are not
#'   auto-pushed (default `50`).
#' @param always_push Character vector of object names to always push,
#'   regardless of `threshold_mb`.
#' @param timeout_s Numeric; seconds to allow the subprocess to run before
#'   forcibly terminating it (default `Inf`, no limit). Use a finite value to
#'   prevent runaway code from hanging the session indefinitely.
#'
#' @return A named list with elements `stdout`, `stderr`, `plots`, `error`,
#'   `warnings`, `messages`, and `large` (names of skipped large objects).
#' @export
execute_subprocess <- function(code, envir = .GlobalEnv,
                               threshold_mb = 50,
                               always_push = character(0),
                               timeout_s = Inf) {
  if (!is.character(code) || length(code) != 1L) {
    stop("`code` must be a character(1).", call. = FALSE)
  }
  if (!is.environment(envir)) {
    stop("`envir` must be an environment.", call. = FALSE)
  }
  if (!is.numeric(threshold_mb) || length(threshold_mb) != 1L || threshold_mb <= 0) {
    stop("`threshold_mb` must be a positive numeric(1).", call. = FALSE)
  }
  if (!is.character(always_push)) {
    stop("`always_push` must be a character vector.", call. = FALSE)
  }
  if (!is.numeric(timeout_s) || length(timeout_s) != 1L || is.na(timeout_s)) {
    stop("`timeout_s` must be a positive numeric(1).", call. = FALSE)
  }
  if (timeout_s <= 0) {
    stop("`timeout_s` must be a positive numeric(1).", call. = FALSE)
  }
  session <- .subprocess_state$session
  if (is.null(session) || !session$is_alive()) {
    session <- callr::r_session$new()
    .subprocess_state$session <- session
  }

  capture_plots <- uses_plot_functions(code)
  large <- replicate_env(session, code, envir, threshold_mb, always_push)

  raw <- tryCatch(
    {
      session$call(
        .subprocess_runner,
        args = list(code = code, capture_plots = capture_plots)
      )
      timeout_ms <- if (is.finite(timeout_s)) as.integer(timeout_s * 1000) else -1L
      poll_status <- processx::poll(list(session$get_poll_connection()), timeout_ms)[[1]]
      if (poll_status == "timeout") {
        tryCatch(session$kill(), error = function(e2) NULL)
        .subprocess_state$session <- NULL
        stop("Code execution timed out after ", timeout_s, "s.", call. = FALSE)
      }
      msg <- NULL
      repeat {
        msg <- session$read()
        if (!is.null(msg) && (msg$code == 200L || (msg$code >= 500L && msg$code < 600L))) break
      }
      if (!is.null(msg$error)) stop(msg$error$message, call. = FALSE)
      msg$result
    },
    error = function(e) {
      tryCatch(session$close(), error = function(e2) NULL)
      .subprocess_state$session <- NULL
      list(
        stdout       = character(0),
        stderr       = character(0),
        warnings     = character(0),
        messages     = character(0),
        error        = paste0("Subprocess error: ", conditionMessage(e)),
        png_raw_list = list()
      )
    }
  )

  plots <- lapply(raw$png_raw_list, raw_png_to_base64)

  result <- build_execution_output(
    stdout   = raw$stdout,
    stderr   = raw$stderr,
    plots    = plots,
    error    = raw$error,
    warnings = raw$warnings,
    messages = raw$messages
  )
  result$large <- large
  result
}
