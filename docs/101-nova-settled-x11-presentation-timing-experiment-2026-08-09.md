# Nova settled X11 presentation timing experiment — 2026-08-09

Status: predeclared; device result pending.

## Causal basis

Docs 98 and 100 both captured a valid, mapped Steam Big Picture X11 window
immediately after SteamUI readiness, and both samples were black. Their Android
screenshots were sampled only after the controller's 30-second settle delay.
The resolution comparison did not change the X11 baseline, but the two images
were still not sampled at the same settled point in the session.

## One-variable harness change

Keep the doc 100 1280x960 Gamescope/AHB output, APK, software CEF/GL flags,
Steam readiness gate, input mapping, AHB cadence, and cleanup contract
unchanged. Add only the opt-in settled X11 phase:

```text
NOVA_CONTROLLER_UI_X11_CAPTURE=1
NOVA_CONTROLLER_UI_X11_CAPTURE_AFTER_SETTLE=1
```

After fresh UI readiness, the controller waits the existing
`NOVA_CONTROLLER_UI_SETTLE_DELAY` once, dismisses any Android settings overlay,
captures the mapped X11 window, and immediately samples the Android surface.
The X11 helper records a distinct `settled` phase and fresh window ID under the
same run directory. A capture failure remains non-gating and cannot cause
input to be sent.

## Device acceptance gate

Retain the strict visible Android Steam-surface gate and the full AHB marker /
identity / cleanup checks. Interpret the same-run settled pair as:

1. Settled X11 black and Android dark: isolate CEF software rendering,
   Xwayland damage, or a known-good synthetic X11 client before changing
   Gamescope.
2. Settled X11 visible and Android dark: isolate Gamescope AHB output import
   with synchronized captures.
3. Both settled captures visible: repair only any remaining marker or
   transform-aware acceptance gate, then repeat A-button navigation.

Do not claim hardware GL, audio, touchscreen, networking, login, or standalone
launcher acceptance from this diagnostic.
