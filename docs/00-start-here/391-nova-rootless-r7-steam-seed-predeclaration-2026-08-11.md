# Nova rootless R7 — public ARM64 Steam seed and supervisor predeclaration — 2026-08-11

Run ID: `nova-rootless-r7-steam-seed-20260811T060538Z`
Sub-run: `R7-steam-seed-supervisor`
Status: predeclared; the R6e app and remote trees were cleaned before launch.

## Controlled change

R6e closed the app-owned Holo archive and complete 103-package UI/audio
closure. R7 changes only the Steam client input: it stages a fresh extraction
of Valve's public ARM64 Steam seed into an app-owned `steam-client/` tree and
binds that tree into the known-good guest closure. The first gate is the
guest-side `steamui.so` dependency check; the second is the rootless
supervisor preflight and a version-only Steam invocation. No Steam UI or
Termux:X11 session is started until those gates pass.

The Holo archive, PRoot, package closure, guest PATH, Debian GTK2 overlay,
network contract, audio contract, display variables, rooted runtime, and
Steam authentication data remain unchanged. The rooted Holo tree is a
read-only bootstrap input and is never modified or treated as rootless
evidence.

## Device, branch, and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `c73b786` (`docs: record rootless R6e closure pass`).
- Installed APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `625be387f085876f2c518cd2ea5ff8bb395f9f454ecf9517115b91d50135c39c`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Combined Holo manifest: 103 entries, SHA-256
  `ffb4a35f5acdc3ce1a24b070fe9ecc08cde495f737ef5e73409eda4fc23a8f92`.
- Public ARM64 Steam seed: 109767361 bytes, SHA-256
  `1c1dd74e63db8d2d64445c7d6156f02e3b2719141e569b52e91b883d39592e82`.
- Seed URL:
  `https://client-update.steamstatic.com/bins_linuxarm64_linuxarm64.zip.0f238017c65e844f71581d1fae8fb42f410e1032`.
- Steam seed manifest: `steam_client_steamdeck_publicbeta_linuxarm64`,
  client version `1785979169`.
- SteamRT3C archive retained as a later input: snapshot
  `3c.0.20260714.251839`, SHA-256
  `f59e9541fb08f36097610f8cab07a0ed8f5f13e4a642b6fead87505aff979ab0`.

The seed extraction is public client content only. Do not copy
`android/nova-lab/build/steam-bootstrap/home`, any existing Steam home, login
tokens, cookies, sentry files, or other authentication state.

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r7-steam-seed-20260811T060538Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r7-steam-seed-20260811T060538Z/
  rootfs-archive/system.rootfs.zst
  guest-rootfs/
  guest-rootfs-closure/
  state/
  proot/
  scripts/
  steam-client/
  steamui-packages/
```

Rooted rollback paths remain outside scope:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Run sequence and acceptance

1. Verify the exact R6e app/remote cleanup, no matching PRoot/pacman/bsdtar
   process, rollback-path presence, device serial, app UID, and available
   space. Do not use broad process kills or touch the rooted paths.
2. Push the pinned archive, PRoot loader/libs, helper scripts, all 103 Holo
   package artifacts, both Debian GTK2 assets, manifests, and the public seed
   extraction. Copy them into the app-owned R7 tree without pre-creating
   either atomic guest-rootfs destination. Verify size/hash at the app UID.
3. Create only public client layout metadata required by the seed probe (for
   example `steamrtarm32 -> steamrtarm64`); do not create a Steam home or
   authentication files. Keep the seed tree app-readable and record its
   extracted file count and key binary hashes.
4. Run the existing atomic archive extractor. Require the archive size/hash,
   app-readable candidate, required loader paths, and no partial destination.
5. Run the existing guest closure helper with the staged public client bound
   at `/opt/nova-steam`. Require all 103 pacman packages, the two Debian
   assets, the guest closure marker, GTK2/audio paths, and a clean
   `steamui.so` `ldd` result. A missing library is a closure/ABI result, not a
   display result.
6. Run supervisor `preflight`, then run only
   `/opt/nova-steam/steamrtarm64/steam --version` with a fresh state/log
   directory. Require an app-UID process, no `su`, `chroot`, or `mount`, and a
   fresh exit/log baseline. Do not claim Steam UI, network, audio, controller,
   QR, or game success from this step.
7. Stop at the first failed gate, preserve the exact logs and hashes in the
   result record, and do not change the helper until this result is committed
   and pushed.

## Cleanup

Pull only the R7 helper output and bounded process/log evidence. Remove the
named R7 app-private and remote trees after documenting the result; verify no
matching PRoot, pacman, bsdtar, Steam, or Termux:X11 process remains, no
staging directory or bridge socket leaked, and the rooted rollback paths are
unchanged. Do not export or back up Steam authentication secrets.

## Follow-up boundary

If R7 passes, predeclare R7b for the same public client and closure with a
fresh Termux:X11 display/socket and SteamUI startup baseline. If R7 fails at
`steamui.so` or `steam --version`, close that ABI/loader boundary first. The
separately pinned SteamRT3C archive and the official Runtime 4/Proton 11
profile remain later, independently staged experiments; Gamescope/
AHardwareBuffer stays outside the rootless critical path.
