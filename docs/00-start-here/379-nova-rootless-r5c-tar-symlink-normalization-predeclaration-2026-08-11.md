# Nova rootless R5c — tar symlink normalization retry — 2026-08-11

Run ID: `nova-rootless-r5c-20260811T052537Z`
Status: predeclared; R5a/R5b extraction results are not reused as readiness.

## Controlled change

R5b proved the app-writable parent strategy works, then exposed toybox’s
display-only ` -> target` suffix in `tar -t` output. R5c changes only the
file-list normalization to strip that suffix before the existing
non-directory filter. Archive, PRoot, closure, rootfs, Steam client, display,
and login variables remain unchanged.

## Device, branch, and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `78f07f6` (`fix: normalize toybox tar symlink listings`).
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `6d0f8368107ceda4ec38bc9f94601ba1ee13e1f00b27e21637bf1bc85ddc25e4`.
- Holo archive size: `384971555` bytes.
- Holo archive SHA-256:
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- SteamUI Holo manifest SHA-256:
  `6583d0a34da45418d82dba9afa369acc22881fc318550b1a4c876c4235241fae`.
- External GTK2 manifest SHA-256:
  `00c06ef768b5c86f67a9e46bbd4f661b2e8e8344d81457af6986d5f9a8ee7354`.

## Exact mutable scope

```text
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r5c-20260811T052537Z/
  rootfs-archive/system.rootfs.zst
  guest-rootfs/
  home/
  state/
  proot/
  scripts/
  steam-client/
  steamui-packages/
```

The rooted rollback paths are immutable and outside scope:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
/data/local/tmp/nova-holo-rootfs
```

## Run sequence and acceptance

1. Verify exact R5b cleanup and rooted rollback presence. Install the pinned
   APK and record its hash.
2. Stage the same archive, PRoot, package closure, and manifests under R5c;
   verify archive and package counts/hashes as the app UID.
3. Run the app-UID archive extractor. Require atomic activation, the archive
   marker, required glibc/pacman paths, and app ownership.
4. Run the Holo/Debian SteamUI closure helper against the app-owned rootfs.
   Require its marker, libraries, and clean `ldd steamui.so` result.
5. Only after those gates pass, start fresh Termux:X11 `:78` on port `6078`
   and run the updated ARM64 Steam client. Do not reuse `:77`.

Separate any later SteamUI frame, OOBE, QR login, network, audio, controller,
Proton, or game result from the extraction/closure result. Never export or copy
Steam authentication data.

## Cleanup

Capture R5c logs, stop only R5c paths and display `:78`, verify port `6078` is
closed, remove only the R5c app-private tree and named temporary push tree,
and confirm the rooted rollback paths remain present.
