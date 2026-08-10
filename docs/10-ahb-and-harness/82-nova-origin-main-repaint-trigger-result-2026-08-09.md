# Nova origin/main repaint-trigger verification — 2026-08-09

Status: negative end-to-end result. The exact `origin/main` repaint-trigger
artifact completes the 240-frame AHardwareBuffer ring, but the fresh Android
fullscreen capture is a uniform dark-gray frame. The trigger is therefore not
accepted for the Steam presentation path.

## Scope and run identity

This run directly tested the pulled `origin/main` tip at `335c600` (`fix: keep
Nova AHB output repainting`) in an isolated temporary repository worktree. The
Gamescope patch contains the nine-line vblank `hasRepaint` trigger from that
commit. The current branch's guarded harness and test-bench APK were used
without changing the working branch or popping the stash.

- Device: Retroid Pocket Nova, Android 13, ADB serial `675a2365`.
- Run ID/profile: `controller-ui-20260809T-latest-main-335c600` /
  `unclassified`.
- Run start: `2026-08-09T08:10:52Z`.
- Presentation: native Steam/Xwayland, fullscreen 1280x960, software CEF/GL.
- AHB: 240 frames, blocking ACK/release path, AHB and socket traces enabled.
- Input: Android `KEYCODE_DPAD_DOWN` 20 -> Linux `BTN_DPAD_DOWN` 545, key-only
  bridge requested; the event was not sent because the visual gate never
  became ready.

The retained artifacts are under:

`android/nova-lab/build/manual-runs/controller-ui-20260809T-latest-main-335c600/`

## Artifact provenance

```text
repo_test_harness_commit=18ac4c7a02cf7897ecf975b016437dbc067cf600
gamescope_binary=/tmp/nova-gamescope-origin-main-20260809.Rqd8ZP/build/gamescope-headless-build/src/gamescope
gamescope_binary_sha256=dc07e57bc6bb26829306a79c5f066da5be708b1ddc32130adce6379d34c761bd
gamescope_source_tree=/tmp/nova-gamescope-origin-main-20260809.Rqd8ZP/build/gamescope-headless-source
gamescope_source_commit=fb9f84ee247a1f02b1a132da60e94585db84bf61
gamescope_source_status_sha256=d8554a591ad45ff80921c48b581bb32857b4e365c978e1b963002ab242c306d3
gamescope_source_diff_sha256=26f7a1e0d02859a440b0e6dccc42bf4e9c3b3c665ceb94cb1b859437e6273d72
gamescope_source_submodules_sha256=ffb0e5c788894ee2a5498ccffe0fcabd659805200bc9bed025ce78e02cc0f8b0
nova_apk=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/nova-lab-debug.apk
nova_apk_sha256=0bb277bf1c591bac68ce256cf74480f5443486f6a988a5d75d2540225674a8b4
gamescope_libei_build=disabled
fullscreen_presentation=1
nova_ahb_trace=1
nova_ahb_socket_trace=1
nova_ahb_scheduler_trace=0
nova_ahb_frame_identity=0
nova_ahb_frame_marker=0
nova_ahb_ack_poll_timeout_ms=0
```

The source tree is intentionally dirty because the repository patch stack was
applied to the clean Gamescope source. The status, diff, and submodule hashes
above are the recorded identity of that exact build.

## Result

Fresh preflight and launch passed. The AHB report reached the requested target:

```text
android_ahb_composite_frame=240
android_ahb_target_reached=240
offscreen_probe_status=0
probe_status=0
ahb_double_buffer_frames=240 releases=239
ahb_double_buffer=pass
headless_gamescope_ahb=pass
```

The final Android screenshot was captured at 1280x960 but contained only the
dark-gray background; the Steam surface gate reported
`controller_ui_surface=missing`. The native client log reached
`client_started=pass`, but the wrapper did not observe `client_installed=pass`.
The Steam process did hold the expected virtual Xbox event FD
(`steam_input_fd_probe=pass`), but no controller event was forwarded because
the controller harness correctly refused to inject input into a missing
presentation surface. This run therefore proves neither navigation nor login.

The independent post-stop verifier passed:

```text
post_stop_residual_processes=pass
post_stop_app_files=pass
post_stop_trace_state=pass
post_stop_scheduler_trace_state=pass
post_stop_frame_identity_state=pass
post_stop_frame_marker_state=pass
post_stop_ack_poll_timeout_state=pass
post_stop_verification=pass
```

Key retained artifact hashes:

```text
device-gamescope-headless-ahb-preflight.txt=29687f5170921ccdbfb5d3681056b56969359bfa0b4a5d2e25771ed3015ecb84
device-gamescope-headless-ahb-metadata.txt=31a5e2a456b2a9a558a721e36a6f110978be8df758f8f2e5799aa73cf06ae90a
device-gamescope-headless-ahb-report.txt=4fe76c8b8860a734a2e4339a5e7c1c72083b1207e8c97a6a48f0b6a794a50d66
device-gamescope-headless-ahb-app-report.txt=9fde77dd17e2d4de1daadc8ee0d2ef89370defae6abb86287e6c2c02fffc9a22
device-gamescope-headless-ahb-logcat.txt=8a44c551c34ef1a1ae08a0acee676dd93c9ff3be7bdb14106d5e04818e8bebfc
device-gamescope-headless-ahb-screenshot.png=5f59504e38b600b446955d3fff7a03152522ac997a40c82ecd9215a9af0afa88
native-steam-controller-ui-input-smoke.log=5286c239f039de0b208479175f3aa05324e05f84493a56309a7e07b3b12885ef
nova-controller-ui-uinput-relay.log=62adba2c12b32a32383ed0421e446ecd84cadea9aba34d219a3f56e3df175fbc
nova-controller-ui-steam-input-fd.log=ac3bc7474a6dbfe7331d383611d14daaac863c3b7159fdd69c567d549073fc84
nova-steam-client.log=a8c51f6539917ff46ecce2884b5bed32a19b878552fa2ea620055552c4fb8a5e
post-stop-verification-explicit.txt=094cc75f9080f7bfed073f41af4d3ea05bcf3e64cc1f0d2f718c84d1791d70f0
```

## Interpretation and next step

The trigger does keep the AHB ring moving, but it does not produce a usable
Steam image. Since the current no-trigger artifact has already passed the same
240-frame ring and a downstream frame-marker correlation with a visible Steam
OOBE surface, this result rejects the global repaint trigger as the fix. It
also means the remaining login/input work should stay on the no-trigger
artifact and focus on deterministic OOBE interaction and state observation,
not another ACK/repaint retry.

The next bounded experiment should use the current branch's no-trigger
Gamescope with marker correlation available, send an explicit A-button event
to the selected OOBE language, and capture CDP route/state plus the Android
surface after each step. Once the login surface is visible, disable the marker
and separately accept gamepad navigation, touch, networking, audio, and
hardware-CEF/GL behavior.
