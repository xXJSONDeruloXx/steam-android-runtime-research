# Termux:X11 native ARM64 Steam `/dev` bind result — 2026-08-09

Status: device namespace repair passed; Steam reached its bounded process
timeout but failed to initialize thread/semaphore infrastructure, before an
X11 child window appeared.

## Run identity and provenance

```text
run_id=termux-x11-20260809T182500Z-native-steam-dev-bind-display-1
repo_commit=4fdbe1003d5f3a0f7a36a63d53feef01be3db40a
adb_serial=675a2365
device=Retroid Pocket Nova
android=13
device_root=/data/local/tmp/nova-holo-rootfs
display=:0
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
steam_launcher_sha256=d21fce0d327d146295142612670028f96977400d003c006ac72ee106397f95df
x11_private_namespace_helper_sha256=14c29e4175f881aaabb3a6ed5ccd6ea551d8f3958d2c7d10174c68911f708400
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

## Device and Steam boundary

The client namespace reached the private mount helper and the Steam launcher:

```text
mount_private=pass path=/
client_runtime_owner_status=pass
client_network_api_compat_status=0
client_xhost_local_status=0
client_started=pass
client_status=124
client_timeout=expected
client_installed=pass
```

The run-scoped Steam log was pulled from the disposable rootfs after teardown:

```text
client_uid=501
client_gid=20
client_pid=10998
client_started=pass
client_status=124
client_timeout=expected
client_stdout=100
client_stderr=2507
```

The decisive fresh stderr was:

```text
CProcessEnvironmentManager is ready, 5 preallocated environment variables.
src/tier0/threadtools.cpp (2526) : Assertion Failed: Permission denied
src/tier0/threadtools.cpp (2121) : Assertion Failed: semaphore creation failed No such file or directory
src/tier0/threadtools.cpp (1951) : Thread synchronization object is unuseable
```

The same errors repeated while Steam installed its exception handler and
attempted to use its minidump directories. This is a new post-`/dev` boundary:
the old `s_dev_urandom_fd` assertion and shell `/dev/null` failures are gone.

The captured rootfs artifacts are:

```text
steam-client.log sha256=d6cc6ebdced36ba49fb1b648aaa2c5fee16ec382b42274a0e315d145bd6708e5
steam-client.stdout sha256=e7a3de096b981f2fadf271a67881392867aa0bcceffb3e9f701aecbcf8c376fa
steam-client.stderr sha256=7f5396987c0d58895b378847e0c459925e183575887d539362eea33deb80bba7
```

## `/dev/shm` observation

After the bind was removed, the rootfs `/dev/shm` was only a normal
`drwxr-xr-x` directory. Android's `/dev/shm` is also a directory beneath the
host `/dev` tmpfs; there was no separate `tmpfs` mount at `/dev/shm` in the
run's mount table. The existing Holo glibc harness explicitly mounts:

```text
tmpfs on <rootfs>/dev/shm type tmpfs mode=1777
```

This direct profile did not. The semaphore `ENOENT`/permission sequence is
consistent with Steam's POSIX/System-V compatibility path lacking a writable
shared-memory namespace, but this remains a hypothesis until the next
one-variable mount test.

## Cleanup and presentation result

The fresh X11 tree remained root-only, so no screenshot was accepted:

```text
nova_x11_display=pass display=:0 screen=0 root=0x511
nova_x11_window id=0x511 parent=0x0 depth=0 map_state=viewable x=0 y=0 width=1280 height=714 border=0 name="<none>"
nova_x11_tree=pass root=0x511
```

Exact Termux:X11 and Nova cleanup passed, with no remaining runtime process or
socket. No OOBE, login, QR, Gamescope, AHardwareBuffer, or SurfaceControl
claim follows from this run.

## Decision and next step

Keep the Android `/dev` bind and uid 501. Add only a private `tmpfs` mounted at
the bound rootfs `/dev/shm` with mode `1777`, using the same cleanup lifetime,
then repeat the direct Steam profile with a fresh run ID. Also make the host
harness pull the three rootfs Steam log files automatically so a bounded kill
cannot hide the decisive child stderr.
