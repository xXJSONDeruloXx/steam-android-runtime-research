# Nova OOBE A-button surface-correlation result — 2026-08-09

Status: partial acceptance. The Android A-button reached Steam and changed
the visible OOBE from the language selector to the timezone selector, but the
run did not complete its 240-frame AHB/marker gate. A `com.rp.settings` USB
chooser was visible in the final capture; Gamescope then observed `EPIPE` on
the Android peer at frame 84. The overall run is not accepted as a complete
marker-correlated result.

## Run identity and provenance

- Predeclared experiment: [doc 83](83-nova-oobe-a-button-surface-correlation-experiment-2026-08-09.md).
- Device: Retroid Pocket Nova, Android 13, ADB serial `675a2365`.
- Run ID/profile: `controller-ui-20260809T-oobe-a-button` /
  `controller-ui-oobe-a-button`.
- Run start: `2026-08-09T08:22:37Z`.
- Presentation: native Steam/Xwayland, fullscreen 1280x960, software CEF/GL.
- Input: Android `KEYCODE_BUTTON_A` 96 -> Linux `BTN_SOUTH` 304.
- AHB: marker and frame identity enabled; target 240 frames.

The retained artifacts are under:

`android/nova-lab/build/manual-runs/controller-ui-20260809T-oobe-a-button/`

```text
gamescope_binary=/tmp/nova-gamescope-frame-identity-final.AOqe48/out-libei/src/gamescope
gamescope_binary_sha256=5d1425b50cbef93ee6084c95a6bd2360f3c97b5686f8d2b2cf17fefcac3b7d1b
gamescope_source_commit=fb9f84ee247a1f02b1a132da60e94585db84bf61
gamescope_source_status_sha256=d8554a591ad45ff80921c48b581bb32857b4e365c978e1b963002ab242c306d3
gamescope_source_diff_sha256=db9e17962a7036dac51c47a1a14551f0e0e5b4e3cf01c210134d7ad54dceec3a
gamescope_source_submodules_sha256=ffb0e5c788894ee2a5498ccffe0fcabd659805200bc9bed025ce78e02cc0f8b0
nova_apk_sha256=9c8166167926719c5438fe26e89f0cd7f4265c7064081e96dee6beeb77d26656
```

## Accepted A-button evidence

The strict controller gate passed before the downstream run failed:

```text
controller_ui_surface=pass
controller_ui_steam_surface=pass
controller_ui_android_event=KEYCODE_BUTTON_A code=96 maps_to=BTN_SOUTH code=304
controller_ui_screen_changed=pass
controller_ui_navigation=pass
```

The controller screenshots show the visible transition:

- before: Steam `Welcome / Select a language`;
- after: Steam `Choose your timezone`.

The exact panel hashes were:

```text
controller_ui_navigation_panel_before_sha256=1d1db2d8df1c55267732f36fb966748d2da7837085106885994eb3f5e9528d50
controller_ui_navigation_panel_after_sha256=08eda50cd7f08b2a733df78c8b4e26b51d63af385ad048d336489dded5d63f53
```

The transport logs also prove the requested press/release and Steam input-FD
ownership:

```text
android_input_key_received code=96 linux_code=304 event=BTN_SOUTH action=0
android_input_key_received code=96 linux_code=304 event=BTN_SOUTH action=1
android_input_key_forwarded=pass
steam_input_fd_probe=pass
```

This is the first accepted Android A-button Steam OOBE transition. It does not
yet prove a complete long-lived session or login.

## Failed downstream gate

Frames 0 through 83 passed identity, marker, acquire-fence, and release
checks. At frame 84, Gamescope repeatedly reported:

```text
Android output acquire fence handoff failed for buffer 0
android_ahb_socket_trace ... op=ack_send frame=84 ... result=-1 errno=32
```

The app report ended with:

```text
ahb_double_buffer_frame=84 buffer=0 ack_bytes=-1 ack=ahb_double_buffer_ack_84=fail fence_fd=missing
ahb_double_buffer_frames=84 releases=83
ahb_double_buffer=fail
```

The final screenshot decoder returned `magic_0000`, not a valid marker
correlation. The final 1280x960 capture visibly contained the Android
`com.rp.settings` `Use USB for` chooser over Steam's timezone page. This
provides a concrete stale/focus transition boundary, but does not by itself
prove whether the chooser caused the Activity stop or was a consequence of
the same external focus transition. The AHB peer closure and the existing
Activity-stop cancellation path are consistent with that boundary, so the
next experiment must keep the chooser dismissed throughout the bounded run.

The independent teardown verifier still passed:

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

Key artifact hashes:

```text
device-gamescope-headless-ahb-preflight.txt=e4d85fb2c93902a7d5dd86e3ea011fcfb7f96633322ec09f325f249554f0b820
device-gamescope-headless-ahb-metadata.txt=7ed734d16dfb03022bc177179a8c9024e3002af380f485c340b9dd74577122b2
device-gamescope-headless-ahb-report.txt=2db829c6b398b864963db338e9aa5c02bbc457ced3f968026cde9155543efece
device-gamescope-headless-ahb-app-report.txt=812bc824bb97706f8641ac9a55c48407c23dd36518712ba775b83d7b1486c7cc
device-gamescope-headless-ahb-screenshot.png=3becd36d620342ca625a6ead6e13e54bd230c79f4326791c333779e77d9eb86f
ahb-frame-marker-screenshot.txt=351200165c37c2e102c0a8c8859bc3ddb629d0d4e94444217cfda9f5e5b1d047
android-input-bridge-report.txt=97a7f59a10abf14c16ade52c620fed29be919b6882751aa3b8e31ebf2efaa510
post-stop-verification-explicit.txt=51baf9c0bae45bad3669cd0a317f360a50a39a3cced79e176adf4249eaba05e2
```

## Next one-variable change

The bounded controller harness currently dismisses the settings overlay before
the controlled event and after the delay, but does not guard against its
reappearance while the AHB probe continues. Add the same exact-focus guard
used by manual sessions to bounded controller runs, then repeat this exact
experiment. Do not change the AHB transport, marker, input mapping, or Steam
flags until the overlay/Activity-stop boundary is eliminated.
