# Nova rootless R27 — rooted nested-layout replay predeclaration — 2026-08-11

Run ID: `nova-rootless-r27-rooted-layout-20260811T133336Z`;
sub-run: `R27-rootless-supervisor-rooted-nested-layout`.

Status: predeclared after R26 reproduced the `vgui2_s` module boundary with
the current rooted public client. R27 changes only the client-root, HOME, and
working-directory mapping so the rootless guest sees the same nesting used by
the preserved rooted OOBE runtime.

## Hypothesis

The preserved rooted client that reached OOBE is launched from:

```text
/opt/nova-steam/home/.local/share/Steam
HOME=/opt/nova-steam/home
```

The rootless supervisor currently binds the public tree directly to
`/opt/nova-steam` and starts Steam with `HOME=/home/nova`, `cwd=/home/nova`,
and a flattened `.steam/steam -> /opt/nova-steam` link. R26 showed that
copying the current rooted public bytes alone does not cross the
`bin/vgui2_s.dll`/`vgui2_s.so` boundary. If the native client resolves this
module relative to the rooted client root or its HOME/cwd contract, R27 should
cross that boundary without changing any binary, provider, loader, display,
or SteamUI behavior.

This is a layout and launch-environment A/B only. It does not patch Steam,
invent a `.dll` alias, preload an adapter, import authentication state, or
change the rootless supervisor implementation.

## Fixed artifacts and source provenance

The public client source is the same sanitized current rooted tree used by
R26. Recreate it from the preserved rooted rollback path and require the
archive and selected file hashes to match R26 before staging:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs/opt/nova-steam/home/.local/share/Steam

R26 public archive sha256=4c62a8e35144b653864c31d84e682814a82384c3746001293e019d98bde25288
package/beta sha256=ef339938036ee25c4f533210a35791d5faf9f69dcbc72cce173263005500f9e4
installed manifest sha256=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
steamrtarm64/steam sha256=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so sha256=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so sha256=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e3b5bd77db4b10c87e
```

Use the same allowlist and exclusions as R26. Exclude `appcache/`,
`config/`, `logs/`, `steamapps/`, `userdata/`, `.crash`, `local.vdf`, and
`update_hosts_cached.vdf`; reject any `ssfn*`, `loginusers.vdf`,
`steam.token`, `user*.vdf`, `localconfig.vdf`, or `sharedconfig.vdf` path.
Do not read excluded file contents.

Keep fixed:

- pinned Holo ARM64 rootfs and the 161-package UI/audio closure;
- app-UID PRoot, no-`su` supervisor, resolver, `/proc`, and app-owned state;
- current rooted public client bytes and Valve media/SDL3 providers;
- direct Termux:X11 at `127.0.0.1:6077`, guest `DISPLAY=127.0.0.1:77`;
- inherited Android network, input, audio, and storage behavior;
- no Gamescope, AHardwareBuffer, Proton, game, OOBE, or SteamUI patch.

## Changed layout

Stage the public tree under the app-owned input root so the existing bind

```text
STEAM_CLIENT -> /opt/nova-steam
```

produces the rooted guest path:

```text
/opt/nova-steam/home/.local/share/Steam/
```

Create only fresh conventional links in the nested home, with no real Steam
data at any link target:

```text
/opt/nova-steam/home/.steam/steam    -> ../.local/share/Steam
/opt/nova-steam/home/.steam/root     -> ../.local/share/Steam
/opt/nova-steam/home/.steam/sdk32    -> ../.local/share/Steam/linux32
/opt/nova-steam/home/.steam/sdk64    -> ../.local/share/Steam/linux64
/opt/nova-steam/home/.steam/sdkarm64 -> ../.local/share/Steam/linuxarm64
/opt/nova-steam/home/.steam/bin32    -> ../.local/share/Steam/ubuntu12_32
/opt/nova-steam/home/.steam/bin64    -> ../.local/share/Steam/ubuntu12_64
```

The outer rootless supervisor still performs its normal preflight and still
binds the fresh app home to `/home/nova`; those links are intentionally not
used by the R27 Steam process. The only changed launch command is:

```text
/bin/sh -c 'export HOME=/opt/nova-steam/home; cd /opt/nova-steam/home/.local/share/Steam; exec /opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui'
```

The supervisor's outer `-w /home/nova` and environment are not edited; the
guest shell changes HOME and cwd immediately before Steam starts. This keeps
the test reversible and limits the A/B to the rooted path contract.

## Device scope and acceptance

Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, `arm64-v8a`.

```text
/data/local/tmp/nova-rootless-r27-rooted-layout-20260811T133336Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r27/
/data/data/com.termux/files/home/.nova-rootless-r27/
```

Preserve and verify the rooted rollback paths:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

Before launch, reread the lifecycle contract and run fresh exact-scope
cleanup. Capture the staged manifest and hashes, nested links, free space,
rootless preflight, fresh X11 PID/listener, exact command, Steam/client/
SteamUI/webhelper logs, process state, and a screenshot. Pull fresh logs before
teardown and verify no matching process or port-6077 listener remains after
cleanup.

The first positive boundary is a fresh loaded `steamui.so`; a UI pass also
requires a visible Steam frame and fresh `steamwebhelper`. Classify failure as
one of:

- rooted nested-layout/HOME/cwd resolution;
- client module-loader or dynamic-loader boundary;
- Holo/provider boundary;
- CEF/X11 display boundary;
- network/audio/input capability; or
- cleanup/process failure.

If R27 crosses `vgui2_s`, preserve the rooted layout as the rootless client
candidate and proceed to isolate the next native SteamUI/OOBE boundary. If it
repeats the fatal, stop the rooted-layout hypothesis and inspect fresh loader
evidence before advancing to Runtime 4, Proton, or packaging.

No Steam authentication secret may be read, copied, backed up, or exported.
