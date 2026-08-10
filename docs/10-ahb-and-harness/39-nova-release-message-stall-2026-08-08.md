# Nova AHardwareBuffer release-message stall — 2026-08-08

Status: confirmed on a fresh manual run; the failure is downstream of the
Steam X11 window and upstream of the Android screenshot. No ownership or
buffer-ring change has been made yet.

## Run identity

| Field | Value |
| --- | --- |
| Run | `legacy-20260808T222115Z-53956` |
| Started | `2026-08-08T22:21:15Z` |
| Output | `1280x960`, fullscreen, 4:3 |
| Gamescope | `android/nova-lab/build/gamescope-headless-build-libei/src/gamescope` |
| Gamescope SHA-256 | `93f4807d55e4ad95e8cbd7c1622f97c3ccd7781952aec3b08cd44ee64a449e8f` |
| Gamescope source | `gamescope-headless-source-six`, commit `fb9f84ee247a1f02b1a132da60e94585db84bf61` |
| Input/presentation | libei enabled; Android keyevent input; GPU composition forced (`0`) |
| APK SHA-256 | `e80c978709dbaa3ecaac0553115f8fc83dc207414f92bfc9296311c391bcbe5e` |
| X11 helper SHA-256 | `a8971824bfcb812139bcc7451a1ab2c262b4a2af0ff9d462e25206a3efb4b017` |

The run stopped through the exact-scope helper and reported
`nova_runtime_cleanup=pass`, `native_steam_runtime_cleanup=pass`, and
`native_steam_app_files_cleanup=pass`.

## Reproduction

1. The fresh CDP target started at `/routes/oobe/1/language`. The Android
   screenshot showed the language page at the expected 1280x960 resolution.
2. `adb shell input keyevent 96` was accepted and logged by the app as
   `android_input_key_dispatch`. CDP reached `/routes/oobe/1/timezone` within
   three seconds. Android still showed language at +3s, then showed timezone by
   +12s. This is a real presentation delay, but not the terminal failure.
3. Repeated root-side X11 capture commands caused `com.rp.settings` to regain
   the Android input focus with its USB chooser. The A event issued while that
   overlay owned focus was not forwarded. Pressing Back restored the Nova
   Activity; subsequent input evidence must check focus immediately before the
   event. This is a harness/operator-state issue separate from the AHB stall.
4. After the overlay was dismissed, a second A event was logged and CDP
   reached `/routes/oobe/1/network`. The mapped Steam X11 window `0x240003b`
   captured the network page, while Android screenshots at both +3s and +12s
   remained the timezone page. Their SHA-256 was identical:
   `30bb7ffe8386630c0cd2175705b51d700a61003dbc7d8d29305c5d94d2362873`.
   The X11 network PNG SHA-256 was
   `9163976a9716366dd44a34d88d51eb5a8c7f582f0d1148972eebc6948e93a47f`.
5. Gamescope emitted composite markers through frame 360, then repeatedly
   reported `Android release message wait failed buffer 0` with
   `poll=0 revents=0x0 errno=11`, followed by
   `Android output release fence wait failed for buffer 0`. The app-side
   diagnostic markers reached frame 390 before the transition and produced no
   later frame marker after the network event. The app process and the
   `Nova double-buffer Linux image loop` SurfaceFlinger layer were still
   present, so this is not an Activity death or an absent layer.

## Boundary and next gate

The evidence rules out Android key delivery, the CEF/X11 route, and an
incorrect aspect-ratio or output-size setting for this failure. It localizes
the next investigation to the Gamescope AHB release-message/fence protocol or
the Android SurfaceControl buffer-latch/release path. The one-second ACK waits
observed around earlier frames are worth preserving as timing evidence, but
they are not by themselves proof of the cause.

Before changing ownership or the three-buffer algorithm, add a per-buffer
sequence trace on both sides that records: submitted frame, AHB index, ACK
receipt, SurfaceControl previous-release FD, release-message send, and
Gamescope release-message receive. Each record must include the fresh run ID.
The next run should also batch root-side diagnostics and verify/dismiss the
settings overlay before every controlled input event.

The diagnostic checkpoint now implements that gate without changing buffer
ownership: set `NOVA_AHB_TRACE=1` on a fresh run. The launcher records the flag
in run metadata, configures `debug.nova.ahb_trace`, and emits per-frame phase
records from both sides of the bridge. Gamescope records release wait,
release-message receipt, fence completion, composition, and ACK send phases;
the Android app records ACK wait/receipt, SurfaceControl present, and release
send phases. Manual sessions also run an exact-scope focus guard that dismisses
the settings USB chooser if it reappears.
