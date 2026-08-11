# Nova rootless R28 — rooted launch-environment/library-path parity predeclaration — 2026-08-11

Run ID: `nova-rootless-r28-rooted-launch-env-20260811T135325Z`;
sub-run: `R28-rootless-supervisor-rooted-launch-environment`.

Status: predeclared after R27 reproduced the `vgui2_s` fatal with the current
rooted public client and rooted nested client-root/HOME/cwd mapping. R28 keeps
that layout fixed and carries over only the rooted direct-launch environment
that the current rootless supervisor does not set.

## Hypothesis

The rooted launcher does more than select the nested client path. Before
starting Steam, `android/nova-lab/device/nova-termux-x11-steam-client.sh`
sets:

```text
USER=steam
LOGNAME=steam
LANG=C
LC_ALL=C
XDG_RUNTIME_DIR=/tmp/nova-steam-runtime
PATH=$STEAM_ROOT/steam-runtime-steamrt-arm64/bin:$STEAM_ROOT/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/bin:/usr/bin:/bin
LD_LIBRARY_PATH=$STEAM_ROOT/steamrtarm64:$STEAM_ROOT/lib/aarch64-linux-gnu:/usr/lib:$STEAM_ROOT/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu:$STEAM_ROOT/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu/pulseaudio
```

R27 kept the nested path but inherited the rootless supervisor's
`USER=nova`, `LOGNAME=nova`, `XDG_RUNTIME_DIR=/run/nova`, and minimal
`PATH`; it also did not explicitly pass the rooted SteamRT-first library
order. A missing library search path could make Steam report the generic
`Could not load module 'bin/vgui2_s.dll'` even when `vgui2_s.so` is present.

R28 changes only those environment values. It keeps the rootless TCP X11
transport, so `DISPLAY` remains `127.0.0.1:77` rather than the rooted
launcher’s `:0`. It does not add `LD_PRELOAD`, a guessed alias, a Runtime 4
shadow, a SteamUI patch, or a UID/GID change; PRoot remains the same `-0`
app-UID supervisor. This isolates environment/library resolution from the
separate guest-identity and preload hypotheses.

## Fixed artifacts and layout

Recreate the same sanitized current rooted public tree used by R26/R27 from:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs/opt/nova-steam/home/.local/share/Steam
```

Require the same public archive and selected hashes before staging:

```text
archive_bytes=3447515136
archive_sha256=4c62a8e35144b653864c31d84e682814a82384c3746001293e019d98bde25288
sanitized_file_count=19557
package/beta sha256=ef339938036ee25c4f533210a35791d5faf9f69dcbc72cce173263005500f9e4
installed_manifest sha256=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
steamrtarm64/steam sha256=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so sha256=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so sha256=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e3b5bd77db4b10c87e
```

Use the R26/R27 allowlist and exclusions. Do not read or stage
`appcache/`, `config/`, `logs/`, `steamapps/`, `userdata/`, `.crash`,
`local.vdf`, `update_hosts_cached.vdf`, `ssfn*`, `loginusers.vdf`,
`steam.token`, `user*.vdf`, `localconfig.vdf`, or `sharedconfig.vdf`.

Stage the public tree at the same rooted nested guest path:

```text
/opt/nova-steam/home/.local/share/Steam
```

Use the same fresh nested `.steam` links, Holo ARM64 rootfs, 161-package
UI/audio closure, direct X11, inherited Android network, input/audio/storage,
and app-owned state. Preserve the rooted rollback paths and do not overwrite
the current rooted runtime.

## Changed environment and exact launch

After the existing supervisor has entered PRoot and passed its preflight, the
guest shell must export:

```text
HOME=/opt/nova-steam/home
USER=steam
LOGNAME=steam
LANG=C
LC_ALL=C
XDG_RUNTIME_DIR=/tmp/nova-steam-runtime
PATH=/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/bin:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/bin:/usr/bin:/bin
LD_LIBRARY_PATH=/opt/nova-steam/home/.local/share/Steam/steamrtarm64:/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu:/usr/lib:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu/pulseaudio
```

Create the disposable guest runtime directory, change to the nested client
root, and run the unchanged client flags:

```text
/bin/sh -c 'export HOME=/opt/nova-steam/home; export USER=steam; export LOGNAME=steam; export LANG=C; export LC_ALL=C; export XDG_RUNTIME_DIR=/tmp/nova-steam-runtime; export PATH=/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/bin:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/bin:/usr/bin:/bin; export LD_LIBRARY_PATH=/opt/nova-steam/home/.local/share/Steam/steamrtarm64:/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu:/usr/lib:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu/pulseaudio; mkdir -p "$XDG_RUNTIME_DIR"; cd /opt/nova-steam/home/.local/share/Steam; exec /opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui'
```

The following remain fixed and are not part of R28:

```text
DISPLAY=127.0.0.1:77
LD_PRELOAD=unset
PRoot binary, loader, `-0`, `/proc`, resolver, and app UID
Steam client bytes, flags, nested links, and working directory
```

## Device scope and acceptance

Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, `arm64-v8a`.

```text
/data/local/tmp/nova-rootless-r28-rooted-launch-env-20260811T135325Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r28/
/data/data/com.termux/files/home/.nova-rootless/
```

Reread the lifecycle contract, run exact-scope cleanup before launch, and
capture fresh preflight, environment/argv/cwd evidence, X11 PID/listener,
Steam/client/SteamUI/webhelper logs, and a screenshot. Pull fresh evidence
before teardown. The positive boundary is a loaded `steamui.so`, followed by
a visible Steam frame and fresh `steamwebhelper`.

If R28 crosses `vgui2_s`, the missing variable was in the rooted launch
environment; preserve a parameterized rootless environment contract and then
isolate any next UI boundary. If it repeats the fatal, close the environment
hypothesis and test guest UID/GID or a read-only loader trace separately. Do
not add a guessed alias, preload, Runtime 4, Proton, Gamescope, or SteamUI
patch based only on R28.

No Steam authentication secret may be read, copied, backed up, or exported.
