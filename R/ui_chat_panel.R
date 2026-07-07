#' Build the chat panel UI
#' @noRd
.chat_panel_ui <- function() {
  css_path <- system.file("shiny/www/styles.css", package = "RAiddin")
  miniUI::miniPage(
    miniUI::gadgetTitleBar(
      "RAiddin",
      right = miniUI::miniTitleBarButton("btn_settings", "⚙", primary = FALSE)
    ),
    shiny::tags$head(
      if (nzchar(css_path)) shiny::includeCSS(css_path)
    ),
    miniUI::miniContentPanel(
      shiny::div(
        id = "chat-history-container",
        shiny::uiOutput("chat_history")
      ),
      shiny::conditionalPanel(
        "input.btn_settings % 2 == 1",
        shiny::div(
          class = "settings-panel",
          shiny::selectInput(
            "setting_model",
            "Model",
            choices = c(
              "claude-sonnet-4-6",
              "claude-opus-4-8",
              "claude-haiku-4-5-20251001"
            ),
            selected = raiddin_get_option("model")
          ),
          shiny::checkboxInput(
            "setting_auto_approve",
            "Auto-approve all code execution",
            value = is_auto_approve()
          ),
          shiny::sliderInput(
            "setting_threshold_mb",
            "Env object push limit (MB)",
            min = 10, max = 500, value = raiddin_get_option("env_size_threshold_mb"), step = 10
          ),
          shiny::actionButton("btn_clear", "Clear conversation", class = "btn btn-warning btn-sm")
        )
      )
    ),
    miniUI::miniButtonBar(
      shiny::div(
        class = "input-area",
        shiny::textAreaInput("prompt", NULL, placeholder = "Ask Claude...", rows = 3),
        shiny::div(
          class = "input-buttons",
          shiny::actionButton("btn_use_selection", "Selection", class = "btn-sm"),
          shiny::actionButton("btn_use_document", "Document", class = "btn-sm"),
          shiny::actionButton("btn_send", "Send", class = "btn btn-primary btn-sm")
        ),
        shiny::div(
          class = "status-bar",
          shiny::textOutput("status_text", inline = TRUE),
          shiny::span(" | Tokens: "),
          shiny::textOutput("token_count", inline = TRUE)
        )
      )
    )
  )
}

#' Chat panel Shiny server
#' @noRd
.chat_panel_server <- function(input, output, session) {
  rv <- shiny::reactiveValues(
    messages         = list(),
    status           = "Idle",
    token_count      = 0L,
    pending_calls    = list(),
    pending_results  = list(),
    pending_code     = NULL
  )

  output$status_text <- shiny::renderText(rv$status)
  output$token_count <- shiny::renderText(as.character(rv$token_count))
  output$chat_history <- shiny::renderUI(
    shiny::div(class = "chat-history", render_conversation(rv$messages))
  )

  shiny::observeEvent(input$setting_auto_approve, {
    set_auto_approve(isTRUE(input$setting_auto_approve))
  })

  shiny::observeEvent(input$btn_clear, {
    rv$messages <- list()
    rv$token_count <- 0L
    rv$pending_calls <- list()
    rv$pending_results <- list()
    rv$status <- "Idle"
  })

  shiny::observeEvent(input$btn_use_selection, {
    sel <- tryCatch(get_selection()$text, error = function(e) NULL)
    if (!is.null(sel) && nzchar(sel)) {
      current <- shiny::isolate(input$prompt)
      shiny::updateTextAreaInput(session, "prompt",
        value = paste0(current, "\n\n```r\n", sel, "\n```")
      )
    }
  })

  shiny::observeEvent(input$btn_use_document, {
    doc <- tryCatch(get_document(), error = function(e) NULL)
    if (!is.null(doc) && nzchar(doc)) {
      current <- shiny::isolate(input$prompt)
      shiny::updateTextAreaInput(session, "prompt",
        value = paste0(current, "\n\n```r\n", doc, "\n```")
      )
    }
  })

  shiny::observeEvent(input$btn_send, {
    prompt_text <- trimws(input$prompt)
    if (!nzchar(prompt_text)) {
      return()
    }
    shiny::updateTextAreaInput(session, "prompt", value = "")
    rv$messages <- c(rv$messages, list(user_message(prompt_text)))
    rv$status <- "Thinking…"
    .run_turn(rv, session, input$setting_model, input$setting_threshold_mb)
  })

  shiny::observeEvent(input$modal_approve, {
    shiny::removeModal()
    code <- shiny::isolate(rv$pending_code)
    if (isTRUE(input$modal_remember_pattern) && !is.null(code)) {
      tryCatch(add_approved_pattern(code), error = function(e) NULL)
    }
    rv$pending_code <- NULL
    .execute_current_tool(rv, session, input$setting_model, input$setting_threshold_mb,
      approved = TRUE
    )
  })

  shiny::observeEvent(input$modal_deny, {
    shiny::removeModal()
    rv$pending_code <- NULL
    .execute_current_tool(rv, session, input$setting_model, input$setting_threshold_mb,
      approved = FALSE
    )
  })

  shiny::observeEvent(input$done, {
    shiny::stopApp()
  })
}

#' Run one Claude turn: call the API, then dispatch tool calls sequentially
#' @noRd
.run_turn <- function(rv, session, model, threshold_mb) {
  model <- model %||% raiddin_get_option("model")
  response <- tryCatch(
    chat_completion(rv$messages, model = model, tools = raiddin_tools()),
    error = function(e) NULL
  )
  if (is.null(response)) {
    rv$status <- "Error: API call failed."
    return()
  }
  rv$token_count <- rv$token_count +
    (response$usage$input_tokens %||% 0L) +
    (response$usage$output_tokens %||% 0L)

  rv$messages <- c(rv$messages, list(assistant_message(response$content)))

  if (!has_tool_calls(response)) {
    rv$status <- "Idle"
    return()
  }

  rv$pending_calls <- extract_tool_calls(response)
  rv$pending_results <- list()
  .process_next_tool(rv, session, model, threshold_mb)
}

#' Advance to and process the next pending tool call
#' @noRd
.process_next_tool <- function(rv, session, model, threshold_mb) {
  if (length(rv$pending_results) >= length(rv$pending_calls)) {
    .flush_tool_results(rv, session, model, threshold_mb)
    return()
  }
  idx <- length(rv$pending_results) + 1L
  tc <- rv$pending_calls[[idx]]
  rv$status <- paste0("Executing: ", tc$name, "…")

  if (identical(tc$name, "execute_r_code")) {
    approval <- check_code_approval(tc$input$code)
    if (!approval$approved) {
      rv$pending_code <- tc$input$code
      show_approval_modal(tc$input$code)
      return()
    }
  }
  .execute_current_tool(rv, session, model, threshold_mb, approved = TRUE)
}

#' Execute the current tool (already approved or no approval needed)
#' @noRd
.execute_current_tool <- function(rv, session, model, threshold_mb, approved) {
  idx <- length(rv$pending_results) + 1L
  tc <- rv$pending_calls[[idx]]

  if (!approved && identical(tc$name, "execute_r_code")) {
    dr <- list(
      content  = list(text_block("[error] Code execution denied by user.")),
      is_error = TRUE
    )
  } else {
    dr <- dispatch_tool(tc, on_approval_required = function(x) TRUE)
  }

  block <- list(type = "tool_result", tool_use_id = tc$id, content = dr$content)
  if (isTRUE(dr$is_error)) block$is_error <- TRUE
  rv$pending_results <- c(rv$pending_results, list(block))
  .process_next_tool(rv, session, model, threshold_mb)
}

#' Send all accumulated tool results back to Claude
#' @noRd
.flush_tool_results <- function(rv, session, model, threshold_mb) {
  rv$messages <- c(rv$messages, list(user_message(rv$pending_results)))
  rv$pending_calls <- list()
  rv$pending_results <- list()
  rv$status <- "Thinking…"
  .run_turn(rv, session, model, threshold_mb)
}

#' Launch the RAiddin agentic chat panel
#'
#' Opens a Shiny gadget in the RStudio Viewer pane. The panel maintains full
#' conversation history, visualises tool calls, renders inline plots, and
#' requests user approval before executing any code block that is not already
#' pre-approved.
#'
#' @return Invisible `NULL` (called for side effects).
#' @export
launch_chat_panel <- function() {
  shiny::runGadget(
    .chat_panel_ui(),
    .chat_panel_server,
    viewer = shiny::paneViewer(minHeight = 300)
  )
  invisible(NULL)
}

#' Explain the selected code using Claude
#'
#' Addin binding: sends the current RStudio selection to Claude with a
#' "Explain this R code" prompt and opens the chat panel showing the response.
#'
#' @return Invisible `NULL` (called for side effects).
#' @export
explain_selection <- function() {
  sel <- tryCatch(get_selection()$text, error = function(e) "")
  if (!nzchar(trimws(sel))) {
    shiny::showNotification("No code selected.", type = "warning")
    return(invisible(NULL))
  }
  prompt <- paste0("Explain this R code:\n\n```r\n", sel, "\n```")
  .launch_with_prompt(prompt)
}

#' Fix or improve the selected code using Claude
#'
#' Addin binding: sends the current RStudio selection to Claude with a
#' "Fix or improve this R code" prompt and opens the chat panel.
#'
#' @return Invisible `NULL` (called for side effects).
#' @export
fix_selection <- function() {
  sel <- tryCatch(get_selection()$text, error = function(e) "")
  if (!nzchar(trimws(sel))) {
    shiny::showNotification("No code selected.", type = "warning")
    return(invisible(NULL))
  }
  prompt <- paste0("Fix or improve this R code:\n\n```r\n", sel, "\n```")
  .launch_with_prompt(prompt)
}

#' Launch the chat panel pre-loaded with an initial user prompt
#' @noRd
.launch_with_prompt <- function(prompt) {
  server <- function(input, output, session) {
    shiny::observe({
      shiny::updateTextAreaInput(session, "prompt", value = prompt)
    })
    .chat_panel_server(input, output, session)
  }
  shiny::runGadget(
    .chat_panel_ui(),
    server,
    viewer = shiny::paneViewer(minHeight = 300)
  )
  invisible(NULL)
}
