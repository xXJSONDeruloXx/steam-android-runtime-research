# Nova rootless R7e — `steamui.so` dependency diagnostic predeclaration — 2026-08-11

Run ID: `nova-rootless-r7e-steamui-ldd-diagnostic-20260811T062455Z`
Sub-run: `R7e-steamui-ldd-diagnostic`
Status: predeclared; the failed R7d tree was removed before launch.

## Controlled change

R7d proved that the public `steamui.so` can be probed after executable-mode
normalization, but the normal closure helper correctly withheld its atomic
candidate because the probe found one or more missing libraries. R7e keeps the
same Holo archive, 103-package closure, Debian assets, PRoot absolute paths,
`libtalloc` links, public seed, and seed modes. It changes only the bind used
for the closure helper: an empty app-owned client directory suppresses the
helper's automatic `steamui.so` gate so the complete Holo closure can activate.

After that candidate is activated, a separate fresh PRoot command binds the
real public seed at `/opt/nova-steam` and captures complete guest-side
`/usr/bin/ldd /opt/nova-steam/steamrtarm64/steamui.so` output. This is a
read-only diagnostic. It does not add packages, patch SteamUI, start Steam,
start Termux:X11, or copy authentication data.

## Device, branch, and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `e4117a1` (`docs: record rootless R7d SteamUI dependency boundary`).
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
/data/local/tmp/nova-rootless-r7e-steamui-ldd-diagnostic-20260811T062455Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r7e-steamui-ldd-diagnostic-20260811T062455Z/
  rootfs-archive/system.rootfs.zst
  guest-rootfs/
  guest-rootfs-closure/
  state/
  proot/
  scripts/
  steam-client/
  steam-client-empty/
  steamui-packages/
```

Rooted rollback paths remain outside scope:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Run sequence and acceptance

1. Verify the new exact scope is absent, no matching process remains, free
   space/app UID are sufficient, and rooted rollback paths are present.
2. Restage and hash-verify the same public artifacts. Recreate the two
   `libtalloc` links and four seed executable-mode changes. Create an empty
   `steam-client-empty/` directory only for the closure bind.
3. Run the unchanged archive extractor and require its atomic candidate.
4. Run the unchanged guest closure with `NOVA_ROOTLESS_STEAM_CLIENT` set to
   the empty directory. Require all 103 packages, both Debian assets, the
   guest marker, and an atomic `guest-rootfs-closure/` candidate.
5. With the activated closure, invoke PRoot directly with the real public
   seed bound at `/opt/nova-steam` and capture the complete `ldd` output and
   exit code. Do not run `steam`, `steamwebhelper`, or any UI process.
6. Stop at the diagnostic result, classify each missing library by guest
   package/provider, and document, commit, and push before changing the
   package closure.

## Cleanup

After pulling only the bounded `ldd` output, remove the named R7e app-private
and remote trees. Verify no matching PRoot/pacman/bsdtar/Steam/Termux:X11
process or staging directory remains, and confirm rooted rollback paths are
unchanged.

## Follow-up

Only libraries shown missing by the captured guest `ldd` may be considered for
a narrowly scoped closure addition. After a truthful seed-bound closure pass,
predeclare the supervisor `steam --version` boundary, then Termux:X11
SteamUI. SteamRT3C and Runtime 4/Proton 11 remain independent later tracks.
