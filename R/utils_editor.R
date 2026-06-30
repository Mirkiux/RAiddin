#' Get the active source editor context, failing informatively if unavailable
#'
#' @return An `rstudioapi` document context list.
#' @noRd
get_editor_context <- function() {
  if (!rstudioapi::isAvailable()) {
    stop("RAiddin requires an active RStudio session.", call. = FALSE)
  }
  ctx <- rstudioapi::getSourceEditorContext()
  if (is.null(ctx)) {
    stop("No active editor found. Open a file in the source editor first.", call. = FALSE)
  }
  ctx
}

#' Stop if the editor context has no non-empty selection
#'
#' @param ctx An `rstudioapi` document context list.
#' @return Invisibly `NULL`.
#' @noRd
require_selection <- function(ctx) {
  if (!nzchar(ctx$selection[[1]]$text)) {
    stop("No code is selected. Select some code in the editor first.", call. = FALSE)
  }
  invisible(NULL)
}

#' Warn if the document's underlying file is not writable
#'
#' @param ctx An `rstudioapi` document context list.
#' @return Invisibly `NULL`.
#' @noRd
warn_if_readonly <- function(ctx) {
  if (nzchar(ctx$path) && file.exists(ctx$path) && file.access(ctx$path, mode = 2L) != 0L) {
    warning("The active document's file appears to be read-only on disk; edits may not save.", call. = FALSE)
  }
  invisible(NULL)
}

#' Get the current editor selection
#'
#' @return A list with `text` (the selected string) and `range` (the
#'   `rstudioapi` document range).
#' @export
get_selection <- function() {
  ctx <- get_editor_context()
  sel <- ctx$selection[[1]]
  list(text = sel$text, range = sel$range)
}

#' Get the full contents of the active document
#'
#' @return A single string with the document source, lines joined by `"\n"`.
#' @export
get_document <- function() {
  ctx <- get_editor_context()
  paste(ctx$contents, collapse = "\n")
}

#' Get the current cursor position in the active document
#'
#' @return A list with `row` and `column` (1-indexed).
#' @export
get_cursor_position <- function() {
  ctx <- get_editor_context()
  start <- ctx$selection[[1]]$range$start
  list(row = start[["row"]], column = start[["column"]])
}

#' Insert text at the current cursor position
#'
#' @param text The text to insert.
#' @return Invisibly `NULL`.
#' @export
insert_at_cursor <- function(text) {
  ctx <- get_editor_context()
  warn_if_readonly(ctx)
  rstudioapi::insertText(text = text, id = ctx$id)
  invisible(NULL)
}

#' Replace the current selection with new text
#'
#' @param text The replacement text.
#' @return Invisibly `NULL`.
#' @export
replace_selection <- function(text) {
  ctx <- get_editor_context()
  require_selection(ctx)
  warn_if_readonly(ctx)
  rstudioapi::modifyRange(ctx$selection[[1]]$range, text, id = ctx$id)
  invisible(NULL)
}

#' Append text to the end of the active document
#'
#' @param text The text to append.
#' @return Invisibly `NULL`.
#' @export
insert_at_end <- function(text) {
  ctx <- get_editor_context()
  warn_if_readonly(ctx)
  end_position <- rstudioapi::document_position(length(ctx$contents) + 1L, 1L)
  prefix <- if (length(ctx$contents) == 0L) "" else "\n"
  rstudioapi::insertText(end_position, paste0(prefix, text), id = ctx$id)
  invisible(NULL)
}

#' Get the file path of the active document
#'
#' @return A single string with the absolute path to the active document.
#' @export
get_active_file <- function() {
  ctx <- get_editor_context()
  if (!nzchar(ctx$path)) {
    stop("The active document has not been saved to disk yet.", call. = FALSE)
  }
  ctx$path
}
