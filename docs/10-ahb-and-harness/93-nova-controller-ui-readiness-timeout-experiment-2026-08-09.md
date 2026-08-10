# Nova controller UI readiness-timeout experiment — 2026-08-09

Status: predeclared; device result pending.

## Causal basis

The doc 92 timeout-split run reached `client_status=124`,
`client_installed=pass`, and `native_steam_smoke=pass`, but the outer
controller harness still reported `controller_ui_surface=missing`. The
nested Steam client was allowed 180 seconds while the outer harness waited
only its default 140 seconds for fresh `steamwebhelper` and SteamUI markers.
That result cannot distinguish late UI readiness from a missing visible
surface.

## One-variable run

Repeat the same libei-enabled valid-content cadence binary, full-screen
1280x960 presentation, 240-frame AHB target, frame identity/marker, scheduler
and socket traces, software CEF/GL flags, overlay guard, and Android A-button
mapping. Change only the outer readiness timeout:

```text
NOVA_CONTROLLER_UI_WAIT_TIMEOUT=240
NOVA_STEAM_CLIENT_TIMEOUT=180
NOVA_STEAM_GAMESCOPE_TIMEOUT=300
```

The controlled input remains:

```text
KEYCODE_BUTTON_A=96
BTN_SOUTH=304
```

The run must use a fresh run ID/profile, fresh Steam log baselines, and the
same exact Gamescope/APK provenance checks as doc 92.

## Acceptance gate

Accept only a run that reaches the fresh Steam surface, sends the A-button,
proves the Android bridge and Steam input-FD ownership, observes the expected
OOBE navigation change, and retains the complete 240-frame marker-correlated
AHB result with cleanup passing. A run that reaches native Steam startup but
still lacks `controller_ui_ready=1` remains a UI-startup diagnostic and does
not advance the login milestone.

If the UI is still absent after the extended window, preserve the fresh
client stdout/stderr and SteamUI/webhelper readiness evidence before changing
GL/CEF, DBus, networking, audio, or Gamescope presentation code.

