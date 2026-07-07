#' Show the interactive code approval modal
#'
#' Displays a Shiny modal asking the user to approve or deny a code block
#' proposed by Claude. The modal shows the full code in a `<pre>` block and
#' offers Approve / Deny buttons plus an optional "remember pattern" checkbox.
#'
#' @param code A character(1) string of R code to display.
#' @return Invisible `NULL` (called for side effects on the Shiny session).
#' @noRd
show_approval_modal <- function(code) {
  shiny::showModal(
    shiny::modalDialog(
      title = "Approve Code Execution?",
      shiny::div(
        class = "approval-modal-body",
        shiny::p("Claude wants to run the following code:"),
        shiny::pre(class = "approval-code", code),
        shiny::checkboxInput(
          "modal_remember_pattern",
          label = "Remember: always approve code containing this text",
          value = FALSE
        )
      ),
      footer = shiny::tagList(
        shiny::actionButton("modal_deny", "Deny", class = "btn btn-danger"),
        shiny::actionButton("modal_approve", "Approve", class = "btn btn-success")
      ),
      size = "l",
      easyClose = FALSE
    )
  )
}
