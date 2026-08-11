# Nova rootless R26 — rooted-device public-tree replay predeclaration — 2026-08-11

Run ID: `nova-rootless-r26-rooted-device-public-steamui-20260811T130824Z`;
sub-run: `R26-rootless-supervisor-rooted-device-public-tree`.

Status: predeclared after the rooted-versus-rootless audit in [doc
462](462-nova-rootless-rooted-runtime-layout-audit-2026-08-11.md). This is
the corrected parity test: stage the current public client from the preserved
rooted OOBE runtime, remove all user/session state, and replay it under the
unchanged rootless supervisor contract.

## Hypothesis

R25 used the older host public-beta client build `1785979614`, while the
preserved rooted runtime that reached OOBE contains public-beta build
`1786137466`. The current rooted `steam`, `steamui.so`, and `vgui2_s.so` are
different bytes from the R25 copies. If the rooted client revision is the
missing part of parity, R26 should cross the `bin/vgui2_s.dll`/`vgui2_s.so`
boundary and load SteamUI without changing the rootless Holo/PRoot, HOME,
working directory, X11, network, input, or audio contract.

This is intentionally a client-source A/B. Do not change the rootless mount
layout in R26; if the failure remains identical, a later run can isolate the
HOME/client-root/cwd mapping separately.

## Source and sanitization

Source device:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs/opt/nova-steam/home/.local/share/Steam
```

The source is public client data only after an allowlisted copy. The sanitized
host staging tree must include the current public client directories and
package metadata needed by Steam:

```text
androidarm64
bin
clientui
controller_base
friends
graphics
legacycompat
lib
linux32
linux64
linuxarm64
package
public
resource
steam
steam-runtime-steamrt-arm64
steamrt32
steamrt64
steamrtarm32
steamrtarm64
steamui
tenfoot
ubuntu12_32
ubuntu12_64
fossilize_engine_filters.json
steam.sh
steam_msg.sh
steam_subscriber_agreement.txt
steamclient.dll
steamclient64.dll
```

Exclude the following source paths and any equivalent authentication/session
state:

```text
appcache/
config/
logs/
steamapps/
userdata/
.crash
local.vdf
update_hosts_cached.vdf
```

Before staging, verify the archive file list contains none of these path
components or secret names:

```text
ssfn*
loginusers.vdf
steam.token
user*.vdf
localconfig.vdf
sharedconfig.vdf
```

Do not read file contents from the excluded paths. Do not pull or export the
rooted Steam home wholesale. The source metadata to retain is limited to
public hashes and file-list provenance:

```text
package/beta
sha256=ef339938036ee25c4f533210a35791d5faf9f69dcbc72cce173263005500f9e4
value=steamdeck_publicbeta

package/steam_client_steamdeck_publicbeta_linuxarm64.installed
sha256=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
first_record=androidarm64/,-1;1786137466;0

steamrtarm64/steam
sha256=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf

steamrtarm64/steamui.so
sha256=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171

steamrtarm64/vgui2_s.so
sha256=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
```

## Controlled variables

Keep unchanged from R25:

- Holo ARM64 rootfs archive and 161-package UI/audio closure;
- app-UID PRoot, no-`su` supervisor, resolver, `/proc`, and app-owned state;
- rootless app home bound to `/home/nova`;
- public client bound to `/opt/nova-steam`;
- supervisor working directory `/home/nova`;
- fresh Steam data and no authentication state;
- direct Termux:X11 at `127.0.0.1:6077`, guest `DISPLAY=127.0.0.1:77`;
- inherited Android network path, input/audio settings, and no preload;
- no Gamescope, AHardwareBuffer, Proton, game, SteamUI, or OOBE patch.

Change only the public Steam client source from the R25 host tree to the
sanitized current rooted-device public tree. Preserve the final rootless
links:

```text
.steam/steam    -> /opt/nova-steam
.steam/root     -> /opt/nova-steam
.steam/sdk32    -> /opt/nova-steam/linux32
.steam/sdk64    -> /opt/nova-steam/linux64
.steam/sdkarm64 -> /opt/nova-steam/linuxarm64
.steam/bin32    -> /opt/nova-steam/ubuntu12_32
.steam/bin64    -> /opt/nova-steam/ubuntu12_64
```

Use this exact launch command:

```text
/bin/sh -c 'cd /opt/nova-steam && exec /opt/nova-steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui'
```

## Device scope and acceptance

Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, `arm64-v8a`.

```text
/data/local/tmp/nova-rootless-r26-rooted-device-public-steamui-20260811T130824Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r26/
/data/data/com.termux/files/home/.nova-rootless/
```

Preserve and verify the rooted rollback paths:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

Run fresh exact-scope cleanup before launch and after capture. Record the
sanitized source manifest, staged size/free space, rootless preflight, fresh
X11 PID/listener, updater/client/SteamUI/webhelper logs, process state, and a
screenshot before teardown.

The first positive boundary is a fresh loaded `steamui.so`; a UI pass requires
a visible Steam frame and fresh `steamwebhelper`. Classify failure as:

- client-revision/module-loader boundary;
- rootless HOME/client-root/cwd layout boundary;
- Holo/provider or dynamic loader boundary;
- CEF/X11 display boundary;
- network/audio/input capability boundary; or
- cleanup/process failure.

If R26 reaches SteamUI, retain the exact rooted public revision as the
rootless candidate and then isolate OOBE lifecycle. If it repeats the R25
fatal, do not add an alias; predeclare one layout-only A/B using the audit’s
rooted nesting contract.

No Steam authentication secret may be read, copied, backed up, or exported.
