# Nova rootless R25 — rooted public-client parity result — 2026-08-11

Run ID: `nova-rootless-r25-rooted-parity-steamui-20260811T124700Z`;
sub-run: `R25-rootless-supervisor-rooted-public-client-parity`.

Status: complete; the rooted public-beta client and runtime closure carried
the rootless path past the raw-seed SDL3 boundary, but Steam stopped before a
SteamUI frame at its legacy `vgui2_s` module-root boundary.

## Result

R25 was the requested rooted-to-rootless parity test. It kept the app-UID
PRoot, Holo glibc closure, fresh app-owned Steam home, and direct Termux:X11
display unchanged from R24, while replacing the raw stable client with a
sanitized copy of the completed public-beta Steam tree that carried the
rooted APK through OOBE/QR. It also carried over the rooted Gamepad UI flags,
the `package/beta` marker, and the conventional `.steam` links. No root,
`su`, private mount namespace, Steam authentication state, Gamescope, or
SteamUI patch was imported.

The client recognized the public beta and reached the completed client/runtime
startup path:

```text
Opted in to client beta 'steamdeck_publicbeta' via beta file
You are in the 'steamdeck_publicbeta' client beta.
Using update UI: xwin
Loading cached metrics...
```

The fresh update UI child reported client version `1785979169`, after which
the client stopped at:

```text
src/steamUI/Main.cpp (2385) : !"Fatal Error: Could not load module 'bin/vgui2_s.dll'"
Error: Could not load module 'vgui2_s.so'
Shutdown
```

There was no fresh `steamui.so` load, `steamwebhelper`, Steam frame, OOBE,
QR screen, Vulkan initialization, or game launch. This is therefore a
Steam client module-resolution/lifecycle result, not a display, Vulkan, WSI,
network, audio, input, Gamescope, or AHardwareBuffer result.

The parity run was still valuable: R24 stopped on the missing
`SDL_TryLockJoysticks@@SDL3_0.0.0` symbol in `steamui.so`; R25 included the
completed Valve ARM64 `libSDL3.so.0` provider and crossed that boundary. The
remaining failure is not explained by the raw stable seed alone.

## What differs from the rooted happy path

The controlled parity boundary is now clearer:

| Boundary | Rooted known-good path | R25 rootless parity path |
|---|---|---|
| Client | Completed public-beta client, build `1785979614` at staging | Same sanitized completed public-beta tree; update child reported `1785979169` |
| Runtime/layout | Rooted private mount namespace/chroot with the provisioned client tree | App-UID PRoot with the same public tree mounted at `/opt/nova-steam` |
| Steam metadata | `package/beta=steamdeck_publicbeta` and rooted conventional `.steam` links | Same marker and final conventional links |
| Launch | `-gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox`, then rooted bounded lifecycle | Same flags plus `-nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui` |
| Privilege | Root/`su`, private mounts, rooted helper lifecycle | No root; app-owned PRoot, resolver, home, and temporary state |
| Authentication | Existing rooted session may have progressed through OOBE/QR | Fresh app-owned home; no authentication state copied or inspected |

The public tree does contain the ARM64 module that the error names in its
runtime directory:

```text
steamrtarm64/vgui2_s.so
size=3427240
sha256=a3e010415d3b1cda22a9fe6ad8e5a33e558113483cbc7639ec4cae560c676dd7
BuildID=7791d546270d9482be771e59859d4ffade472275
```

The completed host tree has no `bin/vgui2_s.dll`. That makes the current
working-directory/module-root contract a stronger explanation than a missing
public payload: Steam first asks for the legacy `bin/vgui2_s.dll` name and
then reports that it cannot load `vgui2_s.so`, even though the ARM64 `.so`
exists under `steamrtarm64/`. R18b reproduced the same fatal with the stable
client and conventional links. R25 proves that copying the complete rooted
public client closure alone does not resolve it.

## Inputs and verification

Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, `arm64-v8a`.

The rooted provisioning pins remained unchanged:

```text
steam_seed_package=bins_linuxarm64_linuxarm64.zip.7affd5c9053499769e4f0a46bbb6cbdf0ba0d548
steam_seed_size=109767888
steam_seed_sha256=b2de13c267e101679750445c9c449fbfb58dbb7c9851729e95ac69637b9df563
steamrt_snapshot=3c.0.20260714.251839
steamrt_sha256=f59e9541fb08f36097610f8cab07a0ed8f5f13e4a642b6fead87505aff979ab0
```

The host source was the completed public tree at
`android/nova-lab/build/steam-bootstrap/home/.local/share/Steam/`. It was
copied to the run staging area with only `logs/` excluded. The staged public
tree contained:

```text
client_files=19631
client_bytes=3385240 KiB
stage_bytes=3962112 KiB
aggregate_file_manifest_sha256=68a61613c5db5c860c49fee6d01ee118ac71ae004a8a11e7b3706d43450abf79
package/beta sha256=ef339938036ee25c4f533210a35791d5faf9f69dcbc72cce173263005500f9e4
steamrtarm64/steam sha256=cb5ba36e6462b6ad8901c9fe51a4df54933669de6c354754399f9ab4c7e5fc85
steamrtarm64/steamui.so sha256=972b2290aef95771fc716dbc0e4cf8d27bd846e3b738a596148fbe67b6346ad0
steamrtarm64/libSDL3.so.0 sha256=b0edc01af34ad08c496928c647edc20a3f2f3bdb22f4a460a902759d0183ef52
steam-runtime-steamrt-arm64/VERSIONS.txt sha256=b41d058bc7f4c8bd220f999661ac64fcbb40aa5ffe396c7eae25715f48ff3726
```

The 384,971,555-byte Holo rootfs archive and its pinned SHA-256 were reused
from R24:

```text
rootfs_archive_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
Holo/UI-audio package closure=161 packages
preflight_free_kib=78056124
```

Preparation passed with app UID `10128`, the prepared rootfs, and the staged
PRoot binary. The final app-home links were:

```text
.steam/steam    -> /opt/nova-steam
.steam/root     -> /opt/nova-steam
.steam/sdk32    -> /opt/nova-steam/linux32
.steam/sdk64    -> /opt/nova-steam/linux64
.steam/sdkarm64 -> /opt/nova-steam/linuxarm64
.steam/bin32    -> /opt/nova-steam/ubuntu12_32
.steam/bin64    -> /opt/nova-steam/ubuntu12_64
```

An initial staging pass used incorrect link targets; those links were
corrected and verified before launch. That correction is not a behavioral
result.

The exact launch command was:

```text
/bin/sh -c 'cd /opt/nova-steam && exec /opt/nova-steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui'
```

Termux:X11 was fresh for this run: PID `10772`, listener
`127.0.0.1:6077`, guest `DISPLAY=127.0.0.1:77`. No existing process or
readiness result was reused.

## Captured evidence

```text
/tmp/nova-r25-bootstrap_log.txt
size=857
sha256=b1925d0752993072a4a39284287fc7a0f4685c2e4a4f31fac004494471e60b0a

/tmp/nova-r25-updateui_child.txt
size=99
sha256=3b60d7f521fe359a1797c714d9b7b91a0aabe04687f5a2447826aa0f8a624b2e

/tmp/nova-r25-rootless-supervisor.log
size=1604
sha256=1b0ac317586af9975aeb2f662062d23c26194614537afc708c8cdc8098e94e8f

/tmp/nova-r25-rooted-parity-command.log
size=2855
sha256=45ef9b9612b9fd621c82a55cb0ed3895cec17040ae15c19bb5d866092ce7315e

/tmp/nova-r25-rootfs-extract.log
size=359
sha256=5450d158affc01bc7500a0cc4f7f961935e5ce6314a11daa0d1de0f341ccbc66

/tmp/nova-r25-guest-rootfs-prepare.log
size=14031
sha256=ad4d6d953705d3f577792d223857d998b63c7a06b399dd87b0068cdb67d76e24

/tmp/nova-r25-supervisor-preflight.log
size=779
sha256=a3874d198c07030b96aae325915f26417a0abe1f3c7821de2c2c6c5a1e1c431b

/tmp/nova-r25-rooted-parity-vgui2-failure.png
PNG 1280x960, size=102456
sha256=675dac3088dc124e2f7d15f2c8f3fe8c5650072186ee54baff3e3d1edfb00818
```

The screenshot is the Nova launcher surface, not SteamUI. No fresh
`steamwebhelper` or Steam process remained when the result was captured.

## Cleanup and rollback

The exact R25 scopes were removed after evidence capture:

```text
/data/local/tmp/nova-rootless-r25-rooted-parity-steamui-20260811T124700Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r25/
/data/data/com.termux/files/home/.nova-rootless/
```

Post-cleanup verification found no matching Steam, SteamUI, webhelper, PRoot,
Termux:X11, or Xwayland process and no `127.0.0.1:6077` listener. Device free
space returned to `86116168 KiB`. The preserved rooted rollback paths remained
present:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

No Steam authentication secret was read, copied, backed up, or exported.

## Decision and next step

Bringing the known-good rooted public client/runtime contract into rootless
was the correct experiment. It materially advanced the rootless path past
the raw stable seed’s missing SDL3 provider, and it establishes that the
remaining failure is not fixed by the public client payload alone.

The next step is a host/device layout audit, not another broad copy and not a
SteamUI patch:

1. Compare the preserved rooted runtime with the R25 host tree for the exact
   `steam`, `steamui.so`, `vgui2_s.so`, `bin`, `steamui`, and `steamrtarm64`
   paths, hashes, symlinks, ownership, and modes without reading auth files.
2. Compare the rooted and rootless launch working directories and environment,
   then inspect the ARM64 Steam module-loader references for the expected
   module root.
3. If the source/layout evidence identifies one missing rooted contract,
   predeclare one fresh rootless run changing only that contract. Do not create
   a guessed `vgui2_s.dll` alias, preload an adapter, or patch SteamUI.

Keep Runtime 4, Proton, full OOBE packaging, embedded X11, and new
Gamescope/AHardwareBuffer work behind the native SteamUI gate. The current
rooted OOBE/QR path remains the rollback/reference profile; R25 is a rootless
client-parity result, not a replacement for it.
