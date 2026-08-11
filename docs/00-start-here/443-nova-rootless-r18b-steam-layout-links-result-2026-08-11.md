# Nova rootless R18b — conventional Steam layout links result — 2026-08-11

Run ID: `nova-rootless-r18b-steam-layout-20260811T110639Z`; sub-run:
`R18b-rootless-supervisor-steam-stable-layout-links`.

Status: complete; the conventional `.steam` links did not unblock the stable
ARM64 client and the replay reproduced the missing `bin/vgui2_s.dll` fatal.

## Result

R18b used Valve's stable ARM64 client with `package/beta` explicitly absent
from both the remote staging input and the app-owned client tree. It kept the
R17 Holo/PRoot closure, app-UID supervisor, resolver, direct Termux:X11
endpoint, client-root working directory, and launch command unchanged. The
only hypothesis variable was the four additional conventional `.steam` links:

```text
$HOME/.steam/steam        -> /opt/nova-steam
$HOME/.steam/sdkarm64     -> /opt/nova-steam/linuxarm64
$HOME/.steam/bin64       -> /opt/nova-steam/steamrt64
$HOME/.steam/bin32       -> /opt/nova-steam/steamrt32
$HOME/.steam/steamrtarm64 -> /opt/nova-steam/steamrtarm64
```

The stable client downloaded and installed successfully. Its first updater
process reached `Update complete, launching...` and `Shutdown`. A fresh
replay then verified the installation and reached the SteamUI handoff, but
failed with:

```text
Fatal Error: Could not load module 'bin/vgui2_s.dll'
```

No `steamwebhelper` process was spawned. The installed tree contains the
native `steamrtarm64/vgui2_s.so` and no `bin/vgui2_s.dll`. The fresh X11
capture is black with a small X cursor and the same narrow right-edge
scrollbar-like artifact; it is not a visible Steam frame.

This disproves the narrow layout-link hypothesis. It also changes the
interpretation of the earlier stable result: R17 without the additional links
did not emit the fatal during replay but stalled before `steamwebhelper`,
whereas R18b with the links reaches and reports the fatal. The links are not a
safe fix and must not be promoted into the rootless baseline.

## Profile and provenance

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `5b27f2c6b38fb3ecebda6d4efe028b6e3086a32775874da48ea08e257a682`.
- Display: fresh app-owned Termux:X11 at `127.0.0.1:6077`; guest display
  `:77`.
- Stable manifest URL:
  `https://client-update.steamstatic.com/steam_client_linuxarm64`.
- Stable client version: `1785799196`.
- Stable manifest SHA-256:
  `a2ad912ef6f150d373504a80c79f95210f8ed4ddbc42071593d0a120eb96ca91`.
- Stable ARM64 VZ payload SHA-256:
  `38dad8316435b1aea099f16c4eefb5da1fd57faa59fafe659945879ad5ae5148`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.
- SteamClientTermux reference revision:
  `8d14c10195b34fe2714ba59df1680df27a852532`.

Declared command:

```text
/bin/sh -c 'cd /opt/nova-steam && exec /opt/nova-steam/steamrtarm64/steam --version'
```

## Setup and acceptance evidence

The corrected device-side gate reported `beta_gate=pass`. Rootfs extraction,
the 161-package Holo/UI-audio closure, and preflight passed; preflight
reported `80196544 KiB` free. The five links were created and verified before
the stable launch.

After installation, the client tree contained `androidarm64`, `bin`,
`clientui`, `linuxarm64`, `steamrt32`, `steamrt64`, `steamrtarm64`, and the
other normal stable directories. The relevant updated hashes were:

```text
steamrtarm64/steam       72f48fb9c3f2c19cf64f8f7bbf4c7b7af65a73571ae0eeaab05bffd1633f4126
steamrtarm64/steamui.so  25ad66cfc78590b1745301ae7b86b70db64f5be0cd142d33134796e203fc8b76
steamrtarm64/vgui2_s.so  705f45328bb03c42509d28b748b0b499938f5e0caf2db618e8c929f0c3044186
steamrtarm64/steamwebhelper
                           3176d90436e49f7d34524ca2686cd324e2583806ba78841852b189fbcee0b83c
```

Fresh host evidence:

```text
/tmp/nova-r18b-steam-stable-layout-command.log
size=1021
sha256=3c5ae0a12f4f478957b6665bee01f52386d992348c734d79a1ad93850b186879

/tmp/nova-r18b-steam-stable-layout-replay.log
size=1082
sha256=0a2ab2832e0becfaf0979032a8b030386f2c3048c088e3c7cd20ba6cb5bbd4f1

/tmp/nova-r18b-stable-layout-replay.png
size=1280x960 PNG
sha256=7f0a25a3410737ed3c8d6cd23c861280944866e76c0437c9f36abe4d38f34241
```

The replay log is the decisive artifact. The screenshot is a presentation
state capture only; it does not establish SteamUI readiness.

## Cleanup and rollback

The exact R18b scopes were removed after process and listener teardown:

```text
/data/local/tmp/nova-rootless-r18b-steam-layout-20260811T110639Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r18b/
/data/data/com.termux/files/home/.nova-rootless/
```

Post-cleanup verification reported:

```text
remote_r18b=absent
app_r18b=absent
termux_rootless=absent
Steam/SteamUI/webhelper/PRoot/bsdtar/pacman/termux-x11 processes=none
127.0.0.1:6077 listener=absent
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs=present
/data/local/tmp/nova-active-runtime=present
```

No Steam authentication secret was read, copied, or exported. The disposable
R18b app state was removed in place, and the rooted rollback runtime was not
modified.

## Decision and next step

Do not retain the four additional links in the rootless profile. Keep R17's
stable/no-link result as a separate historical observation, but do not call
either configuration a SteamUI pass. The next experiment should be a fresh,
host/documented module-resolution or executable/runtime trace that explains
why the ARM64 client requests `bin/vgui2_s.dll` while the installed package
provides `steamrtarm64/vgui2_s.so`. It must not add another guessed alias or
SteamUI patch. Runtime 4, Proton, games, Gamescope/AHardwareBuffer, and
authentication remain deferred.
