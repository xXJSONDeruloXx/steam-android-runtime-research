# Nova one-click touch launch failure result — 2026-08-10

Status: invalid touch sample; the APK session failed before Steam produced a
frame. The failure exposed a stale rootfs system-D-Bus socket left by the
previous forced teardown.

## Run identity

- Experiment: `nova-one-click-touch-20260810T151958Z`
- Source commit: `27fc4bd`
- APK SHA-256: `168b89ecd063ff5479223ffa52843c137a5a095c003c759336f63729ae7739a3`
- Device: Retroid Pocket Nova, Android 13, adb serial `675a2365`, `kalama`
- Start mode: visible APK `Start Steam` button; no Steam launch extras
- Host evidence: `android/nova-lab/build/runs/nova-one-click-touch-20260810T151958Z/`

## Failure evidence

The launcher reached its normal readiness marker, but Steam exited before
initializing its UI. The fresh client log recorded:

```text
client_dbus_system=enabled
client_dbus_system_status=fail reason=stale_socket
```

The stale object was confirmed at:

```text
srwxrwxrwx ... /data/local/tmp/nova-holo-rootfs/run/dbus/system_bus_socket
```

This path is inside the exact Nova rootfs and was not accompanied by a live
Nova runtime process. It was left behind when a previous stop killed the
root-side D-Bus daemon before its shell `EXIT` cleanup ran.

The launcher recorded `nova_launcher_client_exit=1` and the first stop
returned `nova_launcher_stop=fail status=1` because the X11 cleanup verifier
saw a transient `server_parent_state=present`. A second exact launcher stop,
after the process-exit race settled, returned `nova_launcher_stop=pass`; the
runtime cleanup marker was already `nova_runtime_cleanup=pass`, and the final
matching-process audit was empty.

## Touch boundary

The captured “before-touch” image was still the APK launcher screen showing
`Nova launcher exited with status 143`. No Steam surface existed, so the
planned `(620,545)` Friends tap was not a valid touch sample and no touch
conclusion is drawn.

## Corrective experiment

The next isolated change will remove only the stale system-D-Bus socket and
pid marker under this exact rootfs after the no-live-runtime preflight and
during exact Nova teardown. It will log the cleanup result and fail closed if
either object cannot be removed. No global `/run` state, Android service, input,
display, or Steam code will be changed.
