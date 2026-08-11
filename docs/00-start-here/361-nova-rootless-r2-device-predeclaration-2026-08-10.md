# Nova rootless R2 device predeclaration — 2026-08-10

Run ID: `nova-rootless-r2-20260810T230711Z`
Status: predeclared; do not treat any prior rootless process, log, socket, or
Steam state as evidence for this run.

## Device and branch

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `957d70b8db443bb602d69a9eceeab47d26f109ac`.
- Rooted happy path: active signed-in Steam session on display `:0`; leave it
  running and do not read, copy, or mutate its authentication data.
- Rootless display: fresh Termux:X11 display `:77`, loopback TCP port `6077`.

## Exact rootless scope

All new mutable state must remain under the Nova app UID's private tree:

```text
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r2-20260810T230711Z/
  home/
  steam-client/
  state/
  proot/
  artifacts/
```

The Holo rootfs is the existing world-readable, read-only input:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
```

No rootless process may use `/data/local/tmp/nova-active-runtime`, the rooted
Steam home, rooted display `:0`, or the root-owned `termux-x11` process. A
rootless process match must include the R2 state/client paths or the exact
Termux display `:77` before it is eligible for cleanup.

## Selected artifacts

- APK: branch-built `android/nova-lab/build/nova-lab-debug.apk`; record its
  SHA-256 after build/install.
- PRoot: `proot_5.1.107.89_aarch64.deb`, SHA-256
  `ec9fe38c50cfd49dd31fe360ffbcc3124a945dc1ea16293a8a769303dd724f46`.
- `libandroid-shmem_0.7_aarch64.deb`, SHA-256
  `0da3a24d558b93c92bcf8d611e0826a99ff96e396b148e6cdf33b47c47c57ff6`.
- `libtalloc_2.4.3_aarch64.deb`, SHA-256
  `ac81ad623d74c209718b9f3acb2dd702cc8a88c431e820d212229910b4db29da`.
- Current Valve ARM64 Steam seed:
  `bins_linuxarm64_linuxarm64.zip.0f238017c65e844f71581d1fae8fb42f410e1032`,
  size `109767361`, SHA-256
  `1c1dd74e63db8d2d64445c7d6156f02e3b2719141e569b52e91b883d39592e82`.
- Current locally staged SteamRT3C archive remains a diagnostic bootstrap
  input, SHA-256 `f59e9541fb08f36097610f8cab07a0ed8f5f13e4a642b6fead87505aff979ab0`.
- Runtime 4 ARM64 and Proton 11 ARM64 must be downloaded/verified before the
  Runtime 4 gate; no local SteamRT3C archive may be mislabeled as Runtime 4.

## Run sequence

1. Verify the APK hash and install in place; do not uninstall the existing APK
   because that could remove app-owned rooted launcher files.
2. Create the R2 app-private directories and copy only the listed PRoot
   binaries/libs, clean Steam seed, Holo rootfs reference, and rootless assets.
3. Start Termux:X11 `:77` through the APK foreground-service bridge. Record a
   fresh Java/Termux log baseline and the exact Termux UID PID.
4. Run the app-UID proc-net shadow helper and record route/default-route status.
5. Extract the clean Steam seed into the app-owned client, bind it through the
   rootless supervisor, and run a fresh native Steam `--version`/client gate.
6. If the client reaches the login/OOBE boundary, use only a normal QR login;
   never import rooted Steam data or authentication secrets.
7. Download and verify official Runtime 4 ARM64/Proton 11 ARM64 through the
   normal Steam compatibility-tool path if the client reaches it; then run the
   `_v2-entry-point --verb=run -- /bin/true` gate before any game launch.
8. Capture fresh logs, process identity, route shadow, and display evidence.

The first R2 attempt is successful only if it proves the rootless process tree
and fresh Steam boundary, not merely that `127.0.0.1:6077` accepts a socket.
Audio/Pulse and game first-frame results remain separate classifications.

## Cleanup and rollback

On normal exit, interruption, or a failed gate:

- stop the exact Termux UID `:77` helper via the APK bridge;
- terminate only PRoot/Steam processes whose command lines contain the R2
  state/client paths;
- verify port `6077` is closed and display `:0`/rooted PID `26237` remains;
- pull fresh R2 logs before deleting them;
- remove only the R2 app-private tree and temporary pushed artifact paths.

If any exact-scope check is ambiguous, stop without cleaning broadly and record
the blocker. The rooted `/data/local/tmp/nova-active-runtime` is the rollback
baseline and must remain intact.
