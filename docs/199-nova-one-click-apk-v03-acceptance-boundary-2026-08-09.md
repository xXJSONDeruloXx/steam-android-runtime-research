# Nova one-click APK v0.3 acceptance boundary

Date: 2026-08-09  
Device: Retroid Pocket Nova, Android 13, `kalama`, adb serial `675a2365`  
Branch: `feat/nova-one-click-launcher`

## Scope

This record covers the first device acceptance attempts for the standalone
`com.xjsonderulo.steamandroid.novalab` launcher APK. The APK's current product
path is direct Termux:X11; it does not yet package or select the Gamescope /
AHardwareBuffer path. The 198X game-launch result is recorded separately in
[198](198-termux-x11-198x-game-launch-result-2026-08-09.md).

The exact Nova lifecycle contract in [34](34-nova-runtime-harness-lifecycle.md)
was read immediately before the retry run. Each attempt used a fresh local run
directory and the exact runtime cleanup helper on exit.

## Artifact identity

The APK was built by `android/nova-lab/build.sh`, signed with the local debug
keystore, and verified by `apksigner`.

| Attempt | Source state | APK SHA-256 | Version |
| --- | --- | --- | --- |
| initial launch | `8fb5c20` | `1f64fc080989652422de52e7f159432113399564442eaffad22a5af6e8f1c155` | 0.3 |
| window-order retry | `d641095` | `c0b57de4ee3fbe75ed4a90a0dc4f289d36a45f2f502985d2b26baddd436da21c` | 0.3 |
| preflight-guard fix, pending device retest | `0d137c6` | `a5f4a5512fc89da9380eb275a81d1f408ed11796f0655be83f1f512b3f56b2a0` | 0.3 |
| relay-corrected build | `00ed01c` | `d9288c9f7843c215441c074d51491e473b7b53453a1e4454adb4a576db766306` | 0.3 |
| timeout/cleanup fix, pending device retest | working tree after `00ed01c` | `9124807429ff6d21a3c7556865cf6a33b0c8999ac8673cc4b5629b46839b3ec1` | 0.3 |

The runtime inputs for both attempts were the direct launcher mode: Termux:X11
APK `/data/app/~~EaHbYh5LSrJyPyjYrj44Wg==/com.termux.x11-Yy3Sfe-6FUYa5hx2OcDldw==/base.apk`,
rootfs `/data/local/tmp/nova-holo-rootfs`, display `:0`, Steam flags
`-fullscreen -fulldesktopres`, and the ARM64 uinput relay when available.

## Results

### `launcher-20260809T195502Z-apk-v03-direct-input-geometry`

Installation succeeded, but starting `LauncherActivity` failed before the
launcher view was created. Android logged:

```text
FATAL EXCEPTION: main
Unable to start activity ... LauncherActivity:
NullPointerException ... DecorView.getWindowInsetsController()
at LauncherActivity.enterImmersiveMode(LauncherActivity.java:267)
```

The cause was calling `enterImmersiveMode()` before `setContentView()`. No
rooted Steam process was started. The fix moved the call after
`setContentView()` and was committed and pushed as `d641095`.

### `launcher-20260809T195802Z-apk-v03-window-order-retry`

The corrected APK rendered the launcher screen on the Nova. The visible frame
was 1280x960 and showed the expected `Start Steam`, `Stop Nova session`, and
`Open diagnostics lab` controls. The screenshot hash is
`4c2fc38bec52f06bf64adcfbeca2be5f25f3925ac37d377c1c38cb4670de2cdb`.

The device UIAutomator dump returned `null root node` even while the screenshot
showed the activity, so the button was activated at the captured `Start Steam`
location `(640,412)` and the window focus was recorded separately.

The root-side launcher then rejected the start with:

```text
nova_launcher_start=fail reason=existing_nova_runtime
```

The post-failure process table contained no matching Nova rootfs, Steam,
Gamescope, Termux:X11, or relay process. The failure was a launcher
preflight false positive: its `runtime_present()` pipeline searched the
process table for literal Nova paths while its own `awk` command line also
contained those literals. A minimal reproduction captured the `awk` process
itself as a match. The preflight now excludes `awk`, matching the existing
cleanup helper's self-match protection.

The corrected preflight build is `a5f4a5512fc89da9380eb275a81d1f408ed11796f0655be83f1f512b3f56b2a0`.
It has not yet been installed and run on the device at the time of this
record, so standalone APK-to-Steam acceptance remains pending.

### `launcher-20260809T200145Z-apk-v03-preflight-guard`

The preflight-guard build (`a5f4a5512fc89da9380eb275a81d1f408ed11796f0655be83f1f512b3f56b2a0`)
was installed successfully. The APK rendered, the root launcher passed its
preflight, and the fresh state reached:

```text
nova_launcher_ready=pass display=:0 geometry=1280x960
```

The APK therefore launched native ARM64 Steam and `steamwebhelper` from the
rootfs. The Android capture reached the signed-in Steam home screen; its SHA is
`5f4ac46dfbcc2261ee232ea28f521dc3c6771caf5dad14bb72b6b10e8cfe877b`.
The X11 tree and window capture were both fresh and stable: the root was
1280x960, while `Steam Big Picture Mode` was explicitly created as
1280x800. The baseline and settled X11 PPM hashes were
`3b1d600afb64cbe3eb5c886559a7270763250a68c5e3c1453a1b72f6457da174` and
`c02a9eb80c69975825f1d54a6d608e9fad82ef0f1036ff48551fd7592f26db8d`.
This confirms the remaining black bottom band is a Steam/X11 window-size
decision, not an Android SurfaceView crop; `-fullscreen -fulldesktopres` did
not make the Big Picture window 4:3.

The physical input relay did not reach readiness:

```text
nova_launcher_gamepad=not_ready
env: '/data/local/tmp/nova-holo-rootfs/opt/nova-kgsl-driver/nova-uinput-gamepad-relay': No such file or directory
```

The binary was present in the staged rootfs. The failure is in
`nova-uinput-gamepad-relay-launcher.sh`: it passed a host-root absolute helper
path into `chroot`, which caused the chroot to look for the path a second time
under the root. The wrapper now strips the root prefix before `chroot`.

This does not mean controller support was absent in this run. Steam's fresh
`controller.txt` detected the Android Xbox device as an Xbox 360 Controller and
loaded the complete SDL mapping, including `a`, `b`, `x`, `y`, `leftshoulder`,
`rightshoulder`, and the D-pad. `dumpsys input` named Termux:X11 as the focused
window. The relay correction still needs a fresh device run before physical
button forwarding is accepted as a product gate.

Steam's client stdout still records Vulkan enumeration failure, but the same
run reached the signed-in UI through the deliberate software CEF path. This is
not evidence of hardware-accelerated Steam UI or game rendering.

The product stop command removed the runtime, but returned failure because the
Termux:X11 cleanup sub-gate failed; the subsequent exact runtime helper
returned `pass` and the residual process audit was empty. The next run will
retain the cleanup log before removing state so that sub-gate can be repaired
or explained rather than hidden.

### `launcher-20260809T200616Z-apk-v03-relay-fixed`

The relay-wrapper correction was installed as APK `d9288c9f7843c215441c074d51491e473b7b53453a1e4454adb4a576db766306`.
The wrapper now found and executed the binary inside the chroot; its result
changed from `No such file or directory` to the binary's own validation:

```text
uinput_error=invalid_timeout
```

That separated the path bug from the timeout contract. The launcher requests
86400000 ms for a long-lived session, while the relay binary had a 3600000 ms
maximum. The relay source now accepts the requested 24-hour bound and the APK
has been rebuilt as `9124807429ff6d21a3c7556865cf6a33b0c8999ac8673cc4b5629b46839b3ec1`.

This run also retained the Termux:X11 stop log. Its final client residual was
the cleanup verifier's own `awk` command, because `client_pids()` passed the
client token as an `awk -v` argument and did not exclude `awk`. The exact Nova
runtime cleanup still returned `pass` and the final matching process set was
empty. The cleanup verifier now excludes its own `awk` process; that change is
included in the pending APK above.

## Cleanup

Both attempts ended without a Nova Steam runtime. The retry's teardown still
ran the exact helper and returned:

```text
nova_runtime_cleanup=pass root=/data/local/tmp/nova-holo-rootfs attempts=1 term_pids= kill_pids= remaining=
```

The APK and Termux:X11 were force-stopped, `/data/local/tmp/nova-android-launcher`
was removed as app-owned state, and the post-cleanup process audit found no
matching runtime. No broad process kill was used.

## Next gate

Install the timeout/cleanup-corrected build as a new run identity and confirm,
in order:

1. the APK launcher renders;
2. the root-side preflight passes without a stale-process match;
3. the relay reaches `uinput_device_ready=pass`;
4. Termux:X11 and native ARM64 Steam start through the APK;
5. Steam's visible frame is 1280x960 and input/focus evidence is fresh; and
6. the APK stop path and exact cleanup pass.

Only after that direct product path is repeatable should the APK gain the
separate Gamescope/AHardwareBuffer product mode.
