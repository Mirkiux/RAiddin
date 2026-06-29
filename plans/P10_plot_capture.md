---
plan: P10
title: Plot Capture Pipeline
status: not started
---

## Objective
Capture R plots generated during code execution, encode as base64, and pass them as image content blocks to Claude's vision API.

## Pipeline

1. **Plot detection** (before execution):
   - Run `codetools::findGlobals()` on the code to be executed.
   - Check intersect with known plot functions: `plot`, `ggplot`, `print.ggplot`, `hist`, `barplot`, `boxplot`, `pairs`, `image`, `contour`, `persp`, `curve`, etc.
   - If no match found: skip PNG device entirely (no token cost).

2. **Device setup** (if plots expected):
   ```r
   tmp_png <- tempfile(fileext = ".png")
   grDevices::png(tmp_png, width = 800, height = 600, res = 120)
   ```

3. **Execution**: run code through evaluate or callr (see P08).

4. **Device teardown**:
   ```r
   grDevices::dev.off()
   ```

5. **Encode**:
   ```r
   base64enc::base64encode(tmp_png)
   ```

6. **Claude API content block**:
   ```json
   {
     "type": "image",
     "source": {
       "type": "base64",
       "media_type": "image/png",
       "data": "<base64 string>"
     }
   }
   ```

7. **Cleanup**: `unlink(tmp_png)` after encoding.

## Edge cases
- Multiple plots in one execution: capture as separate PNG files, send as multiple image blocks.
- No plot generated despite detection: send no image block (check if file is non-empty before encoding).
- Device already open: use `dev.new()` to avoid clobbering user's active device.

## Key files
- `R/execution/plot_capture.R`

## Dependencies
P08, P09
