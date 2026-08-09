# Termux:X11 rootfs `/dev` bind probe result — 2026-08-09

Status: passed. A private mount namespace can bind Android's real `/dev` over
the disposable rootfs and uid 501 can open the needed device paths.

## Run identity and provenance

```text
run_id=termux-x11-20260809T180000Z-dev-bind-probe-0
repo_commit=dd5088db1b649d7972023408b5cd71f6158fead4
adb_serial=675a2365
device=Retroid Pocket Nova
android=13
device_root=/data/local/tmp/nova-holo-rootfs
probe_sha256=2f40c42cc30ab2257ca35f1efd68d15a33306f1f05ba555270b219fa727bc512
mount_private_sha256=bd19b2ea6eb661f210dcbd5868ce54df678ffdf6ee43035995956789917f6520
runtime_cleanup_sha256=1f647219af5d3dae2e6b8d2ebc5f8ae38bfa241598a0f8d35988dd4a4371c1ed
uid_gid=501:20
termux_x11_server=not_launched
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
```

## Device result

The fresh private namespace and bind operation passed:

```text
mount_private=pass path=/
nova_mount_propagation=private
nova_mount_dev=pass source=/dev target=/data/local/tmp/nova-holo-rootfs/dev
crw-rw-rw- ... u:object_r:null_device:s0 1,3 ... /data/local/tmp/nova-holo-rootfs/dev/null
crw-rw-rw- ... u:object_r:random_device:s0 1,9 ... /data/local/tmp/nova-holo-rootfs/dev/urandom
device_open=pass
nova_x11_dev_bind_probe=pass
```

The `device_open=pass` check ran inside the rootfs after the bind as uid
501:20 and opened both `/dev/urandom` and `/dev/null`. This is the missing
prerequisite that the earlier `mknod` repair could not provide on `/data`'s
`nodev` mount.

## Cleanup

The probe explicitly unmounted the bind inside the private namespace. The
exact Nova cleanup helper passed before and after:

```text
nova_runtime_cleanup=pass root=/data/local/tmp/nova-holo-rootfs attempts=1 term_pids= kill_pids= remaining=
```

The post-run process check found no probe, mount helper, Steam, or Termux:X11
process. No rootfs device files were replaced or modified by this run.

## Decision and next step

The bind strategy is validated and is now the preferred direct-X11 device
namespace path. Integrate it only into the client private namespace so the
bind remains scoped to the chrooted Steam process tree. Keep uid 501:20 and
the existing Steam flags/renderer; do not combine this with a UID, launcher,
Gamescope, AHardwareBuffer, or input change. The next result boundary is
whether native Steam gets past initialization and creates a visible X11
window with the real Android device namespace.
