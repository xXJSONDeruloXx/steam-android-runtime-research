# Nova rootless R23 — matched Valve `libavutil.so.60` predeclaration — 2026-08-11

Run ID: `nova-rootless-r23-matched-libavutil-steamui-20260811T120951Z`;
sub-run: `R23-rootless-supervisor-matched-libavutil`.

Status: predeclared; the R22 ABI boundary and the host-only provider audit are
closed in [docs 452](452-nova-rootless-r22-noverifyfiles-result-2026-08-11.md)
and [453](453-nova-rootless-steam-media-provider-host-audit-2026-08-11.md).

## Hypothesis

The R22 raw ARM64 seed omitted the client-side `libavutil.so.60`, so the Holo
closure supplied an ABI-incompatible provider. The completed Valve ARM64
bootstrap contains a provider beside the same `libvideo.so` that exports
`av_malloc_tracked`, `av_mallocz_tracked`, and `av_register_malloc` under
`LIBAVUTIL_60`. Because `libvideo.so` declares `RUNPATH=$ORIGIN`, staging that
one provider in the client directory should cross the current `steamui.so`
load boundary without a preload adapter or supervisor change.

## Controlled change

Keep the R22 profile unchanged:

- stable Valve ARM64 seed, `package/beta` absent, build `1785799196`;
- Holo ARM64 rootfs and the 161-package closure;
- app-UID PRoot, resolver, `/dev` and `/proc` binds, and app-owned state;
- fresh Termux:X11 at `127.0.0.1:6077`, guest display `:77`;
- only `$HOME/.steam/steam -> /opt/nova-steam`;
- no top-level client symlink, no other launch flags, Runtime 4, Proton,
  route/audio helper, SteamUI patch, DLL alias, Gamescope, AHardwareBuffer,
  game, or authentication variable.

Add exactly one client artifact before launch:

```text
source:
  android/nova-lab/build/steam-bootstrap/home/.local/share/Steam/steamrtarm64/libavutil.so.60
destination:
  <R23 app-owned client tree>/steamrtarm64/libavutil.so.60
size: 887984
sha256: 606c4eb6c7ca987f5b71a4cd0a60d5eeefb11fe97fd60c69c4dfca8afca42f9a
```

Do not add the repository's `libffmpeg-avutil-compat.so`, change
`LD_PRELOAD`, change the Holo manifest, or add an unversioned symlink during
this run. The provider source is an official Valve-completed bootstrap
artifact from public-beta build `1785979614`; its paired `libvideo.so` has the
same SHA-256 as the stable R22 client. If this crosses SteamUI, acquire an
exact stable-build completion before treating the provider as product input.

Launch the same diagnostic command:

```text
/bin/sh -c 'cd /opt/nova-steam && exec /opt/nova-steam/steamrtarm64/steam -noverifyfiles'
```

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

The R23 input is a fresh copy of the R22 host input plus the one verified
provider; do not reuse R22 state, logs, screenshot, socket, readiness, or
process.

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r23-matched-libavutil-steamui-20260811T120951Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r23/
/data/data/com.termux/files/home/.nova-rootless/
```

Preserve and verify:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Procedure and acceptance

1. Read the lifecycle contract, establish a fresh baseline, verify the
   attached device, free space, app UID, APK, rollback paths, and exact R23
   cleanup scope.
2. Stage the R22 inputs into the new app-owned scope, verify the raw seed and
   rootfs hashes, copy only the matched client `libavutil.so.60`, and record
   its hash in the preflight log.
3. Run unchanged rootfs extraction, 161-package closure, and supervisor
   preflight. Require the client-side provider to be a regular file at the
   exact destination and the Holo closure to remain unchanged.
4. Start fresh Termux:X11 and run only the `-noverifyfiles` command. Capture
   fresh updater, Steam, SteamUI/webhelper, X11, process, and screenshot
   evidence. A successful `steamui.so` load or a new client boundary is useful;
   a visible Steam frame is required before calling the UI gate passed.
5. Terminate only the exact R23 tree, remove the three R23 scopes, and verify
   no matching process or listener remains. Confirm both rooted rollback paths
   still exist. Never read, copy, or export Steam authentication data.

## Decision rule

If the client loads, record the next first failure without adding another
variable. If it still resolves Holo `libavutil.so.60`, classify the loader
search path before considering an environment change. If it reaches SteamUI but
fails elsewhere, preserve the provider as a measured closure input and
predeclare the next smallest change separately.
