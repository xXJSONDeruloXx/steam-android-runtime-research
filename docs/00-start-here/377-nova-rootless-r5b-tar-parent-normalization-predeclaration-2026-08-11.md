# Nova rootless R5b — tar parent normalization retry — 2026-08-11

Run ID: `nova-rootless-r5b-20260811T052136Z`
Status: predeclared; R5a’s failed extraction and any old process/log state are
not evidence for this retry.

## Controlled change

R5a verified the Holo archive but toybox tar restored rootfs directory modes
before later hardlinks, causing extraction failure. R5b changes only the
archive extraction command: it lists the pinned archive, filters its
non-directory entries into a file list, and extracts with toybox tar `-T` so
parent directories are created with app-writable defaults. The archive hash,
rootfs, package closure, PRoot, client tree, display, and Steam variables stay
the same.

## Device, branch, and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `d22fa13` (`fix: normalize rootless tar extraction parents`).
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `3ca6536a2ee1cff57b48ff3f114ff673ccde5fdc6ba36e734c7c6a9b321f73aa`.
- Holo archive size: `384971555` bytes.
- Holo archive SHA-256:
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- SteamUI Holo manifest SHA-256:
  `6583d0a34da45418d82dba9afa369acc22881fc318550b1a4c876c4235241fae`.
- External GTK2 manifest SHA-256:
  `00c06ef768b5c86f67a9e46bbd4f661b2e8e8344d81457af6986d5f9a8ee7354`.

## Exact mutable scope

```text
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r5b-20260811T052136Z/
  rootfs-archive/system.rootfs.zst
  guest-rootfs/
  home/
  state/
  proot/
  scripts/
  steam-client/
  steamui-packages/
```

The immutable rooted paths remain outside scope:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
/data/local/tmp/nova-holo-rootfs
```

## Run sequence and acceptance

1. Confirm exact R5a cleanup and rooted rollback presence. Install the pinned
   APK in place and record its hash.
2. Stage the same verified archive, PRoot files, 44 Holo packages, two Debian
   GTK2 packages, and manifests under the R5b tree. Verify counts and hashes
   as the app UID.
3. Run the archive extractor and require the archive marker, required glibc
   and pacman paths, and app ownership. If extraction fails, stop before the
   closure helper.
4. Run the guest closure helper against the app-owned candidate and require
   GTK2/GDK/PipeWire/Pulse plus clean `ldd steamui.so` output.
5. Only after those gates pass, start a fresh Termux:X11 `:78` on port `6078`
   and run the updated ARM64 Steam client. Do not reuse `:77`.

The result must distinguish archive extraction, package installation, SteamUI
loading, and any later frame/OOBE/QR boundary. No Steam authentication data is
exported, copied, or backed up.

## Cleanup

Capture R5b logs before teardown. Stop only R5b paths and display `:78`, verify
port `6078` is closed, remove only the R5b app-private tree and named
temporary push tree, and verify the rooted rollback paths remain present.
