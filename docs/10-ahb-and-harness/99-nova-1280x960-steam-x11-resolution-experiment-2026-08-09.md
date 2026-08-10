# Nova 1280x960 Steam/X11 resolution experiment — 2026-08-09

Status: predeclared; device result pending.

## Causal basis

The doc 98 same-run capture found a viewable Steam Big Picture X11 window but
the 960x540 capture was uniformly black, while the downstream 1280x960 AHB
capture remained dark. The timing of the two captures was not identical. More
importantly, the earlier visible software-CEF controls in docs 54 and 60 used
a 1280x960 Steam/Xwayland window. The current profile therefore has a concrete
resolution boundary that must be tested before changing Gamescope composition
or CEF rendering behavior.

## One-variable device change

Keep the doc 98 Gamescope binary, APK, valid-content cadence, software CEF/GL
flags, Steam readiness gate, X11 diagnostic, Android destination, input path,
timeouts, and cleanup contract unchanged. Change only the producer/Xwayland
output dimensions:

```text
NOVA_AHB_WIDTH=1280
NOVA_AHB_HEIGHT=960
NOVA_FULLSCREEN_WIDTH=1280
NOVA_FULLSCREEN_HEIGHT=960
```

The existing X11 helper must rediscover the mapped window in this fresh run;
do not reuse its prior window ID or image. The A-button remains gated on a
visible Android Steam surface, so no input is sent if the presentation gate
fails.

## Device acceptance gate

Record the fresh run's Steam window dimensions, X11 PPM statistics, Android
capture, SurfaceFlinger geometry, AHB marker/identity result, client renderer
report, and explicit post-stop verification. The resolution comparison is
interpreted as:

1. Visible 1280x960 X11 and Android: the 960x540 path is the leading
   low-resolution Steam/CEF/Xwayland incompatibility; retain 1280x960 for the
   end-user presentation and document the smaller profile as unsupported.
2. Visible 1280x960 X11 with dark Android: return to Gamescope AHB output
   import with a synchronized X11/Android capture.
3. Black 1280x960 X11: isolate software CEF/GLX/Xwayland using the known-good
   synthetic X11 client before making another compositor change.

Do not claim hardware GL, audio, touchscreen, networking, login, or standalone
launcher acceptance from this experiment.
