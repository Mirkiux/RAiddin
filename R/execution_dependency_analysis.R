#' @noRd
.plot_function_names <- c(
  "plot", "ggplot", "hist", "barplot", "boxplot", "pie", "dotchart",
  "pairs", "image", "contour", "persp", "curve", "matplot", "stripchart",
  "beeswarm", "qplot", "autoplot", "ggplotly"
)

#' @noRd
.plot_function_prefixes <- c("geom_", "stat_", "scale_", "theme_", "coord_", "facet_")

#' @noRd
.code_to_function <- function(code) {
  parsed <- tryCatch(parse(text = code), error = function(e) NULL)
  if (is.null(parsed)) {
    return(NULL)
  }
  body_call <- as.call(c(list(quote(`{`)), as.list(parsed)))
  as.function(list(body_call))
}

#' @noRd
analyze_code_dependencies <- function(code, envir = .GlobalEnv) {
  fn <- .code_to_function(code)
  if (is.null(fn)) {
    return(character(0))
  }
  globals <- codetools::findGlobals(fn, merge = FALSE)$variables
  intersect(globals, ls(envir, all.names = TRUE))
}

#' @noRd
uses_plot_functions <- function(code) {
  fn <- .code_to_function(code)
  if (is.null(fn)) {
    return(FALSE)
  }
  globals <- codetools::findGlobals(fn, merge = FALSE)$functions
  any(globals %in% .plot_function_names) ||
    any(vapply(
      .plot_function_prefixes,
      function(pfx) any(startsWith(globals, pfx)),
      logical(1L)
    ))
}
