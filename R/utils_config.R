#' Path to the RAiddin config file
#'
#' @return A character string with the expanded path to `~/.raiddin/config.yaml`.
#' @noRd
raiddin_config_path <- function() {
  path.expand("~/.raiddin/config.yaml")
}

#' Default RAiddin configuration values
#'
#' @return A named list of all configuration defaults.
#' @noRd
raiddin_default_config <- function() {
  list(
    model = "claude-sonnet-4-6",
    api_key_source = "env",
    auto_approve = FALSE,
    env_size_threshold_mb = 50,
    always_push = character(0),
    approved_patterns = character(0),
    stream_responses = TRUE,
    max_tokens = 8192L
  )
}

#' Load RAiddin configuration from disk
#'
#' Reads the YAML config file if it exists and merges with defaults so that
#' any missing keys receive their default values.
#'
#' @return A named list of configuration values.
#' @noRd
raiddin_load_config <- function() {
  defaults <- raiddin_default_config()
  cfg_path <- raiddin_config_path()
  if (!file.exists(cfg_path)) {
    return(defaults)
  }
  on_disk <- yaml::read_yaml(cfg_path)
  for (key in names(defaults)) {
    if (is.null(on_disk[[key]])) {
      on_disk[[key]] <- defaults[[key]]
    }
  }
  on_disk
}

#' Save RAiddin configuration to disk
#'
#' Creates the `~/.raiddin/` directory if it does not exist, then writes the
#' supplied config list to `~/.raiddin/config.yaml`.
#'
#' @param config A named list of configuration values.
#' @return Invisibly `NULL`.
#' @noRd
raiddin_save_config <- function(config) {
  cfg_path <- raiddin_config_path()
  cfg_dir <- dirname(cfg_path)
  if (!dir.exists(cfg_dir)) {
    dir.create(cfg_dir, recursive = TRUE)
  }
  yaml::write_yaml(config, cfg_path)
  invisible(NULL)
}

#' Get a single RAiddin option value
#'
#' Returns a configuration value by name. The lookup order is:
#' 1. The R option `raiddin.<key>` (set via `raiddin_set_option()` or the
#'    `.onLoad` hook).
#' 2. The value stored in `~/.raiddin/config.yaml`.
#' 3. The hardcoded package default.
#'
#' @param key A single character string — the name of the configuration option
#'   (e.g. `"model"`, `"max_tokens"`).
#' @return The option value (type depends on the option).
#' @export
raiddin_get_option <- function(key) {
  r_opt <- getOption(paste0("raiddin.", key))
  if (!is.null(r_opt)) {
    return(r_opt)
  }
  cfg <- raiddin_load_config()
  if (!is.null(cfg[[key]])) {
    return(cfg[[key]])
  }
  raiddin_default_config()[[key]]
}

#' Set a single RAiddin option value
#'
#' Persists a configuration value to `~/.raiddin/config.yaml` and also sets
#' the corresponding R session option `raiddin.<key>` so that
#' `getOption("raiddin.<key>")` reflects the change immediately.
#'
#' @param key A single character string — the name of the configuration option.
#' @param value The value to store.
#' @return Invisibly `NULL`.
#' @export
raiddin_set_option <- function(key, value) {
  cfg <- raiddin_load_config()
  cfg[[key]] <- value
  raiddin_save_config(cfg)
  opt_name <- paste0("raiddin.", key)
  options(stats::setNames(list(value), opt_name))
  invisible(NULL)
}

#' Return all RAiddin configuration options
#'
#' Reads the config file and merges with defaults, returning the full set of
#' configuration values as a named list.
#'
#' @return A named list containing all RAiddin configuration options.
#' @export
raiddin_options <- function() {
  raiddin_load_config()
}

#' @keywords internal
.onLoad <- function(libname, pkgname) { # nolint: object_name_linter.
  cfg <- raiddin_load_config()
  opts <- stats::setNames(
    cfg,
    paste0("raiddin.", names(cfg))
  )
  options(opts)
}
