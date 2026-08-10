# Nova one-click known-good profile predeclaration — 2026-08-10

Status: predeclared; the APK default-profile change and its device acceptance
are pending.

## Question

Does tapping the APK's visible `Start Steam` button start the same prepared-
device profile that already reached the signed-in Steam UI with audible output,
the 4:3 Android surface, and the rooted controller relay? The current
`LauncherActivity` only enables the AudioTrack bridge when an adb intent extra
is supplied, and its ordinary button path defaults `hardware_accel` to false.
That makes the product button materially different from the known-good manual
launch command.

## Narrow implementation

For the normal `LauncherActivity` start path, use these defaults while
preserving explicit intent extras for diagnostics and bounded harnesses:

```text
audio_bridge=1
hardware_accel=1
cef_disable_gpu=1
steam_ui_mode=gamepadui
steam_disable_preload=0
steam_disable_system_dbus=0
steam_holo_mesa_first=0
steam_force_software_gl=1
steam_cef_env_split=1
```

This is the current successful compromise: Android/Termux:X11 and the Vulkan
ICD remain available for the session and future games, while the known-failing
CEF hardware path stays explicitly disabled and the software GL fallback is
kept for Steam's client UI. The AudioTrack bridge remains playback-only; this
change does not claim Steam device discovery, capture, low-latency audio,
rootless operation, or hardware-accelerated CEF.

Explicit extras continue to win over these defaults so the diagnostic APK and
each predeclared experiment can select a different profile without changing
the product button's baseline.

## Device acceptance contract

Build and install the APK, stop any existing Nova session with the exact
launcher cleanup path, and start only through the visible `Start Steam` button.
Capture a fresh run directory containing:

1. APK and helper SHA-256 values;
2. launcher markers showing the defaults above, audio bridge readiness,
   relay readiness, and `nova_launcher_ready=pass`;
3. a fresh 1280x960 Steam screenshot and client log;
4. bridge counters with a naturally closed stream and no short/zero writes;
5. AudioFlinger track information for the current `3844`-frame buffer; and
6. exact launcher/X11/runtime cleanup plus an empty matching-process audit.

The run must distinguish “APK button started the known-good profile” from the
stronger product requirements that remain open: no Termux/rootfs dependency,
native Gamescope/AHardwareBuffer ownership, hardware CEF rendering, Steam
device enumeration, touch-driven Steam navigation, and subjective audio
latency.
