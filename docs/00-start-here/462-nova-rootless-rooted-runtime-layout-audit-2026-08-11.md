# Nova rootless rooted-runtime layout audit — 2026-08-11

Status: complete; the preserved rooted OOBE runtime is a newer public-beta
client than the host tree used by rootless R25, and the rooted and rootless
launch contracts also differ in HOME, client-root nesting, and working
directory. No device state was changed by this audit.

## Findings

R25 was described as rooted public-client parity, but it used the completed
host bootstrap at
`android/nova-lab/build/steam-bootstrap/home/.local/share/Steam/`. Its public
manifest began with client build `1785979614` and its installed-manifest hash
was:

```text
host R25 package/steam_client_steamdeck_publicbeta_linuxarm64.installed
size=1549302
sha256=8fc3a43264a6f1c37895ed43e324f1121db6d7129d1fb70ffd6346abe0b0f5d9
first_record=androidarm64/,-1;1785979614;0
```

The preserved rooted runtime on device
`675a2365` contains a different public-beta installation. Its installed
manifest begins with build `1786137466`:

```text
rooted package/steam_client_steamdeck_publicbeta_linuxarm64.installed
size=1549301
sha256=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
first_record=androidarm64/,-1;1786137466;0
```

The channel marker is the same in both trees:

```text
package/beta
sha256=ef339938036ee25c4f533210a35791d5faf9f69dcbc72cce173263005500f9e4
value=steamdeck_publicbeta
```

The three files at the R25 failure boundary are same-size but not byte
identical:

| File | Host R25 SHA-256 | Preserved rooted SHA-256 | Size |
|---|---|---|---:|
| `steamrtarm64/steam` | `cb5ba36e6462b6ad8901c9fe51a4df54933669de6c354754399f9ab4c7e5fc85` | `6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf` | 10,044,224 |
| `steamrtarm64/steamui.so` | `972b2290aef95771fc716dbc0e4cf8d27bd846e3b738a596148fbe67b6346ad0` | `69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171` | 38,532,968 |
| `steamrtarm64/vgui2_s.so` | `a3e010415d3b1cda22a9fe6ad8e5a33e558113483cbc7639ec4cae560c676dd7` | `aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e` | 3,427,240 |

Both trees place `vgui2_s.so` under `steamrtarm64/`; neither audited tree
contains a top-level `bin/vgui2_s.dll`. The R25 fatal is therefore not
evidence that the file is absent from the rooted client. It can be caused by
the client build’s loader behavior, or by the launch root it uses to resolve
the legacy `bin/vgui2_s.dll` name.

## Launch-contract comparison

The rooted direct Termux:X11 client script defines:

```text
STEAM_HOME=/opt/nova-steam/home
STEAM_ROOT=/opt/nova-steam/home/.local/share/Steam
STEAM_EXECUTABLE=/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam
HOME=/opt/nova-steam/home
```

It uses the conventional links below and invokes the absolute executable
through the rooted `setpriv`/chroot lifecycle:

```text
.steam/steam    -> ../.local/share/Steam
.steam/root     -> ../.local/share/Steam
.steam/sdk32    -> ../.local/share/Steam/linux32
.steam/sdk64    -> ../.local/share/Steam/linux64
.steam/sdkarm64 -> ../.local/share/Steam/linuxarm64
.steam/bin32    -> ../.local/share/Steam/ubuntu12_32
.steam/bin64    -> ../.local/share/Steam/ubuntu12_64
```

The rootless supervisor intentionally uses a flatter app-owned mapping:

```text
bind APP_HOME    -> /home/nova
bind STEAM_CLIENT -> /opt/nova-steam
-w /home/nova
HOME=/home/nova
.steam/steam -> /opt/nova-steam
```

R25 then launched `/opt/nova-steam/steamrtarm64/steam` from that rootless
contract. Thus R25 changed both the client bytes and the rooted-to-rootless
path contract relative to the device’s actual happy path; it was a useful
public-closure test, but not an exact replay of the known-good rooted client.

The existing rooted helper also sets the runtime-first library order and
handles the bounded bootstrap relaunch. The rootless supervisor does not
import that rooted privilege or helper lifecycle, by design. The next test
must isolate the public client revision first rather than silently combining
it with a new layout.

## Decision

The known-good rooted client is a valid rootless input candidate, but it must
be sanitized before it crosses the privilege boundary. The next run will:

1. allowlist only the rooted public client directories and package metadata;
2. exclude `config`, `userdata`, `steamapps`, `logs`, `appcache`, `.crash`,
   and all authentication/session state;
3. verify that no `ssfn*`, `loginusers.vdf`, `steam.token`, `user*.vdf`, or
   equivalent secret path is present in the staged archive; and
4. keep the current rootless Holo/PRoot, direct X11, network, and app-owned
   HOME/cwd contract unchanged for the first A/B.

If that exact current rooted public client still stops at `vgui2_s`, the
following experiment can change only the rootless client-root/HOME/cwd
mapping to mirror the rooted nesting. No guessed `bin/vgui2_s.dll` alias,
preload, or SteamUI patch is justified by this audit.

No authentication file contents were read, copied, backed up, or exported.
