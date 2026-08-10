# Nova one-click hardware profile mount-master retry — 2026-08-10

Status: predeclared; no device session has been launched under this run yet.

## Question

The first hardware-profile attempt used the root launcher directly through
`su 0`. Android created the Termux:X11 surface, but the command-side
`app_process` could not load `com.termux.x11.CmdEntryPoint`. A same-device
probe using the exact APK, `TMPDIR`, and X11 Activity under `su -mm 0` loaded
the class, initialized Adreno EGL, connected XCB, and sent a 1280x960 shared
buffer. This isolates the next controlled change to the app-launched root
process's mount namespace.

The APK launcher service is therefore changed to invoke both start and stop
commands as `su -mm 0 -c`, preserving the mount-master view of `/data/app`,
and to pass an explicit `hardware_accel` intent extra through to the root
launcher. No graphics, Steam, account, game, input, or audio defaults are
changed: the extra is false unless explicitly requested.

## Run identity

Run ID: `gpu-20260810T044000Z-x11-steam-hardware-mount-master`

Profile:

- Retroid Pocket Nova, Android 13, adb serial `675a2365`;
- branch `feat/nova-one-click-launcher`, source commit to be recorded after
  the source build/push;
- current rootfs `/data/local/tmp/nova-holo-rootfs`;
- rebuilt Nova Lab APK, launched through `LauncherActivity` with the existing
  Steam-session intent and the opt-in hardware profile enabled;
- explicit ICD `/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`;
- fullscreen/full-desktop-resolution target `1280x960`;
- no physical or synthetic input and no audio bridge.

## Controlled implementation

The source changes in this retry are limited to the root command invocation
and profile plumbing: `su -c` becomes `su -mm 0 -c` for start and stop, and
the `hardware_accel` intent extra reaches `NOVA_ANDROID_LAUNCHER_HARDWARE_ACCEL`.
The profile still sets the flag to `1`, unsets the software Mesa variables,
selects the explicit ICD, and omits `-cef-disable-gpu`. The known-good
software default remains unchanged.

## Acceptance and cleanup

The retry must establish a fresh APK install/hash and a fresh launcher
identity. A pass requires the current app to reach `nova_launcher_ready=pass`,
start Steam/webhelper under the hardware variables, and produce a same-run
stable Steam UI screenshot without a pre-UI crash. A classpath, X11, or Steam
crash must be recorded at its first failed layer rather than counted as a
hardware-rendering result.

Before launch and after capture, use the exact Nova/X11 and rootfs cleanup
helpers. Verify no matching Steam, Wine, FEX, Gamescope, Termux:X11, relay,
mount, socket, or temporary run state remains. Commit and push this
declaration and the source fix before starting the device session.
