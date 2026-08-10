# Nova one-click known-good profile result — 2026-08-10

Status: the visible APK `Start Steam` button now launches the tested prepared-
device profile. The run reached the signed-in Steam Big Picture home with
audible-output transport and a clean stop. This is not yet the standalone
rootless/Gamescope product acceptance.

## Run identity and provenance

- Experiment: `nova-one-click-known-good-profile-20260810T151313Z`
- Launcher session: `20260810T151454Z-32133`
- Device: Retroid Pocket Nova, Android 13, adb serial `675a2365`, `kalama`
- Source commit: `5d393cc`
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256: `168b89ecd063ff5479223ffa52843c137a5a095c003c759336f63729ae7739a3`
- Profile source: visible `LauncherActivity` `Start Steam` button; no Steam
  launch extras were supplied
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- External display dependency: installed Termux:X11 APK
- Host evidence: `android/nova-lab/build/runs/nova-one-click-known-good-profile-20260810T151313Z/`
- Settled Steam screenshot SHA-256:
  `7f98333d43d3e4e620c923a7945fde101295253f3926958ec6e829fc08e5d6a7`

The APK was started with `am start` only to open its launcher Activity. The
session itself was started by tapping the visible button at `(640,445)`. The
APK's default profile selected the values predeclared in [315](315-nova-one-click-known-good-profile-predeclaration-2026-08-10.md).

## Launcher and Steam result

The fresh launcher log recorded every expected default:

```text
nova_launcher_hardware_accel=1
nova_launcher_vulkan_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
nova_launcher_cef_disable_gpu=1
nova_launcher_steam_ui_mode=gamepadui
nova_launcher_steam_disable_preload=0
nova_launcher_steam_disable_system_dbus=0
nova_launcher_steam_holo_mesa_first=0
nova_launcher_steam_force_software_gl=1
nova_launcher_steam_cef_env_split=1
nova_launcher_audio_bridge=1
nova_launcher_gamepad=pass
nova_launcher_input_allow=event9
nova_launcher_ready=pass display=:0 geometry=1280x960
```

The client log independently recorded the same profile, both private D-Bus
probes passing, `client_network_api_compat_status=0`, and
`client_started=pass`. The settled `1280x960` capture shows the signed-in
Steam Big Picture home/library screen filling the Nova display. The extra
Termux:X11 keyboard bar remained suppressed.

## Audio result

The default button path enabled the Android playback bridge without an adb
extra. One naturally closed connection matched exactly:

```text
C preload attempted: 1343488 frames
C preload sent:      1343488 frames
Android accepted:    1343488 frames
short_writes=0
zero_writes=0
send_failures=0
```

The Android log recorded `AudioTrack: stop ... 1343488 frames delivered`.
The final AudioFlinger history retained the current `3844`-frame client
buffer. The earlier latency run remains the authoritative live comparison of
that buffer against the prior `7688`-frame track; this button-acceptance run
did not sample the active latency field before the stream naturally closed.
No new subjective timing observation was made here, so the known delayed UI
sound report remains open.

## Cleanup and evidence boundary

The exact launcher stop returned `nova_launcher_stop=pass`, including
`nova_x11_cleanup=pass` and `nova_launcher_x11_stretch_restore=pass`.
`nova_runtime_cleanup=pass` and the final matching-process audit were empty.

This result proves:

```text
APK Start button
  -> foreground service
  -> exact rooted launcher
  -> Termux:X11 + native ARM64 Steam
  -> known-good audio bridge and controller relay readiness
  -> visible signed-in Steam UI
```

It does not prove the remaining product requirements:

- no-root/no-Magisk operation;
- app-owned runtime acquisition instead of a manually staged rootfs;
- no external Termux:X11 dependency;
- Gamescope/AHardwareBuffer ownership of the product session;
- hardware-accelerated Steam CEF rendering (CEF GPU was deliberately disabled);
- touch-driven Steam navigation rather than touch transport; or
- low-latency audio and Steam's own audio-device discovery/capture surfaces.

The next implementation should therefore target the product boundary, not
alter this now-reproducible prepared-device profile: preserve the button
defaults as the regression baseline while moving the session launcher toward
app-owned Gamescope/AHardwareBuffer presentation and runtime acquisition.
