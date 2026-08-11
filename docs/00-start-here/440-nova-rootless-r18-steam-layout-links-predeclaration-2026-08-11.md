# Nova rootless R18 — conventional Steam layout links predeclaration — 2026-08-11

Run ID: `nova-rootless-r18-steam-layout-20260811T105432Z`; sub-run:
`R18-rootless-supervisor-steam-stable-layout-links`.

Status: predeclared after [R17 result](439-nova-rootless-r17-stable-channel-result-2026-08-11.md).

## Hypothesis

R17 selected Valve's stable ARM64 client and crossed the earlier
`bin/vgui2_s.dll` fatal, but stalled after the update window before spawning
`steamwebhelper` or producing a Steam frame. The clean SteamClientTermux
reference at revision `8d14c10195b34fe2714ba59df1680df27a852532` creates the
traditional ARM64 `.steam` links before launching the same native client
family:

```text
$HOME/.steam/steam        -> /opt/nova-steam
$HOME/.steam/sdkarm64     -> /opt/nova-steam/linuxarm64
$HOME/.steam/bin64        -> /opt/nova-steam/steamrt64
$HOME/.steam/bin32        -> /opt/nova-steam/steamrt32
$HOME/.steam/steamrtarm64 -> /opt/nova-steam/steamrtarm64
```

R18 tests whether those conventional links are the missing installed-layout
contract in Nova's rootless profile. It does not create `bin/vgui2_s.dll`,
rename a shared object, patch SteamUI, or change the display/compositor path.

## Controlled change

Keep the complete R17 profile fixed:

- stable Valve ARM64 client channel, with `package/beta` absent;
- Holo ARM64 glibc rootfs and the same 161-package closure plus two external
  assets;
- app-UID PRoot supervisor and the same loader/bootstrap assets;
- fresh Termux:X11 at `127.0.0.1:6077`, guest display `:77`;
- resolver and inherited Android network path;
- client-root working directory and declared command:

  ```text
  /bin/sh -c 'cd /opt/nova-steam && exec /opt/nova-steam/steamrtarm64/steam --version'
  ```

The only R18 mutation after `prepare_state` is creation of the four
additional `.steam` links (`sdkarm64`, `bin64`, `bin32`, and
`steamrtarm64`) inside the fresh app-owned R18 home. The existing
`.steam/steam` link is retained. The links point at the client root exposed
inside the guest and are created with `ln -sfn`; no client files are aliased
or modified.

Do not add `-gamepadui`, Steam Runtime 4, Proton, login/authentication
operations, game launch, `/proc/net` shadows, route wrappers, audio changes,
Gamescope, AHardwareBuffer, or any SteamUI/OOBE patch.

## Device and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `5b27f2c6b38fb3ecebda6d4efe028b6e3086a32775874da48ea08ad8e257a682`.
- Stable manifest URL:
  `https://client-update.steamstatic.com/steam_client_linuxarm64`.
- Stable version: `1785799196`.
- Stable manifest SHA-256:
  `a2ad912ef6f150d373504a80c79f95210f8ed4ddbc42071593d0a120eb96ca91`.
- Stable ARM64 VZ payload:
  `bins_linuxarm64_linuxarm64.zip.vz.11771d05f91515ca5337eeb9baf835098df71d3a_60815678`.
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
/data/local/tmp/nova-rootless-r18-steam-layout-20260811T105432Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r18/
/data/data/com.termux/files/home/.nova-rootless/
```

Preserve and verify the rooted rollback paths:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Procedure and acceptance

1. Read the full lifecycle contract, then establish a fresh process, listener,
   APK, remote-scope, app-scope, and rollback baseline. Do not reuse R17
   logs, screenshots, sockets, readiness, or state.
2. Install/hash-verify the pinned APK, start fresh X11, and stage the same
   R17 rootfs archive, PRoot closure, Holo package closure, external assets,
   resolver, and stable-client seed under `files/r18/`. Verify the seed has no
   `package/beta`; normalize only the known executable/link modes required by
   the previously validated setup.
3. Run the same extraction, closure, and supervisor preflight. Create and
   verify only the five `.steam` links listed above inside the fresh R18 home.
4. Launch the stable command with fresh wrapper, supervisor, Steam, SteamUI,
   and X11 capture. Observe through updater handoff and post-update startup.
5. Acceptance is a fresh `steamwebhelper` startup plus SteamUI logs and a
   correlated visible X11 frame. A new precise failure is still useful, but
   it must be classified at the Steam client, webhelper, SteamUI, X11, or
   presentation boundary.
6. Stop X11, terminate the exact R18 process tree, remove only the three R18
   scopes, and verify no matching process/listener remains and both rollback
   paths are present. Do not read, copy, or export Steam authentication data.

R18 is not a login, game, Proton, Runtime 4, audio, controller, network
reachability, Gamescope, AHardwareBuffer, or product-packaging acceptance.
