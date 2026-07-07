# Package-level pusher with baseenv() closure — same rationale as .subprocess_runner.
.push_runner <- local({
  f <- function(objects) {
    for (nm in names(objects)) assign(nm, objects[[nm]], envir = .GlobalEnv)
  }
  environment(f) <- baseenv()
  f
})

#' @noRd
classify_objects <- function(names, envir = .GlobalEnv, threshold_mb = 50) {
  if (length(names) == 0L) {
    return(list(auto_push = character(0), large = character(0)))
  }
  sizes_mb <- vapply(names, function(nm) {
    as.numeric(lobstr::obj_size(get(nm, envir = envir, inherits = FALSE))) / 1024^2
  }, numeric(1L))
  list(
    auto_push = names[sizes_mb <= threshold_mb],
    large     = names[sizes_mb > threshold_mb]
  )
}

#' @noRd
push_objects_to_session <- function(session, names, envir = .GlobalEnv) {
  if (length(names) == 0L) {
    return(invisible(NULL))
  }
  objects <- stats::setNames(
    lapply(names, function(nm) get(nm, envir = envir, inherits = FALSE)),
    names
  )
  session$run(.push_runner, args = list(objects = objects))
  invisible(NULL)
}

#' @noRd
replicate_env <- function(session, code, envir = .GlobalEnv,
                          threshold_mb = 50, always_push = character(0)) {
  deps <- analyze_code_dependencies(code, envir)
  forced <- intersect(always_push, ls(envir, all.names = TRUE))
  needed <- union(deps, forced)
  classified <- classify_objects(needed, envir, threshold_mb)
  push_objects_to_session(session, classified$auto_push, envir)
  classified$large
}
