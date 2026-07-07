#' @noRd
recordedplot_to_base64 <- function(rp) {
  tmp <- tempfile(fileext = ".png")
  on.exit(unlink(tmp))
  grDevices::png(tmp)
  tryCatch(
    grDevices::replayPlot(rp),
    error = function(e) {
      grDevices::dev.off()
      stop(e)
    }
  )
  grDevices::dev.off()
  base64enc::base64encode(readBin(tmp, "raw", file.size(tmp)))
}

#' @noRd
raw_png_to_base64 <- function(raw_bytes) {
  base64enc::base64encode(raw_bytes)
}
