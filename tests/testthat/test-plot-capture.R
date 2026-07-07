test_that("raw_png_to_base64() encodes raw bytes as base64 string", {
  raw_bytes <- as.raw(c(0x89, 0x50, 0x4e, 0x47))
  result <- RAiddin:::raw_png_to_base64(raw_bytes)
  expect_type(result, "character")
  expect_equal(result, base64enc::base64encode(raw_bytes))
})

test_that("recordedplot_to_base64() returns a non-empty base64 string", {
  skip_on_cran()
  grDevices::png(tempfile(fileext = ".png"))
  plot(1)
  rp <- grDevices::recordPlot()
  grDevices::dev.off()
  result <- RAiddin:::recordedplot_to_base64(rp)
  expect_type(result, "character")
  expect_true(nchar(result) > 0L)
})

test_that("recordedplot_to_base64() cleans up temp file", {
  skip_on_cran()
  before <- length(list.files(tempdir(), pattern = "\\.png$"))
  grDevices::png(tempfile(fileext = ".png"))
  plot(2)
  rp <- grDevices::recordPlot()
  grDevices::dev.off()
  RAiddin:::recordedplot_to_base64(rp)
  after <- length(list.files(tempdir(), pattern = "\\.png$"))
  expect_lte(after, before + 1L)
})

test_that("uses_plot_functions() detects ggplot", {
  expect_true(uses_plot_functions("ggplot(df, aes(x)) + geom_histogram()"))
})

test_that("uses_plot_functions() detects barplot", {
  expect_true(uses_plot_functions("barplot(c(1, 2, 3))"))
})

test_that("uses_plot_functions() does not flag ordinary function calls", {
  expect_false(uses_plot_functions("sum(x); lm(y ~ x)"))
})
