# Nova one-click stop caller guard experiment — 2026-08-10

Status: predeclared; no device session has been launched under this run.

## Question

The previous stop regression left no runtime process or residue, but the
cleanup helper still selected the exact stop command because its rootfs path
made it look like a launch wrapper. The next one-variable repair excludes the
literal command-line token:

```text
nova-one-click-root-launcher.sh stop
```

Can that caller guard allow the stop script to finish while the independent
`...root-launcher.sh start` process and all Nova descendants are still
terminated?

## Fixed profile

- Device: Retroid Pocket Nova, adb serial `675a2365`
- Android: 13, product `kalama`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- APK: `com.xjsonderulo.steamandroid.novalab`
- Presentation: direct Termux:X11, Android `1280x960`, stretched X11
  `1280x800`, extra-key bar hidden
- Steam: signed-in software/CEF profile
- Gamescope/AHardwareBuffer: not used
- Input, audio, and game launch: not exercised
- Intended run ID:
  `nova-one-click-stop-caller-guard-20260810T`

The run uses the APK built from the current source after the committed
`nova-runtime-cleanup.sh` guard. It must capture a settled Steam frame and
then invoke the exact product stop command.

## Acceptance

The stop result is accepted only if all of these are present from the same
fresh run:

```text
nova_launcher_cleanup_exclude_pids=...
nova_launcher_x11_stretch_restore=pass
nova_runtime_cleanup=pass
nova_launcher_stop=pass
```

The final settled process list and exact rootfs residue scan must be empty,
the Termux:X11 preferences must match the pre-run SHA-256 byte-for-byte, and
the stop command must return status zero. A clean process list without the
completion marker remains a failure.

This predeclaration is committed and pushed before the device run.
