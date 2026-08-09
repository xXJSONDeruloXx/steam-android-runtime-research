# Nova AHB downstream surface-marker result (2026-08-09)

Status: accepted as a downstream SurfaceControl-visible-frame correlation
result. The marker gate passes for the final Android screenshot, but this run
does not accept controller navigation or Steam login.

## Run identity and provenance

- Repository branch/commit at launch: `feat/nova-steam-end-to-end` at
  `f894d5b` (`feat: add Nova surface frame marker`).
- Device: Retroid Pocket Nova, Android 13, ADB serial `675a2365`.
- Run ID/profile: `controller-ui-20260809T-surface-marker` /
  `controller-ui-surface-marker`.
- Run start: `2026-08-09T07:58:10Z`.
- Presentation: native Steam/Xwayland, fullscreen 1280x960, software CEF/GL,
  Android key-event controller bridge.
- AHB target: 240 frames; identity and surface marker enabled; AHB, socket,
  and scheduler traces enabled; ACK poll-timeout override disabled (`0`).

The exact run artifacts are retained under
`android/nova-lab/build/manual-runs/controller-ui-20260809T-surface-marker/`.

```text
gamescope_binary=/tmp/nova-gamescope-frame-identity-final.AOqe48/out-libei/src/gamescope
gamescope_binary_sha256=5d1425b50cbef93ee6084c95a6bd2360f3c97b5686f8d2b2cf17fefcac3b7d1b
gamescope_source_tree=/tmp/nova-gamescope-frame-identity-final.AOqe48/source
gamescope_source_commit=fb9f84ee247a1f02b1a132da60e94585db84bf61
gamescope_source_status_sha256=d8554a591ad45ff80921c48b581bb32857b4e365c978e1b963002ab242c306d3
gamescope_source_diff_sha256=db9e17962a7036dac51c47a1a14551f0e0e5b4e3cf01c210134d7ad54dceec3a
gamescope_source_submodules_sha256=ffb0e5c788894ee2a5498ccffe0fcabd659805200bc9bed025ce78e02cc0f8b0
nova_apk_sha256=b3befb6a2dbbe70431054c354ea7f25d5d2e69ae2873b76451c7cabdf07f3d5f
```

## Result

The underlying native Steam/AHB run passed:

```text
native_steam_smoke=pass
headless_gamescope_ahb=pass
controller_ui_android_input_bridge=pass
ahb_double_buffer_frames=240 releases=239
```

Every frame passed both diagnostic paths:

```text
frame_identity_pass=240 fail=0
frame_marker_pass=240 fail=0
checksum_status_nonzero=0
marker_status_nonzero=0
```

The final screenshot decoder reported:

```text
nova_frame_marker_decode=pass
nova_frame_marker_png_size=1280x960
nova_frame_marker_origin=16,96
nova_frame_marker_cell=8
nova_frame_marker_frame=239
nova_frame_marker_checksum_low16=e5f5
ahb_frame_marker_capture=pass frame=239 checksum_low16=e5f5
```

The matching app record is:

```text
ahb_double_buffer_frame_identity_239=pass producer_frame=239 ... checksum_fnv1a64=229674f10005e5f5 checksum_status=0
ahb_double_buffer_frame_marker_239=pass producer_frame=239 checksum_low16=e5f5 marker_status=0 checksum_status=0
```

The explicit post-stop verifier passed, including reset of the new property:

```text
post_stop_frame_identity_state=pass
post_stop_frame_marker_state=pass
post_stop_residual_processes=pass
post_stop_app_files=pass
post_stop_verification=pass
```

Run artifact hashes:

```text
preflight=781ca2d0978f82771219fc2dd6b2bebd1d734fe116ba2cbc0f006f4ebf9d4d7f
logcat=ee25c60b9cf1dc6dd7cd369b10d327289009b37e8bb80783091fb1bfd173bd94
metadata=5e8cf0a1bdbdad9f7f32972f9eaae70c9281c43e356d41e80b3b41efd0eefc2b
gamescope_report=457111638994631823524161f99d54f13bd301808374ce6aa6901e7b22c2114b
app_report=454bd650afea819ae7491613c58e16613c7541a4fbb2b28117945351ebf6d745
screenshot=18f0a74f77bb0714d15dc9ce66d4df5b38c32f3787c43ba7d721812dd64f46a1
marker_decode=8d36edebb28bb8819cf04380b0c90286ba970cee9a784e1fbfb2df3f1454bdd2
android_input_report=ae221b8e144afdd0d4ca6ce15259d17bd52621b7d7bd5b924da2d197a08d124e
post_stop_verification=e2347d1d5b227c0443420405f203dc26bef45cdadc92ecece05218b5fdbb87fb
```

## Interpretation

The marker is written into the received AHardwareBuffer after the raw
pre-marker checksum is calculated and before the buffer is submitted to
SurfaceControl. The same marker is visible in the retained Android screenshot,
and its frame/checksum suffix matches the app's exact identity record. This
establishes that the identified received buffer reached the user-visible
SurfaceControl screenshot in this run.

The marker is intentionally visible and diagnostic-only; the upper-left
black/white cells in the screenshot are not part of the end-user presentation.
The result does not prove that every downstream pixel is byte-identical to the
AHardwareBuffer, and it does not prove login or input acceptance.

The controller event traversed Android and the rooted virtual Xbox device, but
the controller UI panel hash did not change (`controller_ui_navigation=none`),
so the wrapper correctly rejected the run's navigation gate. The screenshot
still shows Steam's language/OOBE page rather than the login form. The next
experiment should keep this correlation mode available while separately
driving and observing the OOBE transition, then disable the marker for the
end-user presentation result.
