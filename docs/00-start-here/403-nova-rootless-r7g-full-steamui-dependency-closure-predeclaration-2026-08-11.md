# Nova rootless R7g — full SteamUI dependency closure predeclaration — 2026-08-11

Run ID: `nova-rootless-r7g-full-steamui-dependency-closure-20260811T063431Z`
Sub-run: `R7g-full-steamui-dependency-closure`
Status: predeclared; the failed R7f tree was removed before launch.

## Controlled change

R7f showed that adding only `sdl3` and `ffmpeg` is not an installable pacman
transaction. R7g adds the exact transitive Holo package closure derived from
the pinned package metadata and the Holo base guest package database. It adds
56 package artifacts, including the `jack2`, `libvpl`, `sdl2-compat`, and
multimedia codec/provider packages required by `ffmpeg`, for a new total of
161 rootless Holo entries.

The closure remains Holo-only for these additions. Debian GTK2 assets,
absolute PRoot paths, `libtalloc` soname links, seed mode normalization,
archive extraction, guest hooks, SteamUI source, display, network, audio,
input, rooted runtime, and authentication policy remain unchanged. No
`--nodeps` installation or SteamUI patch is allowed.

## Device, branch, and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `6228794` (`docs: record rootless R7f package boundary`).
- R7f APK SHA-256:
  `b2c86d1155126084a8b090954f81b31740565a1b7fd3f87db07f4cd9b223ffa6`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- R7f manifest: 105 entries, SHA-256
  `cde330b4c2af6425828378ca24a3df8844fb22d40ab05a76cc359763c8e5294c`.
- R7f public seed: 109767361 bytes, SHA-256
  `1c1dd74e63db8d2d64445c7d6156f02e3b2719141e569b52e91b883d39592e82`.
- New Holo closure target: 161 entries, sourced only from
  `android/nova-lab/build/holo-rootfs/packages/`.

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r7g-full-steamui-dependency-closure-20260811T063431Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r7g-full-steamui-dependency-closure-20260811T063431Z/
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

1. Update the manifest/profile to 161 entries, record the resulting manifest
   hash, extend static validation, rebuild the APK/assets, and record the new
   APK hash. Verify every added artifact against its Holo package hash.
2. Verify the R7f cleanup, app UID/free space, no matching process, and rooted
   rollback paths. Stage the new exact R7g scope with 161 Holo packages, both
   Debian assets, and the same public seed/mode/PRoot inputs.
3. Run the unchanged archive extractor and require its atomic candidate.
4. Run the unchanged guest closure with the real public seed bound at
   `/opt/nova-steam`. Require pacman completion, all 161 Holo entries, Debian
   GTK2/audio paths, the guest marker, and `steamui.so` `ldd` with no
   `not found`.
5. Stop at the truthful closure result. Do not start Steam, supervisor,
   Termux:X11, or any UI/input/audio/network session in this run.
6. Document, commit, and push before attempting `steam --version`.

## Cleanup

After pulling bounded closure output and hashes, remove only the named R7g
app-private and remote trees. Verify no matching PRoot/pacman/bsdtar/Steam/
Termux:X11 process or staging directory remains, and confirm rooted rollback
paths are unchanged.

## Follow-up

If the 161-entry truthful closure passes, predeclare the supervisor
`steam --version` boundary. If it fails, retain the exact pacman/ldd result and
derive only the next missing provider from the same pinned metadata.
