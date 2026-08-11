# Nova rootless R6b — Holo `bsdtar` mode result — 2026-08-11

Run ID: `nova-rootless-r6b-20260811T054200Z`
Sub-run: `R6b-holo-bsdtar-mode`
Status: archive extraction returned success; app-readability gate failed
before SteamUI package closure.

## Result

R6b repeated the app-UID Holo `bsdtar` extraction after changing `-xpf` to
`-xf` and creating `state/proot-tmp` before PRoot launch. The previous PRoot
temporary-directory warnings disappeared. Extraction completed atomically
with the expected archive marker, required glibc/pacman paths, app ownership,
and no partial staging directory:

```text
nova_rootless_rootfs_archive=extract archive=files/rootless-r6b-20260811T054200Z/rootfs-archive/system.rootfs.zst stage=files/rootless-r6b-20260811T054200Z/.guest-rootfs.archive-staging.25252
nova_rootless_rootfs_archive=pass rootfs=files/rootless-r6b-20260811T054200Z/guest-rootfs
```

The candidate was not yet usable as an app-owned guest. The same archive
entry that blocked R6 still had a mode without owner read permission:

```text
---x--x--- 1 u0_a128 u0_a128 ... dbus-daemon-launch-helper
readable=1
```

The `readable=1` value is the failed `test -r` status. The SteamUI closure
helper was not started in R6b because this app-readability gate failed first.

## Classification

Holo `bsdtar` is a viable archive reader through PRoot, but its available
permission behavior did not normalize this archive into an app-readable
guest, even without `-p`. The archive path therefore needs an explicit
post-extraction owner-access normalization step. This is narrower and more
auditable than additional toybox member-name rewriting.

The rooted Holo bootstrap tree and rooted Steam state were not modified. No
Steam authentication data was exported or copied. No Steam, Termux:X11,
network, audio, controller, Proton, or game result was produced in R6b.

## Scope and provenance

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `934ffd8` (`docs: predeclare rootless R6b mode retry`).
- APK SHA-256:
  `e60c53de5e741e5109cfc1bd0d82f473dd600da7a3414c736aed6f8e8e53843e`.
- Holo archive size: `384971555` bytes.
- Holo archive SHA-256:
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- PRoot execution UID: app UID `u0_a128`; no `su`, `chroot`, or `mount` was
  used by the helper.

## Cleanup

R6b's failed candidate is inside the declared app-private tree and must be
made owner-accessible only for exact-scope cleanup before the next run. The
remote staging tree and app-private tree must then be removed, with no
matching PRoot/bsdtar process left. Rooted rollback paths remain outside
scope:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Next bounded change

Predeclare R6c with one code change after extraction: run
`chmod -R u+rwX` on the app-owned staging tree. Repeat the archive marker,
required-path, owner, and `test -r`/`test -x` gates before attempting package
installation.

