# Nova rootless R24 — matched Valve media suite predeclaration — 2026-08-11

Run ID: `nova-rootless-r24-matched-media-suite-steamui-20260811T122724Z`;
sub-run: `R24-rootless-supervisor-matched-media-suite`.

Status: predeclared after the R23 result in [doc
455](455-nova-rootless-r23-matched-libavutil-result-2026-08-11.md) and the
host audit in [doc 456](456-nova-rootless-steam-media-suite-host-audit-2026-08-11.md).

## Hypothesis

R23 proved that the single Valve `libavutil.so.60` crosses the original
`libvideo.so` allocator boundary but cannot be mixed with Holo's FFmpeg. The
completed Valve ARM64 bootstrap supplies a seven-file `$ORIGIN` media family
that should keep `libvideo.so`, FFmpeg, and `libvpx` on one ABI set.

## Controlled change

Keep the R22/R23 profile unchanged:

- stable Valve ARM64 seed, `package/beta` absent, build `1785799196`;
- Holo ARM64 rootfs and the 161-package closure;
- app-UID PRoot, resolver, `/dev` and `/proc` binds, and app-owned state;
- fresh Termux:X11 at `127.0.0.1:6077`, guest display `:77`;
- only `$HOME/.steam/steam -> /opt/nova-steam`;
- no top-level client symlink, no other launch flags, Runtime 4, Proton,
  route/audio helper, SteamUI patch, DLL alias, Gamescope, AHardwareBuffer,
  game, or authentication variable.

Stage exactly these seven regular files in the raw client's
`steamrtarm64/` directory:

| File | Size | SHA-256 |
|---|---:|---|
| `libavcodec.so.62` | 2,781,800 | `f47a44246510d6aea528959046ab81496b610fd63d5c67abfc5da1e5ac1c17db` |
| `libavfilter.so.11` | 162,952 | `459d3433f802ad071c3ef8229bb1f19dbf7700d31a5c5f805fa02996758609e7` |
| `libavformat.so.62` | 1,024,816 | `c0383fdc0ee6ba7dc9d479d8fd8dd26f4ab38350d19f6555fbbc799f718cc025` |
| `libavutil.so.60` | 887,984 | `606c4eb6c7ca987f5b71a4cd0a60d5eeefb11fe97fd60c69c4dfca8afca42f9a` |
| `libswresample.so.6` | 88,464 | `d6cc3c9cc68bde026869491967784dd2dc89bfb328b6dd27ec016e53b8149bb3` |
| `libswscale.so.9` | 514,616 | `ef6354a7bad5aea551ee7ee6876e1ae195b00fb853ce6a070f3527c23bc6291a` |
| `libvpx.so.6` | 2,112,096 | `0e02a468d8647d6ede477cee83d8d9840590d6024def250dc63c4350f8017d37` |

The source is the ignored completed Valve bootstrap at
`android/nova-lab/build/steam-bootstrap/home/.local/share/Steam/steamrtarm64/`.
Do not add the repository's `libffmpeg-avutil-compat.so`, change
`LD_PRELOAD`, modify the Holo package manifest, add an unversioned symlink, or
copy any other completed-bootstrap file during this run.

Launch exactly:

```text
/bin/sh -c 'cd /opt/nova-steam && exec /opt/nova-steam/steamrtarm64/steam -noverifyfiles'
```

The provider source is from public-beta completed build `1785979614`, while
the raw R24 client is stable build `1785799196`. The paired `libvideo.so` hash
is identical. A pass is an ABI/lifecycle experiment; exact stable-build
completion provenance remains a follow-up before product packaging.

## Device and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `5b27f2c6b38fb3ecebda6d4efe028b6e3086a32775874da48ea08e257a682`.
- Stable manifest SHA-256:
  `a2ad912ef6f150d373504a80c79f95210f8ed4ddbc42071593d0a120eb96ca91`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.

Use a fresh copy of the R22 host inputs, with `package/beta` absent and only
the seven listed files added to `steamrtarm64/`. Do not reuse R23 state, logs,
screenshots, socket, readiness, or process.

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r24-matched-media-suite-steamui-20260811T122724Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r24/
/data/data/com.termux/files/home/.nova-rootless/
```

Preserve and verify:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Procedure and acceptance

1. Read the lifecycle contract and establish a fresh process, listener, APK,
   free-space, app-UID, scope, and rollback baseline.
2. Stage the verified R22 inputs and exactly the seven media files into the
   fresh app-owned R24 scope. Verify `package/beta` is absent, the seven
   regular-file hashes match, and `libvideo.so` is unchanged.
3. Run unchanged rootfs extraction, 161-package closure, and supervisor
   preflight. Keep the Holo manifest and supervisor hashes unchanged.
4. Start fresh Termux:X11 and run only the `-noverifyfiles` command. Capture
   fresh bootstrap, SteamUI/webhelper, X11, process, and screenshot evidence.
   A successful `steamui.so` load is the first target; a visible Steam frame
   and fresh webhelper are required for a UI pass.
5. Terminate only the exact R24 tree, stop Termux:X11, remove the three R24
   scopes, and verify no matching process/listener remains. Confirm rollback
   paths remain present. Never read, copy, or export Steam authentication data.

## Decision rule

If SteamUI loads, record the next first lifecycle failure without changing the
media family. If it still resolves a Holo FFmpeg object, classify loader search
order before changing the environment. If another missing client dependency
appears, document it and audit the completed bootstrap before staging anything
else.
