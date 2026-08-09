# Termux:X11 rootfs device-namespace repair result — 2026-08-09

Status: failed at the rootfs shell-launch boundary; the device-node repair
itself passed. No reliable fresh Steam process or X11 client window was
observed.

## Run identity and provenance

```text
run_id=termux-x11-20260809T163000Z-native-steam-devices-display-0
repo_commit=2fc35da9050bbf3ed7bfd1a18e0a0f35f764817d
adb_serial=675a2365
device=Retroid Pocket Nova
android=13
device_root=/data/local/tmp/nova-holo-rootfs
display=:0
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
steam_launcher_sha256=8276eb2034302b20321be5887e23c3fb9299dca30c6c434d9bbf2d9871fad3a4
rootfs_devices_helper_sha256=c0487f0b5ea53ca1fb378562e705efdf245247ab0dd105e43e374c0804e8c4c7
nova_x11_capture_sha256=a8971824bfcb812139bcc7451a1ab2c262b4a2af0ff9d462e25206a3efb4b017
presentation=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
steam_flags=-gamepadui -steamos3 -steampal -steamdeck -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui -no-cef-sandbox
steam_renderer=swrast + softpipe + LIBGL_ALWAYS_SOFTWARE=1
steam_uid=501:20
steam_timeout=60s
x11_window_name=any viewable depth-1 child
x11_window_wait_seconds=25
```

## Device-node repair

The rootfs helper passed before the Activity/server launch and verified the
expected character devices:

```text
nova_rootfs_device=pass name=null path=/data/local/tmp/nova-holo-rootfs/dev/null
nova_rootfs_device=pass name=zero path=/data/local/tmp/nova-holo-rootfs/dev/zero
nova_rootfs_device=pass name=full path=/data/local/tmp/nova-holo-rootfs/dev/full
nova_rootfs_device=pass name=random path=/data/local/tmp/nova-holo-rootfs/dev/random
nova_rootfs_device=pass name=urandom path=/data/local/tmp/nova-holo-rootfs/dev/urandom
nova_rootfs_device=pass name=tty path=/data/local/tmp/nova-holo-rootfs/dev/tty
nova_rootfs_devices=pass root=/data/local/tmp/nova-holo-rootfs
```

This proves that root can create the nodes in the disposable rootfs. It does
not yet prove that every rootfs process can use them: Android assigned the
nodes the `shell_data_file` SELinux context because the rootfs lives below
`/data/local/tmp`.

## Observed launch boundary

Termux:X11 started successfully. The X11 tree remained root-only after the
25-second window wait:

```text
nova_x11_display=pass display=:0 screen=0 root=0x511
nova_x11_window id=0x511 parent=0x0 depth=0 map_state=viewable x=0 y=0 width=1280 height=714 border=0 name="<none>" res_name="<none>" res_class="<none>"
nova_x11_tree=pass root=0x511
```

The launcher reached its setup code and then failed before providing reliable
evidence that the Steam executable ran:

```text
client_runtime_owner_status=pass
client_network_api_compat_status=0
client_xhost_local_status=0
client_started=fail
client_status=1
client_installed=pass
client_stdout=0
client_stderr=0
```

The fresh client stderr identifies the actual boundary:

```text
/tmp/nova-x11-animate-termux-x11-20260809T163000Z-native-steam-devices-display-0: line 123: /dev/null: Permission denied
/tmp/nova-x11-animate-termux-x11-20260809T163000Z-native-steam-devices-display-0: line 128: /dev/null: Permission denied
/tmp/nova-x11-animate-termux-x11-20260809T163000Z-native-steam-devices-display-0: line 117: cannot redirect standard input from /dev/null: Permission denied
/tmp/nova-x11-animate-termux-x11-20260809T163000Z-native-steam-devices-display-0: line 29: /dev/null: Permission denied
```

The errors correspond to the launcher’s background-process implicit stdin
handling and its diagnostic `2>/dev/null` redirections. Therefore this run
must not be described as a second fresh Steam `s_dev_urandom_fd` failure: the
launcher failed while constructing the command, and its Steam stdout/stderr
files remained empty. The `client_installed=pass` line reflects the existing
package marker in the rootfs, not a successful launch in this run.

## Narrowing diagnostic — superseded ad-hoc probe

An ad-hoc nested `adb shell su -c` command printed the following after
teardown:

```text
exec 3</dev/urandom; echo fd_status=$?
fd_status=0
exec 4>/dev/null; echo null_status=$?
null_status=0
```

The later checked-in stdio probe in
`docs/135-termux-x11-rootfs-stdio-probe-result-2026-08-09.md` disproved this
as a reliable uid-501 chroot result: the nested quoting did not establish the
same controlled execution boundary. The controlled probe is the authoritative
result and found that uid 501 is denied even by foreground opens. This result
note retains the earlier output for provenance but it must not be used as a
positive device-access claim.

## Cleanup and acceptance result

The Termux:X11 and Nova cleanup gates passed, and no Steam or X11 client window
was left behind:

```text
pre_cleanup_server_pids=1973,
pre_cleanup_client_pids=
client_matching=1 phase=runtime
namespace_cleanup=pass
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
nova_x11_cleanup=pass
```

No Android screenshot was accepted because no Steam window appeared. This run
did not reach CEF, SteamUI, OOBE, login, QR presentation, Gamescope, or the
AHardwareBuffer path.

## Decision and next step

Keep the character-device helper: it is a valid prerequisite repair. Do not
change Gamescope, AHardwareBuffer, the Termux:X11 APK, Steam flags, renderer,
or UID in the next experiment. First predeclare and commit a minimal
rootfs-side stdio/`timeout` probe that compares explicit stdin/stdout/stderr
file descriptors with the shell’s implicit background behavior. Only after
that probe passes should the same launcher be retried against native Steam.
