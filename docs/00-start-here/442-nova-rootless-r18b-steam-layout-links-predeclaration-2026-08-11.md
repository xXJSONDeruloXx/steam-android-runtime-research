# Nova rootless R18b — corrected conventional Steam layout links predeclaration — 2026-08-11

Run ID: `nova-rootless-r18b-steam-layout-20260811T110639Z`; sub-run:
`R18b-rootless-supervisor-steam-stable-layout-links`.

Status: predeclared as a fresh retry of the rejected setup in [doc
441](441-nova-rootless-r18-beta-seed-setup-rejection-2026-08-11.md). This is a
new run identity; no R18 logs, sockets, processes, or state will be reused.

## Hypothesis and controlled change

R17's stable ARM64 client crossed the prior `bin/vgui2_s.dll` fatal but
stalled before `steamwebhelper`. SteamClientTermux's clean revision
`8d14c10195b34fe2714ba59df1680df27a852532` creates these conventional links:

```text
$HOME/.steam/steam        -> /opt/nova-steam
$HOME/.steam/sdkarm64     -> /opt/nova-steam/linuxarm64
$HOME/.steam/bin64       -> /opt/nova-steam/steamrt64
$HOME/.steam/bin32       -> /opt/nova-steam/steamrt32
$HOME/.steam/steamrtarm64 -> /opt/nova-steam/steamrtarm64
```

R18b tests only that installed-layout hypothesis. Keep the stable ARM64
client channel, Holo/PRoot closure, app UID, resolver, X11 endpoint, client
root working directory, and launch command unchanged. Do not patch SteamUI,
create `vgui2_s.dll`, add Runtime 4/Proton, or change Gamescope,
AHardwareBuffer, audio, controller, networking, login, or game variables.

The corrected staging procedure must verify both before and after copying to
the app scope:

```text
test ! -e steam-client/package/beta
```

The only other run mutation is creation of the five links above in the fresh
app-owned home. The links are guest-path links; no client library is renamed
or modified.

## Device and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- APK SHA-256:
  `5b27f2c6b38fb3ecebda6d4efe028b6e3086a32775874da48ea08ad8e257a682`.
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

Declared command:

```text
/bin/sh -c 'cd /opt/nova-steam && exec /opt/nova-steam/steamrtarm64/steam --version'
```

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r18b-steam-layout-20260811T110639Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r18b/
/data/data/com.termux/files/home/.nova-rootless/
```

Preserve and verify:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Acceptance and teardown

1. Read the full lifecycle contract and establish a fresh process, listener,
   APK, scope, and rollback baseline.
2. Stage the verified rootfs, PRoot, package closure, stable-client seed, and
   app assets under the R18b scope. Remove `package/beta` before copying and
   verify its absence in the app-owned client tree.
3. Extract the rootfs, apply the unchanged closure, run preflight, create and
   verify the five `.steam` links, and record fresh free-space/provenance
   markers.
4. Run the declared command long enough to classify updater handoff and
   post-update startup. Require fresh `steamwebhelper`, SteamUI logs, and a
   correlated visible frame for a pass. A precise later failure is still a
   useful result.
5. Stop X11, terminate only the exact R18b tree, remove the three declared
   scopes, and verify no matching process/listener remains and rollback paths
   remain present. Never read, copy, or export Steam authentication data.
