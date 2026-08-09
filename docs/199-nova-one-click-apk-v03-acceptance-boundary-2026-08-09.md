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
| preflight-guard fix, pending device retest | working tree after this record | `a5f4a5512fc89da9380eb275a81d1f408ed11796f0655be83f1f512b3f56b2a0` | 0.3 |

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

Install the preflight-guard build as a new run identity and confirm, in order:

1. the APK launcher renders;
2. the root-side preflight passes without a stale-process match;
3. the relay reaches `uinput_device_ready=pass`;
4. Termux:X11 and native ARM64 Steam start through the APK;
5. Steam's visible frame is 1280x960 and input/focus evidence is fresh; and
6. the APK stop path and exact cleanup pass.

Only after that direct product path is repeatable should the APK gain the
separate Gamescope/AHardwareBuffer product mode.
