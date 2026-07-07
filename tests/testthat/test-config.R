test_that("raiddin_get_option() returns default when no config exists", {
  withr::with_tempdir({
    withr::local_envvar(HOME = getwd(), USERPROFILE = getwd())
    expect_equal(raiddin_get_option("model"), "claude-sonnet-4-6")
    expect_equal(raiddin_get_option("max_tokens"), 8192L)
    expect_false(raiddin_get_option("auto_approve"))
  })
})

test_that("raiddin_set_option() persists a value", {
  withr::with_tempdir({
    withr::local_envvar(HOME = getwd(), USERPROFILE = getwd())
    raiddin_set_option("model", "claude-haiku-4-5-20251001")
    expect_equal(raiddin_get_option("model"), "claude-haiku-4-5-20251001")
  })
})

test_that("raiddin_options() returns all keys", {
  withr::with_tempdir({
    withr::local_envvar(HOME = getwd(), USERPROFILE = getwd())
    opts <- raiddin_options()
    expect_type(opts, "list")
    required_keys <- c("model", "max_tokens", "auto_approve", "env_size_threshold_mb")
    expect_true(all(required_keys %in% names(opts)))
  })
})

test_that("R option overrides config file value", {
  withr::with_tempdir({
    withr::local_envvar(HOME = getwd(), USERPROFILE = getwd())
    withr::local_options(raiddin.model = "claude-opus-4-8")
    expect_equal(raiddin_get_option("model"), "claude-opus-4-8")
  })
})

test_that("raiddin_get_option() returns NULL for unknown key", {
  withr::with_tempdir({
    withr::local_envvar(HOME = getwd(), USERPROFILE = getwd())
    expect_null(raiddin_get_option("nonexistent_key_xyz"))
  })
})

test_that("raiddin_load_config() handles corrupt YAML gracefully", {
  withr::with_tempdir({
    withr::local_envvar(HOME = getwd(), USERPROFILE = getwd())
    dir.create(".raiddin")
    writeLines("{]", ".raiddin/config.yaml")
    expect_warning(
      cfg <- RAiddin:::raiddin_load_config(),
      regexp = "Could not read"
    )
  })
})
