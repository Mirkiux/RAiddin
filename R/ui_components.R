#' Render a single conversation turn as an HTML tag
#'
#' @param role One of `"user"` or `"assistant"`.
#' @param content_blocks A list of content blocks (text, image, tool_result,
#'   tool_use).
#' @return A `shiny.tag` object.
#' @noRd
render_turn <- function(role, content_blocks) {
  css_class <- if (identical(role, "user")) "turn turn-user" else "turn turn-assistant"
  blocks_html <- lapply(content_blocks, render_content_block)
  shiny::div(class = css_class, blocks_html)
}

#' Render a single content block as HTML
#'
#' @param block A content block list with at least a `type` field.
#' @return A `shiny.tag` object.
#' @noRd
render_content_block <- function(block) {
  switch(block$type,
    text = shiny::div(
      class = "content-text",
      shiny::HTML(render_markdown_text(block$text))
    ),
    image = shiny::div(
      class = "content-image",
      shiny::tags$img(
        src = paste0("data:image/png;base64,", block$source$data),
        class = "inline-plot"
      )
    ),
    tool_use = shiny::div(
      class = "content-tool-use",
      shiny::div(class = "tool-header", paste0("\U0001F527 ", block$name)),
      shiny::pre(class = "tool-input", jsonlite::toJSON(block$input, auto_unbox = TRUE, pretty = TRUE))
    ),
    tool_result = shiny::div(
      class = if (isTRUE(block$is_error)) "content-tool-result error" else "content-tool-result",
      shiny::div(class = "tool-header", "\U1F4E4 Result"),
      lapply(if (is.list(block$content)) block$content else list(), render_content_block)
    ),
    shiny::div(class = "content-unknown", paste0("[", block$type, "]"))
  )
}

#' Escape special HTML characters in a plain string
#' @noRd
.html_escape <- function(text) {
  text <- gsub("&", "&amp;", text, fixed = TRUE)
  text <- gsub("<", "&lt;", text, fixed = TRUE)
  text <- gsub(">", "&gt;", text, fixed = TRUE)
  text <- gsub("\"", "&quot;", text, fixed = TRUE)
  text
}

#' Very lightweight Markdown-to-HTML conversion for chat display
#'
#' Handles code fences and inline code only. Everything else is HTML-escaped.
#'
#' @param text A character(1) string.
#' @return A character(1) HTML string.
#' @noRd
render_markdown_text <- function(text) {
  escaped <- .html_escape(text)
  fenced <- gsub(
    "```([a-zA-Z]*)\\n([\\s\\S]*?)```",
    "<pre class='code-block'><code>\\2</code></pre>",
    escaped,
    perl = TRUE
  )
  inline_code <- gsub("`([^`]+)`", "<code>\\1</code>", fenced, perl = TRUE)
  gsub("\n", "<br>", inline_code, fixed = TRUE)
}

#' Build the HTML for the full conversation history
#'
#' @param messages A list of message objects (role + content).
#' @return A `shiny.tag` list.
#' @noRd
render_conversation <- function(messages) {
  lapply(messages, function(msg) {
    content <- if (is.character(msg$content)) {
      list(list(type = "text", text = msg$content))
    } else {
      msg$content
    }
    render_turn(msg$role, content)
  })
}
