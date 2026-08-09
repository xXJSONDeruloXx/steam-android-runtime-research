# Termux:X11 rootfs `/dev` bind probe experiment — 2026-08-09

Status: completed; the device result is recorded in
`docs/139-termux-x11-rootfs-dev-bind-probe-result-2026-08-09.md`.

## Why this is next

The [root-identity result](137-termux-x11-native-steam-root-identity-result-2026-08-09.md)
identified the decisive constraint: `/data` is mounted `nodev`, so character
devices created inside `/data/local/tmp/nova-holo-rootfs/dev` cannot be opened,
even by uid 0. The repository's existing private-mount infrastructure has
already reported successful private propagation and `/dev` bind operations in
the native input path.

This experiment tests that capability directly against the actual disposable
Steam rootfs, without launching Steam or Termux:X11.

## One-variable change

Inside a fresh `unshare -m` namespace, the probe:

1. marks `/` private with the existing checked-in `nova-mount-private` helper;
2. bind-mounts Android's real `/dev` over the rootfs `/dev`;
3. enters the rootfs as uid 501:20 and opens `/dev/urandom` and `/dev/null`;
4. unmounts the bind before leaving the namespace.

The rootfs files are not replaced or modified. The exact Nova cleanup helper
runs before and after the probe, and the mount helper and probe hashes are
recorded with the run metadata.

## Acceptance and interpretation

The target result is:

```text
nova_mount_propagation=private
nova_mount_dev=pass source=/dev target=/data/local/tmp/nova-holo-rootfs/dev
device_open=pass
nova_x11_dev_bind_probe=pass
```

That would validate the next direct Steam profile: use the same private
namespace bind before chroot, retain uid 501:20, and remove the rootfs device
node workaround from the causal path. A bind failure leaves the mount
capability as the blocker; an open failure after a bind means the namespace
or mount propagation is not equivalent to the earlier input runs.

No Steam, X11 window, screenshot, OOBE, login, QR, Gamescope, or
AHardwareBuffer claim can be made from this probe.
