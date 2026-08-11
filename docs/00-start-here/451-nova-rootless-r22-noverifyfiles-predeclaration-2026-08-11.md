# Nova rootless R22 — `-noverifyfiles` launch-flag predeclaration — 2026-08-11

Run ID: `nova-rootless-r22-noverifyfiles-steam-lifecycle-20260811T115353Z`;
sub-run: `R22-rootless-supervisor-steam-noverifyfiles`.

Status: predeclared after the R19 and R21 updater-handoff results in [docs
446](446-nova-rootless-r19-no-version-steam-lifecycle-result-2026-08-11.md)
and [450](450-nova-rootless-r21-client-root-symlink-result-2026-08-11.md).

## Hypothesis

The successful SteamClientTermux launch includes `-noverifyfiles`. R19 and
R21 reached the stable updater through the same native ARM64 executable and
then exited after `Update complete, launching...` without a post-update
Steam process. R22 tests whether disabling Steam's file-verification pass
changes the post-update relaunch boundary.

## Controlled change

Keep the R19/R21 stable/no-link rootless profile unchanged:

- Valve stable ARM64 client with `package/beta` absent;
- Holo ARM64 rootfs and the 161-package closure;
- app-UID PRoot, loader, resolver, `/dev` and `/proc` binds, and app-owned
  state;
- fresh Termux:X11 at `127.0.0.1:6077`, guest display `:77`;
- only `$HOME/.steam/steam -> /opt/nova-steam`;
- no top-level client symlink, no `--version`, no `-no-cef-sandbox`, no
  `-cef-disable-gpu`, no `-chromeosnopreallocate`, no Runtime 4, Proton,
  route/audio helper, SteamUI patch, DLL alias, Gamescope, AHardwareBuffer,
  game, or authentication variable.

The only controlled change is the one target-derived flag:

```text
/bin/sh -c 'cd /opt/nova-steam && exec /opt/nova-steam/steamrtarm64/steam -noverifyfiles'
```

Do not add the remaining sibling flags during R22. A pass still requires a
fresh `steamwebhelper` process/log and a correlated visible Steam frame.

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
/data/local/tmp/nova-rootless-r22-noverifyfiles-steam-lifecycle-20260811T115353Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r22/
/data/data/com.termux/files/home/.nova-rootless/
```

Preserve and verify:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Procedure and acceptance

1. Read the full lifecycle contract. Establish a fresh process, listener,
   APK, scope, and rollback baseline; do not reuse R21's process, logs,
   screenshot, socket, readiness, or app state.
2. Stage the verified inputs under `files/r22/`, remove and verify absence of
   `package/beta`, extract the rootfs with the app bootstrap, apply the
   unchanged closure, and run supervisor preflight.
3. Start fresh X11 and run the exact command with only `-noverifyfiles`.
   Observe through updater installation and any post-update client handoff.
4. Capture fresh wrapper, bootstrap, SteamUI/webhelper, and X11 evidence. A
   precise updater, client, or module boundary is useful, but do not add
   another flag during this run.
5. Stop X11, terminate only the exact R22 process tree, remove the three R22
   scopes, and verify no process/listener remains and rollback paths remain
   present. Never read, copy, or export Steam authentication data.
