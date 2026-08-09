# Nova same-run X11/AHB presentation split experiment — 2026-08-09

Status: predeclared; device result pending.

## Causal basis

The doc 96 run reached fresh SteamUI readiness and retained a valid
SurfaceFlinger AHB layer, but its native 1280x960 Android capture was dark
apart from the diagnostic marker. SurfaceFlinger showed the expected
960x540-to-1280x960 transform, so the remaining ambiguity is upstream: Steam's
CEF/GLX/Xwayland window may already be dark, or Gamescope may be losing visible
X11 content while importing/compositing it into the AHB output.

## One-variable harness change

Keep the doc 96 Gamescope binary, APK, AHB valid-content cadence, dimensions,
software CEF/GL flags, Steam readiness gate, input mapping, and cleanup contract
unchanged. Add only an opt-in, best-effort call to the existing X11 window
capture helper after fresh SteamUI readiness and before the Android screenshot
or any controller event:

```text
NOVA_CONTROLLER_UI_X11_CAPTURE=1
```

The helper will retain the mapped `Steam Big Picture Mode` X11 window tree,
window ID, and same-run PPM capture under the current `NOVA_RUN_DIR`. A missing
window or capture error is recorded as a diagnostic failure and must not alter
the strict Android presentation result or cause input to be sent. The capture
must use the same `NOVA_RUN_ID`, ADB serial, rootfs, Gamescope binary, and APK
provenance as the AHB artifacts.

## Device acceptance gate

Repeat the fresh doc 96 profile with the X11 diagnostic enabled. Preserve the
existing rule that the run is rejected unless the native Android capture is a
visible Steam surface. Record the X11 capture status even when it fails, and
retain the PPM only when the helper reports a successful capture.

Interpret the pair from the same run:

1. X11 dark and AHB dark: investigate CEF/GLX/Xwayland rendering or damage.
2. X11 visible and AHB dark: investigate Gamescope composition/output import.
3. X11 and AHB both visible: repair only any transform-aware marker/capture
   gate, then repeat the controlled A-button navigation test.

Do not change the AHB compositor, SurfaceControl destination, controller input,
network, audio, hardware-GL, touchscreen, login, or standalone-app paths in
this experiment. The X11 helper's SHA-256 and all same-run artifacts belong in
the result document.
