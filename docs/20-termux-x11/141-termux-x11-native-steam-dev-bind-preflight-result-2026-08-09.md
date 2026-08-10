# Termux:X11 native ARM64 Steam `/dev` bind preflight result — 2026-08-09

Status: harness failure before client launch. This run produced no Steam
result and did not exercise the bind mount.

## Run identity

```text
run_id=termux-x11-20260809T181500Z-native-steam-dev-bind-display-0
repo_commit=ffdf04f3a95e6cfbc9f51fae2dbc453a8ba9c275
adb_serial=675a2365
device=Retroid Pocket Nova
android=13
device_root=/data/local/tmp/nova-holo-rootfs
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
x11_private_namespace_helper_sha256=14c29e4175f881aaabb3a6ed5ccd6ea551d8f3958d2c7d10174c68911f708400
mount_private_helper_sha256=bd19b2ea6eb661f210dcbd5868ce54df678ffdf6ee43035995956789917f6520
bind_android_dev=1
client_namespace_mode=chroot-dev
uid_gid=501:20
```

## Boundary

The Termux:X11 server started and the root X11 tree was fresh, but the staged
client launcher passed the namespace mode incorrectly:

```text
termux_x11_server=pass display=:0 socket=/data/local/tmp/nova-holo-rootfs/tmp/.X11-unix/X0
chroot: chroot-dev: No such file or directory
```

`android/nova-lab/device/nova-termux-x11-client-launcher.sh` still inserted a
literal `chroot` before forwarding its arguments. The new generic harness had
correctly supplied `chroot-dev`, but the launcher treated that mode as the
rootfs path. Consequently:

```text
client_begin_run_id=termux-x11-20260809T181500Z-native-steam-dev-bind-display-0 display=:0
nova_rootfs_devices=skipped mode=android-dev-bind
```

There is no fresh Steam log, stdout, stderr, X11 child, or Android screenshot
from this run. The bind mount was never attempted.

## Cleanup

The failure remained within the exact cleanup contract:

```text
namespace_cleanup=pass
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
nova_x11_cleanup=pass
nova_runtime_cleanup=pass root=/data/local/tmp/nova-holo-rootfs attempts=1 term_pids= kill_pids= remaining=
```

## Next repair

Change only the client launcher argument forwarding so it accepts the explicit
namespace mode (`chroot` or `chroot-dev`) and passes the remaining arguments
unchanged to the private helper. Commit and push that harness repair before a
fresh direct Steam bind run. No Steam, renderer, UID, or mount hypothesis is
rejected by this preflight failure.
