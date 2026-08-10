# Nova one-click stop caller guard result — 2026-08-10

## Result

The exact stop-caller guard closes the direct one-click launcher lifecycle
regression. A fresh signed-in Steam session reached the full Android surface,
and the exact product stop command returned zero with all required completion
markers. The final process and rootfs-residue scans were empty, and the
Termux:X11 preference file was restored to its pre-run bytes.

This is a pass for the direct Termux:X11 fallback's launch/stop contract. It
does not make the fallback a final Gamescope product: it still depends on the
external Termux:X11 APK, uses software Steam/CEF rendering, and does not yet
prove game rendering, hardware Steam/CEF, audio, or physical-controller
delivery.

## Run identity and provenance

- Run ID: `nova-one-click-stop-caller-guard-20260810T112317Z`
- Device: Retroid Pocket Nova, adb serial `675a2365`
- Android: 13, product `kalama`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- Source commit at launch: `71d31f9d2957b9c25d433862af62d0668b7ac74e`
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256:
  `05728ddc9b1a85f20524172c5f3adf2e64815013dbc945042be396d75f2d7853`
- Evidence:
  `android/nova-lab/build/runs/nova-one-click-stop-caller-guard-20260810T112317Z/`

The fixed profile was direct Termux:X11 on display `:0`, with an X11 buffer
of `1280x800` stretched to the Nova Android surface at `1280x960`. The extra
key bar was hidden. Steam used the signed-in software/CEF profile with
`hardware_accel=0` and `cef_disable_gpu=1`; Gamescope/AHardwareBuffer was not
used.

## Presentation checkpoint

The first readiness attempt passed:

```text
ready=1 attempt=1
nova_launcher_ready=pass display=:0 geometry=1280x960
nova_launcher_x11_hide_extra_keybar=1
nova_launcher_gamepad=pass input_allow=event9
```

The settled Android capture visibly showed the signed-in Steam Store/Friends
desktop filling the `1280x960` surface without the bottom extra-key bar.
`android-screen-settled.png` has SHA-256:

```text
9265eb59139f08ef4139842ed40921a9ed02271a4b65e7e35283b01a6826a8d1
```

## Stop and restore evidence

The exact product stop command produced:

```text
nova_launcher_x11_stretch_restore=pass
nova_launcher_cleanup_exclude_pids=32114 32113 1032
nova_launcher_stop=pass
```

It returned `adb_exit_status=0`. The final process audit contained no matching
Gamescope, Steam/webhelper, Xwayland, libei, uinput relay, root launcher, or
Nova runtime process. The exact rootfs residual scan was empty.

The reversible Termux:X11 preference transaction also restored its known
baseline:

```text
during 2985d0d52b35d40d9f00dfbd6c69ca994dba3c99ef1b2c71b55fb5cf19d6ec5c
after  25530aa4ed8fda450e43638e2c7a00bb95d5cb1ff1c1ab18e717f32a4feb0895
```

The stop-caller guard was the one changed variable after the negative
[ancestor-exclusion result](288-nova-one-click-stop-ancestor-exclusion-result-2026-08-10.md).
It ignores only the literal `nova-one-click-root-launcher.sh stop` command in
the cleanup matcher; the independent start wrapper and its descendants remain
eligible for termination.

## Decision and next step

The direct fallback is now safe enough to retain as the product recovery path.
Do not spend another experiment on its stop ancestry. The next rendering
experiment should use a materially different client path: either a
WineD3D/OpenGL session that isolates Mesa GLX/Zink from the existing Steam
software profile, or an Android-aware Vulkan WSI layer/renderer seam modeled on
the prior art documented in [doc 117](117-x11-android-forwarding-experiment-plan-2026-08-09.md).
The existing FROG/DXVK result remains scoped to the missing-swapchain route,
not to all possible Proton game paths.
