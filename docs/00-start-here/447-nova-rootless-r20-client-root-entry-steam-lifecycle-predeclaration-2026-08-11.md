# Nova rootless R20 — client-root Steam entry-point predeclaration — 2026-08-11

Run ID: `nova-rootless-r20-client-root-entry-steam-lifecycle-20260811T113042Z`;
sub-run: `R20-rootless-supervisor-steam-client-root-entry`.

Status: predeclared after the R19 result in [doc
446](446-nova-rootless-r19-no-version-steam-lifecycle-result-2026-08-11.md).

## Hypothesis

The audited SteamClientTermux launcher executes the native client from the
Steam client root as `$client/steam`. R19 used the equivalent-looking
`steamrtarm64/steam` entry point and stopped after the updater logged
`Update complete, launching...`. R20 tests whether the client-root entry point
changes the post-update relaunch behavior.

## Controlled change

Keep R19's stable/no-link rootless filesystem, provisioning, display, and
network profile unchanged:

- Valve stable ARM64 client with `package/beta` absent;
- Holo ARM64 rootfs and the 161-package closure;
- app-UID PRoot, loader, resolver, `/dev` and `/proc` binds, and app-owned
  state;
- fresh Termux:X11 at `127.0.0.1:6077`, guest display `:77`;
- only `$HOME/.steam/steam -> /opt/nova-steam`;
- no `--version`, no `-no-cef-sandbox`, no `-cef-disable-gpu`, no
  `-chromeosnopreallocate`, no `-noverifyfiles`, no Runtime 4, Proton, route
  shadow, PulseAudio change, SteamUI patch, DLL alias, Gamescope,
  AHardwareBuffer, game, or authentication variable.

The only controlled change is the native command:

```text
/bin/sh -c 'cd /opt/nova-steam && exec /opt/nova-steam/steam'
```

The R19 command was:

```text
/bin/sh -c 'cd /opt/nova-steam && exec /opt/nova-steam/steamrtarm64/steam'
```

If R20 reaches SteamUI, the sibling launch flags will be tested in separate
predeclared profiles. Do not import the sibling's PRoot, Runtime 4, route,
audio, or SteamUI compatibility changes in R20.

## Device and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `5b27f2c6b38fb3ecebda6d4efe028b6e3086a32775874da48ea08e257a682`.
- Stable manifest URL:
  `https://client-update.steamstatic.com/steam_client_linuxarm64`.
- Stable version: `1785799196`.
- Stable manifest SHA-256:
  `a2ad912ef6f150d373504a80c79f95210f8ed4ddbc42071593d0a120eb96ca91`.
- Stable VZ SHA-256:
  `38dad8316435b1aea099f16c4eefb5da1fd57faa59fafe659945879ad5ae5148`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.
- Fresh host staging source: `/tmp/nova-r10-input-final.LnvYB3`.

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r20-client-root-entry-steam-lifecycle-20260811T113042Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r20/
/data/data/com.termux/files/home/.nova-rootless/
```

Preserve and verify:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Procedure and acceptance

1. Read the full lifecycle contract. Establish a fresh process, listener,
   APK, scope, and rollback baseline; do not reuse R19's process, logs,
   screenshot, socket, readiness, or app state.
2. Stage the verified inputs under `files/r20/`, remove and verify absence of
   `package/beta`, extract the rootfs, apply the unchanged closure, and run
   supervisor preflight with a fresh free-space marker.
3. Start fresh X11 and run the client-root command. Observe the normal
   updater and post-update lifecycle. Capture fresh wrapper, bootstrap,
   SteamUI/webhelper, and X11 evidence.
4. A pass requires a fresh `steamwebhelper` process/log and a correlated
   visible Steam frame. A precise later failure is useful, but no extra
   launch flag may be added during this run.
5. Stop X11, terminate only the exact R20 process tree, remove the three R20
   scopes, and verify no process/listener remains and rollback paths remain
   present. Never read, copy, or export Steam authentication data.
