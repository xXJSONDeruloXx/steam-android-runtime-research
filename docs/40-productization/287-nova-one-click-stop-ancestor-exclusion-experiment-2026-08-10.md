# Nova one-click stop ancestor exclusion experiment — 2026-08-10

Status: predeclared; no device session has been launched under this run.

## Question

The previous one-click run restored Termux:X11 preferences and left no Nova
processes, but the stop command returned `143` before `nova_launcher_stop=pass`.
The exact runtime cleanup matcher excluded only the stop script PID and its
immediate parent. Under the Android `adb shell` → `su` → shell nesting, a
grandparent carrying the rootfs path was still classified as Nova runtime and
could terminate the stop command itself.

Can the launcher preserve the stop command's complete ancestor chain while
continuing to terminate the separate long-lived Nova start wrapper and all of
its descendants?

## Implementation under test

The root launcher now walks up to 16 numeric `/system/bin/ps` parent links
from the stop script's `PPID` and passes the complete chain, plus `$$`, as
`NOVA_RUNTIME_CLEANUP_EXCLUDE_PIDS`. It logs the selected exclusion list for
provenance. This is a narrow caller-preservation change: it does not exclude
the start wrapper, Steam, Gamescope, Xwayland, relay, or any other runtime
descendant unless that process is genuinely an ancestor of the stop command.

## Fixed profile and run identity

- Device: Retroid Pocket Nova, adb serial `675a2365`
- Android: 13, product `kalama`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- APK: `com.xjsonderulo.steamandroid.novalab`
- Presentation: direct Termux:X11, `1280x960` Android surface with
  `1280x800` stretch and extra-key bar hidden
- Steam: signed-in software/CEF profile
- Input, audio, and game launch: not exercised
- Intended run ID:
  `nova-one-click-stop-ancestor-exclusion-20260810T`

The fresh run must start a new session, capture a settled Steam frame, invoke
the exact product stop path, and require all of these teardown markers:

```text
nova_launcher_cleanup_exclude_pids=...
nova_launcher_x11_stretch_restore=pass
nova_runtime_cleanup=pass
nova_launcher_stop=pass
```

It must also verify a settled empty Nova process/residue audit and byte-for-byte
restoration of the Termux:X11 preferences. A clean process audit without the
completion marker is not a pass.

This predeclaration is committed and pushed before the device regression.
