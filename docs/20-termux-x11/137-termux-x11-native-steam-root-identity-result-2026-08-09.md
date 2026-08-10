# Termux:X11 native ARM64 Steam root-identity result — 2026-08-09

Status: failed before Steam process initialization. Running the launcher as
uid 0 did not bypass the rootfs device-access boundary.

## Run identity and provenance

```text
run_id=termux-x11-20260809T173000Z-native-steam-root-display-0
repo_commit=ae8717c78e15b7aefab15355669078bb23ce74bd
adb_serial=675a2365
device=Retroid Pocket Nova
android=13
device_root=/data/local/tmp/nova-holo-rootfs
display=:0
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
steam_launcher_sha256=d21fce0d327d146295142612670028f96977400d003c006ac72ee106397f95df
rootfs_devices_helper_sha256=c0487f0b5ea53ca1fb378562e705efdf245247ab0dd105e43e374c0804e8c4c7
presentation=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
steam_uid=0:0
x11_window_name=any viewable depth-1 child
x11_window_wait_seconds=25
```

## Observed boundary

Termux:X11 itself passed and exposed a fresh root window, but no Steam child
appeared:

```text
termux_x11_server=pass display=:0 socket=/data/local/tmp/nova-holo-rootfs/tmp/.X11-unix/X0
nova_x11_display=pass display=:0 screen=0 root=0x511
nova_x11_window id=0x511 parent=0x0 depth=0 map_state=viewable x=0 y=0 width=1280 height=714 border=0 name="<none>"
nova_x11_tree=pass root=0x511
```

The fresh launcher log proves that the uid override reached the rootfs
client, but the shell still could not open the rootfs `/dev/null` while
constructing the background Steam command:

```text
client_uid=0
client_gid=0
client_runtime_owner_status=pass
client_network_api_compat_status=0
client_xhost_local_status=0
client_started=fail
client_status=1
client_stdout=100
client_stderr=0
```

The separate launcher stderr was:

```text
/tmp/nova-x11-animate-termux-x11-20260809T173000Z-native-steam-root-display-0: line 124: cannot redirect standard input from /dev/null: Permission denied
/tmp/nova-x11-animate-termux-x11-20260809T173000Z-native-steam-root-display-0: line 130: /dev/null: Permission denied
/tmp/nova-x11-animate-termux-x11-20260809T173000Z-native-steam-root-display-0: line 135: /dev/null: Permission denied
/tmp/nova-x11-animate-termux-x11-20260809T173000Z-native-steam-root-display-0: line 36: /dev/null: Permission denied
```

There is no fresh Steam stderr from this run because the Steam executable was
not reached. The existing `client_installed=pass` marker remains only a
package-state marker.

## Root cause of the device-node dead end

The run was followed by a read-only mount inspection:

```text
/dev/block/dm-14 /data f2fs rw,lazytime,seclabel,nosuid,nodev,noatime,... 0 0
```

The rootfs lives at `/data/local/tmp/nova-holo-rootfs`. Its character nodes are
therefore on a `nodev` filesystem. Their `crw-rw-rw-` mode and `mknod` success
are not sufficient: the kernel refuses to open device inodes on that mount,
including for the root-identity A/B. This also explains why Android's real
`/dev/null` and `/dev/urandom` work while identically numbered nodes created
under the rootfs do not.

The existing lab's private mount infrastructure has previously reported
`mount_propagation=private` and `relay_mount_dev=pass`; the next test should
use that capability instead of creating device nodes on `/data`.

## Cleanup

The exact Termux:X11 and Nova cleanup gates passed:

```text
namespace_cleanup=pass
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
nova_x11_cleanup=pass
nova_runtime_cleanup=pass root=/data/local/tmp/nova-holo-rootfs attempts=1 term_pids= kill_pids= remaining=
```

No Android screenshot was accepted because no Steam window appeared. This run
did not reach CEF, SteamUI, OOBE, login, QR presentation, Gamescope, or the
AHardwareBuffer path.

## Decision and next step

The root-identity A/B is rejected as a remedy. Do not spend another Steam run
on uid or launcher stdin variants while the rootfs remains on `nodev` storage.
Predeclare a mount-namespace-only bind probe for `/dev` over the rootfs
`/dev`, verify uid-501 access to the real Android nodes, unmount it in the
same namespace, and only then retry direct Steam with that mount in place.
