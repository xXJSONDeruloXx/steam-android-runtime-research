# Nova Vulkan AHardwareBuffer readback result — 2026-08-09

Status: invalid diagnostic run; the readback hook was not enabled in the
selected native-Steam control-script path. The propagation fix is committed in
`65a2786` and pushed before the rerun.

## Decision

Do not use this run to compare Vulkan and CPU AHardwareBuffer pixels. The
fresh 240-frame Android producer loop and raw snapshot passed, but the
Gamescope report contains neither a Vulkan readback `pass` nor `fail` line.
The rootfs received `NOVA_AHB_VULKAN_READBACK=1` and frame `239`; the selected
native Steam wrapper then replaced the generic AHB control script with
`gamescope-headless-steam-xwayland-control.sh`, whose missing environment-file
propagation left the Gamescope hook disabled.

This was a harness wiring failure, not evidence about Vulkan image contents.
The Android screenshot and raw PNG still show the established green-line
diagnostic pattern, while settled X11 capture completed independently. No
Android key event was sent because the strict Android Steam-surface gate was
missing.

## Gate summary

```text
controller_ui_ready=1
controller_ui_surface=missing
native_steam_smoke=pass
ahb_double_buffer_raw_capture_239=pass
ahb_raw_capture=pass frame=239 bytes=4915200
nova_ahb_raw_decode=pass
ahb_double_buffer_frames=240 releases=239
android_ahb_vulkan_readback_239=missing
android_input_forwarded=none
post_stop_verification=pass
```

The outer controller wrapper returned status 1 because the required readback
report marker was absent. The bounded probe itself returned `probe_status=0`,
and the exact-scope cleanup and explicit post-stop verifier both passed.

## Cause and correction

The run selected the native Steam path:

```text
deploy-native-steam-smoke-test.sh
  -> NOVA_GAMESCOPE_AHB_CONTROL=...
     device/gamescope-headless-steam-xwayland-control.sh
```

The prior readback commit updated
`device/gamescope-headless-ahb-control.sh`, but not this native-Steam variant.
The fresh rootfs report recorded:

```text
rootfs.ahb_vulkan_readback=1
rootfs.ahb_vulkan_readback_frame=239
```

The pushed Gamescope binary contained the readback strings, and the device
report reached frame 239, but the selected control script did not read or
export `/opt/nova-steam/ahb-vulkan-readback` and
`/opt/nova-steam/ahb-vulkan-readback-frame`. Consequently the branch guarded
by `NOVA_AHB_VULKAN_READBACK=1` never ran, so there is no Vulkan checksum to
interpret.

Commit `65a2786` adds the same file reads and exports to the native-Steam
control script. A rerun uses a new run identity after this commit; no prior
process, report, socket, or screenshot may satisfy it.

## Run provenance

```text
run_id=controller-ui-20260809T134528Z-vulkan-readback-1280x960
profile=controller-ui-vulkan-readback-1280x960
run_started_utc=2026-08-09T13:48:25Z
adb_serial=675a2365
device=Retroid Pocket Nova / Android 13
gamescope_binary=/tmp/nova-gamescope-ahb-vulkan-readback-202609-out2/src/gamescope
gamescope_binary_sha256=12a19e022aad45ae3468530a9ea9ed79a2d8f404ce8649457733aa5fc53b5308
gamescope_libei_build=enabled
gamescope_input_emulation=enabled
nova_apk_sha256=255db3949ef690c489f184ee7a2d2d141ab6b4ffd44fa5772ac2ef54f5e637b8
gamescope_source_tree=/tmp/nova-gamescope-ahb-vulkan-readback-source2-20260809
gamescope_source_commit=fb9f84ee247a1f02b1a132da60e94585db84bf61
gamescope_source_dirty=1
gamescope_source_status_sha256=d8554a591ad45ff80921c48b581bb32857b4e365c978e1b963002ab242c306d3
gamescope_source_diff_sha256=a42cbbdbfcf24bbd08a7bfe8689ebbc8306f3b384c0b3fe7f252d2ce88a46af9
gamescope_source_submodules_sha256=ffb0e5c788894ee2a5498ccffe0fcabd659805200bc9bed025ce78e02cc0f8b0
fullscreen_presentation=1
fullscreen=1280x960
ahb_buffer=1280x960
ahb_usage=0x333
ahb_frames=240
NOVA_AHB_OUTPUT_TILING=optimal
NOVA_AHB_VULKAN_READBACK=1
NOVA_AHB_VULKAN_READBACK_FRAME=239
NOVA_AHB_RAW_CAPTURE=1
NOVA_AHB_RAW_CAPTURE_FRAME=239
NOVA_AHB_FRAME_IDENTITY=1
NOVA_AHB_FRAME_MARKER=1
NOVA_AHB_CONTENT_PROBE=1
NOVA_AHB_TRACE=1
NOVA_AHB_SOCKET_TRACE=1
NOVA_AHB_SCHEDULER_TRACE=1
NOVA_AHB_ACK_POLL_TIMEOUT_MS=0
NOVA_CONTROLLER_UI_INPUT_MODE=android-keyevent
NOVA_CONTROLLER_UI_X11_CAPTURE_AFTER_SETTLE=1
NOVA_CONTROLLER_UI_REQUIRE_STEAM_SURFACE=1
```

The retained run directory is:

```text
/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/manual-runs/controller-ui-20260809T134528Z-vulkan-readback-1280x960/
```

## Raw and presentation evidence

The APK's selected raw frame was a valid logical RGBA8 snapshot:

```text
ahb_double_buffer_frame_content_239=pass producer_frame=239 desc=1280x960 stride=1280 layers=1 format=0x00000001 usage=0x333 pixels=1228800 raw_fnv1a64=331219c317e02083 rgba_min=0,0,0,0 rgba_max=255,255,255,255 rgba_avg_milli=510,1953,727,1024 luma_min=0 luma_max=255 luma_avg_milli=1379
ahb_double_buffer_raw_capture_239=pass producer_frame=239 desc=1280x960 stride=1280 layers=1 format=0x00000001 usage=0x333 bytes=4915200 pre_marker=1 raw_fnv1a64=331219c317e02083
```

The host decoder passed at 1280×960 and 4,915,200 bytes. Visual inspection of
both the raw PNG and Android screenshot shows the dark green vertical-line
pattern with the small white diagnostic pattern at upper left, not Steam. The
settled X11 capture completed with `window_id=0x240003b`; it remains
observational evidence only for this invalid diagnostic.

Retained artifact hashes:

```text
device-gamescope-headless-ahb-report.txt  sha256=805cbf672f9ae0a8e16362acfc05488ac3d63b0066a155705ec977149e181d79
device-gamescope-headless-ahb-logcat.txt  sha256=05537336ca7b70843b0078498f2ba033ee75d678d8b3ca3d4b1f463271cd7b96
device-gamescope-headless-ahb-app-report.txt sha256=f400ee89b20b9b17e1d9be04e8541ccceb7e2c715fdc84aa988b5abaf9e05847
device-gamescope-headless-ahb-screenshot.png sha256=20d79f27a5be9e5ac0015b28f3bd55452c11aa2e9b955d64243d1ebdb5bddff5
nova-ahb-raw-frame.rgba                  sha256=85108fef4a41eac057c6a60f74380e27fe5070f8b9a0a81153032640c4c220bf
nova-ahb-raw-frame.png                   sha256=8bbac1dcaa74eb3e2f59921a140fdb4b4fadb905b725ce76e5e347e5ed83d952
nova-ahb-raw-frame-decode.txt            sha256=e401de72bcd7fd86748352f5a952c88256373ab753f80c977caf3a8cf1fd61e8
x11-steam-settled.ppm                   sha256=04c4ecfc2308053f14b72265a66dc96328961b006a424228f27d1e55d64f3ed1
x11-capture-settled-status.txt           sha256=3af46211bb488e45e991cf1da0df9cc74ac8f451ffc97cb22df46cb2aff60f77
device-surfaceflinger.txt                sha256=993afca2bdafbc8c7bffe138ffe054d0582a5a278cd27f7a800772622c6a18ec
device-gamescope-headless-ahb-metadata.txt sha256=b061b3f35b363adeac42c96c21779a8b5154646f4572467af950235436bd2dd0
device-gamescope-headless-ahb-preflight.txt sha256=b6ba1d7076917781d190a2455285296196520dd13ad8ac7e7a1a10fcbf3fbc54
post-stop-verification-explicit.txt      sha256=4d84baf7df3ce13f09668a6ec500dfabc706c409f1e3b40ce7a566723a23193c
```

The pulled device setup report was retained at
`android/nova-lab/build/holo-glibc-report.txt` with SHA-256
`98e68d9ef3656144ffd64fd3615ed432ef1bbeadffe1a369ccbce9aacd3d3ae7`.

## Next step

Rerun the same 1280×960 optimal-tiling/readback/raw-capture contract with a
fresh identity after `65a2786`. Accept the next diagnostic only when the
Gamescope report contains `android_ahb_vulkan_readback_239=pass` and the
Vulkan FNV-1a value can be compared directly with the APK's
`331219c317e02083`-style raw-capture value. Do not advance to Android input,
login, touch, audio, networking, hardware GL, or standalone launch based on
this invalid run.
