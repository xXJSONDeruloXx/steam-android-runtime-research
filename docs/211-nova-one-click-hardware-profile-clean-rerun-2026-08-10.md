# Nova one-click hardware profile clean rerun — 2026-08-10

Status: predeclared; no device session has been launched under this run yet.

## Question

The prior mount-master retry loaded `com.termux.x11.CmdEntryPoint`, but a
leftover manual X11 probe owned the socket and invalidated the UI attempt. The
probe is now terminated, the Activity is stopped, and the rootfs/X11 paths have
been checked. This run repeats the same opt-in hardware profile with one
variable changed: a genuinely clean X11 process baseline.

## Run identity

Run ID: `gpu-20260810T043806Z-x11-steam-hardware-clean-rerun`

Profile:

- Retroid Pocket Nova, Android 13, adb serial `675a2365`;
- branch `feat/nova-one-click-launcher`, source commit `f8d4534`;
- rebuilt APK with `su -mm 0` root launch and explicit `hardware_accel` intent;
- rootfs `/data/local/tmp/nova-holo-rootfs`;
- Termux:X11 display `:0`, fullscreen/full-desktop-resolution, target
  `1280x960`;
- `/opt/nova-kgsl-driver/freedreno-kgsl.icd.json` selected through the
  hardware profile;
- no physical or synthetic input and no audio bridge.

## Controlled baseline

Before the Activity launch, use the exact cleanup helpers, force-stop the Nova
and Termux:X11 packages, and prove that no `termux-x11`, `app_process` with
`CmdEntryPoint`, Steam, Gamescope, Wine, FEX, relay, X11 socket, or rootfs
mount from a prior run remains. Do not run a separate manual X11 probe during
this experiment.

The app is started with:

```text
am start -W -n com.xjsonderulo.steamandroid.novalab/.LauncherActivity \
  --ez run_steam_session true --ez hardware_accel true
```

## Acceptance and cleanup

A pass requires the current launcher to record `nova_launcher_ready=pass`,
the client log to show hardware mode and the explicit ICD, fresh Steam and
webhelper startup evidence, and a same-run stable Steam screenshot. A startup,
Steam, or CEF crash is recorded at its first failed layer and is not counted
as a hardware-rendering pass. Only if the Steam UI is stable will the next
run test hardware game rendering.

After capture, run the exact X11 and rootfs cleanup helpers and verify no
matching process, mount, socket, or temporary launcher state remains. Commit
and push the result before any next experiment.
