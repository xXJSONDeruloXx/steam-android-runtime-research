# Nova Gamescope/AHardwareBuffer product-promotion baseline result — 2026-08-10

Status: lower-level presentation passed; run rejected at the libei artifact gate.

This is the result for the predeclared [run 223](223-nova-gamescope-ahb-product-promotion-baseline-2026-08-10.md).
It is not an end-to-end product acceptance result.

## Run identity and provenance

- Device: Retroid Pocket Nova, `kalama`, ADB serial `675a2365`.
- Run ID: `gamescope-product-baseline-20260810T063853Z`.
- Source tree: `/Users/kurt/Developer/gamescope-valve`, commit
  `fb9f84ee247a1f02b1a132da60e94585db84bf61`.
- Intended host Gamescope artifact:
  `android/nova-lab/build/gamescope-headless-build/src/gamescope`, SHA-256
  `640ff8df14a129e7e4416cb8f5abc3222718765216b88acfbec550f9a98a660c`.
- APK installed by the harness: `android/nova-lab/build/nova-lab-debug.apk`,
  SHA-256 `34ca3c9e65e01dd6c94e17b180c079ff94aa29477a895d7fa27728c2363cfcb7`.
- Device Gamescope artifact: `/data/local/tmp/nova-holo-rootfs/opt/nova-kgsl-driver/gamescope-headless`,
  SHA-256 `640ff8df14a129e7e4416cb8f5abc3222718765216b88acfbec550f9a98a660c`.
- Device control script:
  `/data/local/tmp/nova-holo-rootfs/opt/nova-kgsl-driver/gamescope-headless-ahb-control.sh`,
  SHA-256 `64d72fb69e63df43f02a99206215c980f2d16e70ec72234c00d0128054cbe63e`.
- Presentation: `1280x960`, three AHardwareBuffers, linear output tiling,
  `force_gpu_composition=true`.
- Steam client: native ARM64 Gamepad UI with software GL inside the client.

The source tree already contained the checked-in AHB and libei-touch source changes,
but the existing local Gamescope build directory had been configured with
`-Dinput_emulation=disabled`. The manual-session wrapper reused the already-staged
device binary and did not redeploy it.

## What passed

The fresh run reached the current Gamescope/AHB presentation path:

```text
mount./data/local/tmp/nova-holo-rootfs/run/nova-lab-app=pass
vulkaninfo_status=0
GPU0: Turnip Adreno (TM) 740
Android AHardwareBuffer output imported: 3 x 1280x960 RGBA
Running compositor on wayland display 'gamescope-0'
android_ahb_composite_frame=60 layers=1 async=0
```

The fresh native Steam process and `steamwebhelper` were both live in the same run,
and SteamUI logs reached the post-login Gamepad UI initialization path. The Android
app log recorded the AHB ACK, acquire-fence, SurfaceControl presentation, and release
fence sequence through frame 90 before the run was stopped.

## First failed layer

The artifact gate failed before touch or libei input could be evaluated:

```text
gamescope_libei_build=disabled
[gamescope] Gamescope built without libei, XTEST will not be available!
eis_touch_bridge=unavailable gamescope_socket=/tmp/gamescope-0-ei app_socket=@/data/user/0/com.xjsonderulo.steamandroid.novalab/files/nova-touch.sock
```

The host build itself reports the same disabled marker. The required next action is
to create a clean Gamescope build directory, configure `-Dinput_emulation=enabled`,
verify the binary marker and SHA-256, deploy that exact binary to the device, and only
then repeat the same run. This is a harness/artifact-selection issue, not evidence
against the AHB presentation path.

## Cleanup

The interrupted manual run completed the exact cleanup gates:

```text
native_steam_runtime_cleanup=pass
controller_ui_app_files_cleanup=pass
native_steam_runtime_cleanup=pass
controller_ui_app_files_cleanup=pass
```

The post-stop process audit contained no matching Gamescope, Steam, webhelper, relay,
or libei helper process. The run artifacts remain under the ignored
`android/nova-lab/build/runs/gamescope-product-baseline-20260810T063853Z/` directory.

## Decision

Do not promote the current test-bench path or change the product APK based on this
run. First repair the build/deploy provenance so that a libei-enabled Gamescope
binary is an explicit input to the next fresh session. The AHB path is worth keeping:
it reached full Nova geometry and live native Steam, while the only newly observed
failure was the stale/disabled Gamescope input feature.
