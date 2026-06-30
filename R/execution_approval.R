# Session-level approval state. Not exported.
.approval_state <- new.env(parent = emptyenv())
.approval_state$auto_approve <- FALSE
.approval_state$session_patterns <- character(0)

.raiddin_patterns_path <- function() {
  file.path(path.expand("~"), ".raiddin", "approved_patterns.txt")
}

.raiddin_patterns_dir <- function() {
  file.path(path.expand("~"), ".raiddin")
}

#' Check whether auto-approve is active for this session
#'
#' @return `logical(1)` - `TRUE` if all Claude-generated code executes without
#'   prompting for the duration of the current R session.
#' @export
is_auto_approve <- function() {
  .approval_state$auto_approve
}

#' Enable or disable session-level auto-approve
#'
#' When `TRUE`, every code block proposed by the agentic loop is executed
#' immediately without a confirmation prompt. This setting is session-scoped
#' and resets when R restarts.
#'
#' @param value `logical(1)` - the desired auto-approve state.
#' @return Invisibly `NULL`.
#' @export
set_auto_approve <- function(value) {
  if (!is.logical(value) || length(value) != 1L || is.na(value)) {
    stop("`value` must be a non-NA logical(1).", call. = FALSE)
  }
  .approval_state$auto_approve <- value
  invisible(NULL)
}

#' Return all currently active approved patterns
#'
#' Returns the union of in-session patterns added via `add_approved_pattern()`
#' and patterns persisted in `~/.raiddin/approved_patterns.txt`. Patterns from
#' the file are merged with session patterns and duplicates removed before returning.
#'
#' @return A `character` vector of approved pattern strings (may be length 0).
#' @export
get_approved_patterns <- function() {
  session_pats <- .approval_state$session_patterns
  path <- .raiddin_patterns_path()
  persistent_pats <- tryCatch(
    {
      lines <- readLines(path, warn = FALSE)
      lines <- trimws(lines)
      lines[nzchar(lines)]
    },
    error = function(e) character(0)
  )
  union(session_pats, persistent_pats)
}

#' Add an approved pattern
#'
#' Adds `pattern` to the in-session approved list and appends it to
#' `~/.raiddin/approved_patterns.txt`, creating the directory and file if they
#' do not yet exist. Duplicate patterns are silently ignored.
#'
#' @param pattern A non-empty `character(1)` string. Fixed-string matching is
#'   used: special regex characters have no effect.
#' @return Invisibly `NULL`.
#' @export
add_approved_pattern <- function(pattern) {
  if (!is.character(pattern) || length(pattern) != 1L || !nzchar(trimws(pattern))) {
    stop("`pattern` must be a non-empty character(1).", call. = FALSE)
  }
  existing <- get_approved_patterns()
  if (pattern %in% existing) {
    return(invisible(NULL))
  }
  .approval_state$session_patterns <- c(.approval_state$session_patterns, pattern)
  dir_path <- .raiddin_patterns_dir()
  if (!dir.exists(dir_path)) {
    dir.create(dir_path, recursive = TRUE)
  }
  cat(pattern, "\n", file = .raiddin_patterns_path(), append = TRUE, sep = "")
  invisible(NULL)
}

#' Remove an approved pattern
#'
#' Removes `pattern` from the in-session list and rewrites
#' `~/.raiddin/approved_patterns.txt` without that pattern. If the pattern
#' does not exist in either location the call is a no-op.
#'
#' @param pattern A `character(1)` string to remove.
#' @return Invisibly `NULL`.
#' @export
remove_approved_pattern <- function(pattern) {
  if (!is.character(pattern) || length(pattern) != 1L) {
    stop("`pattern` must be a character(1).", call. = FALSE)
  }
  .approval_state$session_patterns <- setdiff(.approval_state$session_patterns, pattern)
  path <- .raiddin_patterns_path()
  if (file.exists(path)) {
    lines <- tryCatch(readLines(path, warn = FALSE), error = function(e) character(0))
    lines <- trimws(lines)
    lines <- lines[nzchar(lines) & lines != pattern]
    writeLines(lines, path)
  }
  invisible(NULL)
}

#' Test whether a code string matches any approved pattern
#'
#' Uses fixed-string matching (`grepl(..., fixed = TRUE)`) against every
#' pattern returned by `get_approved_patterns()`.
#'
#' @param code A `character(1)` code string to test.
#' @return `logical(1)` - `TRUE` if at least one approved pattern is found
#'   within `code`.
#' @export
matches_approved_pattern <- function(code) {
  if (!is.character(code) || length(code) != 1L) {
    stop("`code` must be a character(1).", call. = FALSE)
  }
  patterns <- get_approved_patterns()
  if (length(patterns) == 0L) {
    return(FALSE)
  }
  matches <- vapply(patterns, function(p) grepl(p, code, fixed = TRUE), logical(1))
  any(matches)
}

#' Decide whether a code block requires user confirmation
#'
#' This is the primary entry point called by the agentic loop before executing
#' any Claude-generated code. It checks, in order:
#'
#' 1. Session-level auto-approve (`is_auto_approve()`).
#' 2. Pattern-based approval (`matches_approved_pattern()`).
#' 3. Falls back to requiring an interactive prompt.
#'
#' @param code A `character(1)` string containing the code block to evaluate.
#' @return A named list with two elements:
#'   \describe{
#'     \item{`approved`}{`logical(1)` - `TRUE` if execution should proceed
#'       immediately.}
#'     \item{`reason`}{`character(1)` - one of `"auto_approve"`,
#'       `"pattern_match"`, or `"requires_prompt"`.}
#'   }
#' @export
check_code_approval <- function(code) {
  if (!is.character(code) || length(code) != 1L) {
    stop("`code` must be a character(1).", call. = FALSE)
  }
  if (is_auto_approve()) {
    return(list(approved = TRUE, reason = "auto_approve"))
  }
  if (matches_approved_pattern(code)) {
    return(list(approved = TRUE, reason = "pattern_match"))
  }
  list(approved = FALSE, reason = "requires_prompt")
}

#' Reset session-level approval state
#'
#' Clears the in-session auto-approve flag and the in-session pattern list.
#' Does not modify `~/.raiddin/approved_patterns.txt`. Call this when starting
#' a new conversation to ensure a clean slate.
#'
#' @return Invisibly `NULL`.
#' @export
reset_session_approvals <- function() {
  .approval_state$auto_approve <- FALSE
  .approval_state$session_patterns <- character(0)
  invisible(NULL)
}

#' Interactively manage approved patterns from the R console
#'
#' Prints the current list of approved patterns (both session and persistent)
#' with numbered indices and offers a `readline()`-based interface for removing
#' individual entries. This is the non-UI fallback; a full Shiny modal is
#' provided by the addin UI implemented in P13.
#'
#' @return Invisibly `NULL`.
#' @export
raiddin_manage_approvals <- function() {
  patterns <- get_approved_patterns()
  if (length(patterns) == 0L) {
    message("No approved patterns are currently active.")
    return(invisible(NULL))
  }
  message("Current approved patterns:")
  for (i in seq_along(patterns)) {
    message(sprintf("  [%d] %s", i, patterns[[i]]))
  }
  raw <- readline("Enter index to remove (or press Enter to cancel): ")
  raw <- trimws(raw)
  if (!nzchar(raw)) {
    message("No changes made.")
    return(invisible(NULL))
  }
  idx <- suppressWarnings(as.integer(raw))
  if (is.na(idx) || idx < 1L || idx > length(patterns)) {
    message("Invalid index. No changes made.")
    return(invisible(NULL))
  }
  remove_approved_pattern(patterns[[idx]])
  message(sprintf("Removed pattern: %s", patterns[[idx]]))
  invisible(NULL)
}
