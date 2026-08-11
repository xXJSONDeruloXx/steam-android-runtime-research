# Nova rootless R4 — source-rootfs readability result — 2026-08-11

Run: `nova-rootless-r4-20260811T050124Z`
Sub-run: `R4a-rootfs-copy`
Status: failed closed at the app-UID source copy gate; no SteamUI package
installation or client launch was attempted.

## Result

The R4 helper correctly refused to activate a candidate after `cp -R` could
not read every file in the existing rooted Holo tree. The fresh output was:

```text
nova_rootless_guest_rootfs=copy source=/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs stage=files/rootless-r4-20260811T050124Z/.guest-rootfs.staging.23386
cp: .../rootfs/./etc/shadow: Permission denied
cp: .../rootfs/./etc/pacman.d/gnupg/secring.gpg: Permission denied
cp: .../rootfs/./opt/nova-steam/home/.steam: Permission denied
cp: .../rootfs/./root: Permission denied
```

The source tree is about 5.6 GiB. The device had about 86 GiB free, so this
was not a storage failure. The temporary candidate was removed by the
helper's failure trap; no `.nova-rootless-guest-rootfs` marker was created.

## Scope and provenance

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch baseline: `238b48a` (`docs: pin R4 APK artifact`).
- APK SHA-256:
  `7055f9d8e54e3397c88ccccccac90663d49c351370a67ce70039d431c7fbbbea`.
- Source rootfs:
  `/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs`,
  expected SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Package artifacts were downloaded and verified before the device attempt:
  44 Holo archives plus 2 Debian GTK2 artifacts, 37,393,683 bytes total.
- Holo manifest SHA-256:
  `6583d0a34da45418d82dba9afa369acc22881fc318550b1a4c876c4235241fae`.
- External manifest SHA-256:
  `00c06ef768b5c86f67a9e46bbd4f661b2e8e8344d81457af6986d5f9a8ee7354`.

The rooted source, `/data/local/tmp/nova-active-runtime`, rooted Steam data,
and rooted display were not modified. No authentication data was read or
copied. R4 did not start Termux:X11 `:78` or a Steam process.

## Classification

This is an input-provisioning boundary between a root-owned extracted image
and an app-owned rootless runtime. A rootless process can use the readable
parts of the existing tree, but it cannot construct a faithful app-owned copy
when the source includes intentionally private files. Installing the Holo or
Debian closure was not reached, so this result says nothing new about GTK2,
SteamUI, X11, OOBE, networking, audio, input, Proton, or game rendering.

## Next bounded change

Do not weaken the helper by silently skipping unreadable files. The next
experiment must choose and document one of these explicit provisioning paths:

1. For a rooted clean-device bootstrap, perform a one-time root-assisted copy
   into a new app-owned candidate, verify ownership and hashes, then run the
   same rootless supervisor without root; or
2. For a genuinely rootless device, download the pinned Holo `system.rootfs`
   archive and extract it directly into app-private storage, so no root-owned
   source tree is involved.

The first option is the shortest way to continue the current rooted-device
validation, but it must remain outside the app-UID-only helper and must be
marked as a staging prerequisite rather than a rootless runtime capability.
