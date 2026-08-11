# Nova rootless R19 — no-version native Steam lifecycle predeclaration — 2026-08-11

Run ID: `nova-rootless-r19-no-version-steam-lifecycle-20260811T111816Z`; sub-run:
`R19-rootless-supervisor-steam-stable-no-version`.

Status: predeclared after the host launch-contract audit in [doc
444](444-nova-rootless-steamclienttermux-launch-contract-host-result-2026-08-11.md).

## Hypothesis

The successful SteamClientTermux ARM64 sessions launch the native Steam client
without `--version`. Nova R17 and R18b used `--version` to probe the module
handoff, so the diagnostic argument remains an uncontrolled lifecycle
variable. R19 tests whether the ordinary client invocation reaches
`steamwebhelper` and SteamUI on Nova's stable/no-link rootless baseline.

## Controlled change

Keep R17's stable/no-link profile and every setup/display variable unchanged:

- Valve stable ARM64 client, with `package/beta` absent and version
  `1785799196`;
- Holo ARM64 rootfs, the 161-package closure, and two external assets;
- app-UID PRoot, loader, resolver, `/dev`/`/proc` binds, and app-owned state;
- fresh Termux:X11 at `127.0.0.1:6077`, guest display `:77`;
- no additional `sdkarm64`, `bin64`, `bin32`, or `steamrtarm64` links beyond
  the supervisor's existing `.steam/steam` link;
- no SteamUI patch, route shadow, PulseAudio change, Runtime 4, Proton, game,
  authentication, Gamescope, or AHardwareBuffer variable.

The only controlled change is the declared command:

```text
/bin/sh -c 'cd /opt/nova-steam && exec /opt/nova-steam/steamrtarm64/steam'
```

Do not add SteamClientTermux's `-no-cef-sandbox`, `-cef-disable-gpu`,
`-chromeosnopreallocate`, or `-noverifyfiles` in R19; test those separately if
the no-version lifecycle crosses the current boundary.

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

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r19-no-version-steam-lifecycle-20260811T111816Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r19/
/data/data/com.termux/files/home/.nova-rootless/
```

Preserve and verify:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Procedure and acceptance

1. Read the full lifecycle contract and establish a fresh process, listener,
   APK, scope, and rollback baseline. Do not reuse R17/R18b process, logs,
   screenshots, sockets, readiness, or Steam state.
2. Stage the verified inputs under `files/r19/`, remove and verify absence of
   `package/beta`, extract the rootfs, apply the unchanged closure, and run
   supervisor preflight with a fresh free-space marker.
3. Start fresh X11 and run the no-version command. Capture fresh wrapper,
   Steam bootstrap, SteamUI/webhelper, and X11 evidence. Observe through the
   ordinary post-update lifecycle rather than stopping at updater exit.
4. A pass requires a fresh `steamwebhelper` process/log and a correlated
   visible Steam frame. A precise fatal or later boundary is still a useful
   result, but it must be classified without adding another variable.
5. Stop X11, terminate only the exact R19 process tree, remove the three R19
   scopes, and verify no matching process/listener remains and rollback paths
   remain present. Never read, copy, or export Steam authentication data.
