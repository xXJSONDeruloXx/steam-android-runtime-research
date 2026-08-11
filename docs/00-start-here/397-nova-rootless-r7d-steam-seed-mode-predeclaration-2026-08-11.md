# Nova rootless R7d — public Steam seed mode retry predeclaration — 2026-08-11

Run ID: `nova-rootless-r7d-steam-seed-mode-20260811T062111Z`
Sub-run: `R7d-steam-seed-mode`
Status: predeclared; the failed R7c tree was removed before launch.

## Controlled change

R7c reached the seed-bound closure but `ldd` refused to inspect
`steamui.so` because the ZIP extraction produced it as `0666`. R7d changes
only the app-private public seed mode after copy, before any execution:

```text
steamui.so
steam
steamwebhelper
steamwebhelper.sh
```

These files receive owner-execute permission. The two R7c PRoot `libtalloc`
soname links and all helper inputs remain unchanged. No SteamUI patch, library
addition, display change, network change, audio change, input change, or
rooted-runtime mutation is permitted.

## Device, branch, and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `e21a9b7` (`docs: record rootless R7c seed mode boundary`).
- APK SHA-256:
  `625be387f085876f2c518cd2ea5ff8bb395f9f454ecf9517115b91d50135c39c`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Combined Holo manifest: 103 entries, SHA-256
  `ffb4a35f5acdc3ce1a24b070fe9ecc08cde495f737ef5e73409eda4fc23a8f92`.
- Public ARM64 Steam seed: 109767361 bytes, SHA-256
  `1c1dd74e63db8d2d64445c7d6156f02e3b2719141e569b52e91b883d39592e82`.

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r7d-steam-seed-mode-20260811T062111Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r7d-steam-seed-mode-20260811T062111Z/
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

1. Verify the new exact scope is absent, no matching process remains, free
   space and app UID are sufficient, and rooted rollback paths are present.
2. Restage and hash-verify the same archive, 103 Holo packages, two Debian
   assets, PRoot files, and public ARM64 seed. Add only the two `libtalloc`
   soname links and the four owner-execute mode changes listed above. Do not
   create Steam home/authentication files.
3. Run the unchanged archive extractor with absolute PRoot paths. Require an
   atomic app-readable candidate.
4. Run the unchanged complete guest closure with the public seed bound at
   `/opt/nova-steam`. Require all 103 packages, GTK2/audio paths, the guest
   marker, and a clean executable `steamui.so` `ldd` result.
5. If closure passes, run supervisor `preflight` and only
   `/opt/nova-steam/steamrtarm64/steam --version` with fresh state/log files.
   Do not start Termux:X11 or claim Steam UI/network/audio/controller/login/
   game success from this run.
6. Stop at the first failed gate, document, commit, and push before making
   another change.

## Cleanup

After the result is recorded, remove only the R7d app-private and remote
trees. Verify no matching PRoot/pacman/bsdtar/Steam/Termux:X11 process or
staging directory remains, and confirm the rooted rollback paths are unchanged.

## Follow-up

If the closure and version-only supervisor invocation pass, predeclare a fresh
rootless Termux:X11 SteamUI run. SteamRT3C and Runtime 4/Proton 11 remain
separate later inputs; Gamescope/AHardwareBuffer remains optional.
