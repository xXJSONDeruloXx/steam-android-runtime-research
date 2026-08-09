# Termux:X11 native ARM64 Steam `/dev/shm` result — 2026-08-09

Status: `/dev` and `/dev/shm` namespace repair passed. Steam advanced to an
executable-path/procfs boundary and exited before creating an X11 child.

## Run identity and provenance

```text
run_id=termux-x11-20260809T190000Z-native-steam-dev-shm-display-0
repo_commit=2cf42a10a5b7559cdbf2ab6aa5ef8a8ff7a17321
adb_serial=675a2365
device=Retroid Pocket Nova
android=13
device_root=/data/local/tmp/nova-holo-rootfs
display=:0
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
steam_launcher_sha256=d21fce0d327d146295142612670028f96977400d003c006ac72ee106397f95df
x11_private_namespace_helper_sha256=bc4c21b7bff672d8f18b4980442c4c5359188225853f9664fdd9799953491618
x11_client_launcher_sha256=6ac146ef54286d832440e5e5c24b78673f938c7179cf5f7743d57d1d36f5cece
mount_private_helper_sha256=bd19b2ea6eb661f210dcbd5868ce54df678ffdf6ee43035995956789917f6520
presentation=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
bind_android_dev=1
client_namespace_mode=chroot-dev
steam_uid=501:20
steam_timeout=60s
x11_window_wait_seconds=25
```

## New Steam boundary

The same direct Steam profile now passes the device and shared-memory seams:

```text
mount_private=pass path=/
client_runtime_owner_status=pass
client_network_api_compat_status=0
client_xhost_local_status=0
client_started=pass
client_status=155
client_installed=pass
```

The fresh captured Steam stderr is only 807 bytes and no longer contains the
previous semaphore/thread-synchronization failures. Its decisive lines are:

```text
CProcessEnvironmentManager is ready, 5 preallocated environment variables.
src/steamexe/main.cpp (1330) : Plat_GetExecutablePath returned false
src/steamexe/main.cpp (1330) : Plat_GetExecutablePath returned false
```

The run-scoped artifact hashes are:

```text
steam-client.log sha256=0a60aee68283eba22e5318c77c2851ae115d0ddd3692199ec30c96905aaa6d7a
steam-client.stdout sha256=e7a3de096b981f2fadf271a67881392867aa0bcceffb3e9f701aecbcf8c376fa
steam-client.stderr sha256=990adcef034c04f77c3c48ec91b9f86631c52b9c1230bdf584be897dff49c7fb
```

## Procfs evidence

The rootfs `/proc` remained an empty ordinary directory after the client
namespace exited:

```text
drwxr-xr-x ... u:object_r:shell_data_file:s0 ... /data/local/tmp/nova-holo-rootfs/proc
dr-xr-xr-x ... u:object_r:proc:s0 ... /proc
proc /proc proc rw,relatime,gid=3009,hidepid=invisible 0 0
```

The existing Holo glibc setup binds Android `/proc` into the rootfs. The
`Plat_GetExecutablePath` failure is therefore the next targeted hypothesis,
not yet a confirmed cause; the next run must bind only `/proc` in the same
private namespace and preserve the successful `/dev` + `/dev/shm` setup.

## Presentation and cleanup

The X11 tree stayed at the viewable root only, so no Android screenshot was
accepted:

```text
nova_x11_display=pass display=:0 screen=0 root=0x511
nova_x11_window id=0x511 parent=0x0 depth=0 map_state=viewable x=0 y=0 width=1280 height=714 border=0 name="<none>"
nova_x11_tree=pass root=0x511
```

Exact Termux:X11 and Nova cleanup passed with no residual process or socket.
No OOBE, login, QR, Gamescope, AHardwareBuffer, or SurfaceControl result is
claimed.

## Decision and next step

Retain both Android `/dev` and the private `1777` `/dev/shm` tmpfs. Add only an
Android `/proc` bind to `chroot-dev`, unmounting it after Steam exits, and run
the same profile again with automatic log capture.
