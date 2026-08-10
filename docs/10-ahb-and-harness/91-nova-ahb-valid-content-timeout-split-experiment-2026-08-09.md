# Nova AHB valid-content timeout-split experiment — 2026-08-09

Status: predeclared; device result pending.

## Causal basis

Doc 90 recorded 240 consecutive AHardwareBuffer frames and continuous
Gamescope `Present()` calls with the valid-content cadence binary, but the
controller run ended with the native Steam log stopping at
`client_started=pass`. The nested client wrapper waits for Steam before
writing `client_status` and `client_installed`; the outer Gamescope timeout
was configured to the same 300-second deadline and can kill that wrapper
first.

## One-variable harness change

Repeat the exact doc 90 run with the same binary, source tree, APK rebuild,
fullscreen 1280x960 mode, AHB target of 240, frame identity/marker, input
mapping, overlay guard, and scheduler trace. Change only:

```text
NOVA_STEAM_CLIENT_TIMEOUT=180
NOVA_STEAM_GAMESCOPE_TIMEOUT=300
```

This gives the nested client wrapper time to emit its post-wait markers before
Gamescope's outer acceptance timeout. No compositor or Android presentation
code changes are included in this experiment.

## Acceptance gate

Require the existing client markers `client_started=pass`,
`client_status=...`, and `client_installed=pass`, plus the existing doc 89
gate:

```text
controller_ui_navigation=pass
ahb_frame_marker_capture=pass
ahb_double_buffer_frames=240 releases=239
post_stop_verification=pass
```

The final screenshot must show a visible, run-correlated Steam surface. A
timeout-split run that only proves AHB frames or a dark marker capture remains
partial and does not advance the login milestone. If the gate passes, repeat
once with `NOVA_AHB_SCHEDULER_TRACE=0` before moving to network/login, audio,
hardware CEF/GL, touchscreen, or standalone-app work.
