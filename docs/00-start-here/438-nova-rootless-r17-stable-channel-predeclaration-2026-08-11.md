# Nova rootless R17 — stable ARM64 client-channel predeclaration — 2026-08-11

Run ID: `nova-rootless-r17-stable-channel-20260811T102817Z`
Sub-run: `R17-rootless-supervisor-steam-stable-channel`
Status: predeclared after the host package/channel investigation in [doc
437](437-nova-rootless-arm64-client-channel-host-result-2026-08-11.md).

## Hypothesis

R15 and R16 used the seeded `package/beta` selector and therefore updated to
Valve's current public-beta ARM64 build `1786141909`. That build reaches the
X11 update window but exits at the SteamUI module handoff requesting absent
`bin/vgui2_s.dll`. Valve's stable ARM64 manifest remains at build `1785799196`,
which is the build used by the successful SteamClientTermux SteamUI logs.

R17 tests whether selecting the stable upstream client pairing crosses the
handoff without changing the rootless loader, filesystem aliasing, SteamUI,
display, or runtime variables.

## Controlled change

Keep the complete R16 profile unchanged, including the client-root CWD:

```text
/bin/sh -c 'cd /opt/nova-steam && exec /opt/nova-steam/steamrtarm64/steam --version'
```

Before staging the copied R16 client input, remove only:

```text
steam-client/package/beta
```

An absent beta selector is the standard stable-channel selection. Do not add
or rename `bin/vgui2_s.dll`, do not patch SteamUI, and do not alter the
supervisor's PRoot arguments or library path. Do not add `-gamepadui`, Steam
Runtime 4, `/proc/net`, Proton, login, game launch, authentication access,
Gamescope, or AHardwareBuffer variables.

## Device and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Code/assets under test: current pushed branch at predeclaration time;
  no launcher or runtime code change is part of R17.
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `5b27f2c6b38fb3ecebda6d4efe028b6e3086a32775874da48ea08ad8e257a682`.
- Bootstrap manifest: 18 payload entries, SHA-256
  `8d9befcdbaa1cb4aa918677d021f0cfe63185accc1f85d5c9e59a7ea8008dab6`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Holo package manifest: 161 entries, SHA-256
  `f3f46d90ab246dd799cb22d75cbb219ff3c5d8e62f1ce6f53c3847c74238d83f`.
- Debian external manifest: two entries, SHA-256
  `00c06ef768b5c86f67a9e46bbd4f661b2e8e8344d81457af6986d5f9a8ee7354`.
- Seed input: the same 51-file client tree used by R16, with only
  `package/beta` removed in the R17 staging copy. Key seed hashes remain:
  `steamrtarm64/steam`
  `cb5ba36e6462b6ad8901c9fe51a4df54933669de6c354754399f9ab4c7e5fc85`;
  `steamrtarm64/steamui.so`
  `972b2290aef95771fc716dbc0e4cf8d27bd846e3b738a596148fbe67b6346ad0`;
  `steamrtarm64/steamwebhelper`
  `3901a2af2b9348a4b6381162c3913d607fcf7e959996b8388fd571f4a0d1cd8f`.
- Stable manifest: `https://client-update.steamstatic.com/steam_client_linuxarm64`,
  version `1785799196`, SHA-256
  `a2ad912ef6f150d373504a80c79f95210f8ed4ddbc42071593d0a120eb96ca91`.
- Stable ARM64 VZ package:
  `bins_linuxarm64_linuxarm64.zip.vz.11771d05f91515ca5337eeb9baf835098df71d3a_60815678`,
  SHA-256
  `38dad8316435b1aea099f16c4eefb5da1fd57faa59fafe659945879ad5ae5148`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r17-stable-channel-20260811T102817Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r17/
/data/data/com.termux/files/home/.nova-rootless/
```

Preserve and verify the rooted rollback paths:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Procedure and acceptance

1. Reread the complete lifecycle contract and establish a fresh process,
   listener, app, remote-scope, and rollback baseline.
2. Install/hash-verify the pinned APK and start fresh app-UID Termux:X11 on
   `127.0.0.1:6077`. Recreate the unchanged R16 archive extraction, Holo
   package closure, and supervisor preflight in `files/r17/`. Verify the
   staged client has no `package/beta` before launching Steam.
3. Run the declared stable-channel command with fresh stdout/stderr,
   supervisor, Steam, and package-state capture. Observe long enough to
   distinguish successful SteamUI/webhelper startup from a fresh fatal or
   timeout. A pass is crossing the `vgui2` handoff and reaching a precise
   SteamUI/X11 state; it is not a login, game, WSI, or compositor result.
4. Run the exact-scope cleanup helper, stop X11, and remove only the three R17
   scopes. Verify no Steam/SteamUI/webhelper/PRoot/helper process remains, no
   `:6077` listener remains, rollback paths remain present, and free space
   recovers.

## Interpretation

If stable reaches SteamUI, record the next SteamUI/X11 gate separately before
adding Runtime 4 or Proton. If it fails with the same module request, the
channel/build pairing is not sufficient and the next step is an upstream
installed-layout/loader trace—not an alias or view patch. If it fails later,
classify that new boundary and keep all later runtime/game variables deferred.
