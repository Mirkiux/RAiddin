#' Get the Anthropic API key
#'
#' Reads from the `ANTHROPIC_API_KEY` environment variable.
#'
#' @return A non-empty string containing the API key.
#' @noRd
get_api_key <- function() {
  key <- Sys.getenv("ANTHROPIC_API_KEY")
  if (nzchar(key)) {
    return(key)
  }
  stop(
    "ANTHROPIC_API_KEY environment variable is not set.\n",
    "Add it to your .Renviron: ANTHROPIC_API_KEY=your-key\n",
    "Then restart R or call readRenviron('~/.Renviron').",
    call. = FALSE
  )
}
