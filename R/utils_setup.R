#' Interactive RAiddin setup wizard
#'
#' Guides the user through first-time configuration: API key instructions,
#' model selection, connectivity test, and config save. All output uses
#' [message()] so it can be suppressed with [suppressMessages()].
#'
#' @return Invisibly `NULL`.
#' @export
raiddin_setup <- function() {
  message("=== RAiddin Setup Wizard ===\n")

  # Step 1: API key
  message("Step 1: API Key")
  message(
    "RAiddin reads your Anthropic API key from the ANTHROPIC_API_KEY ",
    "environment variable."
  )
  message(
    "To set it permanently, add the following line to your ~/.Renviron file:"
  )
  message("  ANTHROPIC_API_KEY=your-key-here")
  message(
    "Then restart R or run: readRenviron('~/.Renviron')\n"
  )

  # Step 2: Model selection
  message("Step 2: Model Selection")
  available_models <- c(
    "claude-sonnet-4-6",
    "claude-opus-4-5",
    "claude-haiku-4-5"
  )
  message("Available models:")
  for (i in seq_along(available_models)) {
    message("  [", i, "] ", available_models[[i]])
  }
  current_model <- raiddin_get_option("model")
  message("Current model: ", current_model)
  raw_input <- readline("Enter model number or name (press Enter to keep current): ")
  chosen_model <- current_model
  if (nzchar(trimws(raw_input))) {
    trimmed <- trimws(raw_input)
    if (grepl("^[0-9]+$", trimmed)) {
      idx <- as.integer(trimmed)
      if (idx >= 1L && idx <= length(available_models)) {
        chosen_model <- available_models[[idx]]
      } else {
        message("Invalid selection. Keeping current model: ", current_model)
      }
    } else if (trimmed %in% available_models) {
      chosen_model <- trimmed
    } else {
      message("Unrecognised model name. Keeping current model: ", current_model)
    }
  }

  # Step 3: Test connectivity
  message("\nStep 3: Testing API connectivity...")
  key_ok <- tryCatch(
    {
      get_api_key()
      TRUE
    },
    error = function(e) {
      message("API key check failed: ", conditionMessage(e))
      message(
        "Please set ANTHROPIC_API_KEY in your ~/.Renviron and re-run raiddin_setup()."
      )
      FALSE
    }
  )

  # Step 4: Save and summarise
  if (key_ok) {
    raiddin_set_option("model", chosen_model)
    message("\nConfiguration saved successfully.")
    message("Summary:")
    message("  model: ", raiddin_get_option("model"))
    message("  api_key_source: ", raiddin_get_option("api_key_source"))
    message("  max_tokens: ", raiddin_get_option("max_tokens"))
    message("  stream_responses: ", raiddin_get_option("stream_responses"))
    message("\nRAiddin is ready to use.")
  }

  invisible(NULL)
}
