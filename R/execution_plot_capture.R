#' @noRd
recordedplot_to_base64 <- function(rp) {
  tmp <- tempfile(fileext = ".png")
  on.exit(unlink(tmp))
  grDevices::png(tmp)
  grDevices::replayPlot(rp)
  grDevices::dev.off()
  base64enc::base64encode(readBin(tmp, "raw", file.size(tmp)))
}

#' @noRd
raw_png_to_base64 <- function(raw_bytes) {
  base64enc::base64encode(raw_bytes)
}
