# Nova rootless R26 — rooted-device public-tree replay result — 2026-08-11

Run ID: `nova-rootless-r26-rooted-device-public-steamui-20260811T130824Z`;
sub-run: `R26-rootless-supervisor-rooted-device-public-tree`.

Status: complete; the current public client copied from the preserved rooted
OOBE runtime still stopped at the same `vgui2_s` module boundary under the
unchanged rootless HOME/client-root/cwd contract. The stale R25 client
revision is therefore not the sole cause.

## Result

R26 staged an allowlisted, authentication-free public copy of the current
rooted Steam tree. The source was the exact client that had progressed through
rooted OOBE/QR, including its newer public-beta files. R26 kept the R25
rootless Holo/PRoot, app-owned state, direct Termux:X11, network, input, audio,
and flattened client-root contract unchanged.

Steam recognized the public beta and reached client startup at version
`1786141909`:

```text
Opted in to client beta 'steamdeck_publicbeta' via beta file
Using update UI: xwin
Loading cached metrics...
```

It then reproduced the same fatal as R18b and R25:

```text
src/steamUI/Main.cpp (2385) : !"Fatal Error: Could not load module 'bin/vgui2_s.dll'"
Error: Could not load module 'vgui2_s.so'
Shutdown
```

No fresh `steamui.so` load, `steamwebhelper`, Steam frame, OOBE, QR screen,
Vulkan initialization, or game launch was reached. This remains a Steam
client module-resolution/lifecycle result, not a display, Vulkan, WSI,
network, audio, input, Gamescope, or AHardwareBuffer result.

The decisive comparison is now:

| Test | Public client source | Result |
|---|---|---|
| R25 | Host completed public-beta tree, installed manifest build `1785979614` | `bin/vgui2_s.dll`/`vgui2_s.so` fatal |
| R26 | Sanitized current rooted OOBE tree, installed manifest build `1786137466`; runtime reported `1786141909` | Same fatal |

Copying the exact current rooted public client is necessary parity work but
not sufficient. The next controlled variable is the rooted versus rootless
HOME/client-root/working-directory mapping.

## Sanitization and public artifact provenance

Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, `arm64-v8a`.

Source device path:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs/opt/nova-steam/home/.local/share/Steam
```

The public archive explicitly excluded `appcache/`, `config/`, `logs/`,
`steamapps/`, `userdata/`, `.crash`, `local.vdf`, and
`update_hosts_cached.vdf`. A secret-name scan found no `ssfn*`,
`loginusers.vdf`, `steam.token`, `user*.vdf`, `localconfig.vdf`, or
`sharedconfig.vdf` path. No excluded file contents were read.

```text
archive_bytes=3447515136
archive_sha256=4c62a8e35144b653864c31d84e682814a82384c3746001293e019d98bde25288
sanitized_file_count=19557
device_input_size_kib=3392696
package/beta sha256=ef339938036ee25c4f533210a35791d5faf9f69dcbc72cce173263005500f9e4
installed_manifest sha256=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
installed_manifest_first_record=androidarm64/,-1;1786137466;0
steamrtarm64/steam sha256=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so sha256=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so sha256=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
```

The public input was owned by app UID `10128`. Final rootless links were:

```text
.steam/steam    -> /opt/nova-steam
.steam/root     -> /opt/nova-steam
.steam/sdk32    -> /opt/nova-steam/linux32
.steam/sdk64    -> /opt/nova-steam/linux64
.steam/sdkarm64 -> /opt/nova-steam/linuxarm64
.steam/bin32    -> /opt/nova-steam/ubuntu12_32
.steam/bin64    -> /opt/nova-steam/ubuntu12_64
```

## Provisioning and launch

The pinned Holo archive and rootless closure remained unchanged:

```text
rootfs_archive_size=384971555
rootfs_archive_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
Holo/UI-audio package closure=161 packages
```

The first attempt through Android toybox `tar` failed on archive symlinks:

```text
tar: './usr/lib64' bad symlink
tar: './usr/lib/icu/78.1/pkgdata.inc' not in archive
tar: './usr/lib/systemd/system/system-systemd\\x2dcryptsetup.slice' not in archive
tar: './usr/lib/systemd/system/system-systemd\\x2dveritysetup.slice' not in archive
tar: had errors
```

This was a rootless extraction-tool boundary, not a Steam result. The retry
used the existing read-only Holo rootfs only as a PRoot-visible source of
`/usr/bin/bsdtar`; it did not modify the rooted runtime. The archive then
passed and the 161-package guest closure completed.

```text
/tmp/nova-r26-rootfs-extract.log
sha256=1edf9c3663742bb6461714ceffc76563a3bcf127b8f41bb08b0ba6e223144df4

/tmp/nova-r26-rootfs-extract-bootstrap.log
sha256=7671d420fb4345644f025fce9addda04bc1def83e63690ac37c1f168f37be1fa

/tmp/nova-r26-guest-rootfs-prepare.log
sha256=62555340f81efccf947e7b8806d078c832fa70fad4d2b1354c2a3057ddd658b8

/tmp/nova-r26-supervisor-preflight.log
sha256=e25bfd3dcc7fa1c4e6ae0ec45cd8b498f300b2044414215a785bcdd2b55cd2e5
preflight_free_kib=78048152
launch_preflight_free_kib=78044656
```

Fresh Termux:X11 was PID `13840`, invoked as
`termux-x11 com.termux.x11 :77 -listen tcp -ac`. The listener was present on
port 6077; the guest used `DISPLAY=127.0.0.1:77`. The `/proc/net/tcp`
listener was `0.0.0.0:6077`, not a loopback-only bind, as expected for this
experimental TCP transport.

The exact guest launch was:

```text
/bin/sh -c 'cd /opt/nova-steam && exec /opt/nova-steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui'
```

## Captured evidence

```text
/tmp/nova-r26-rooted-device-public-rootless-command.log
size=2867
sha256=296f940640528e3786cafb839222345fdbbe2968b1622667a0f72ef21955242e

/tmp/nova-r26-bootstrap_log.txt
size=857
sha256=722c875cf1b2862b89b44216883dd2c5b604bcb9348a3bd11c7980e2016c3692

/tmp/nova-r26-updateui_child.txt
size=99
sha256=d72db4a3b0b5407aec435342db994374dcd0573fcf247b54aa644caf410a2894

/tmp/nova-r26-rootless-supervisor.log
size=1628
sha256=5bdbfa78739433e3b77930c0a40efc2fb389ac8275ffe521e21c834630007053

/tmp/nova-r26-rooted-device-public-rootless-after-launch.png
PNG 1280x960, size=102456
sha256=675dac3088dc124e2f7d15f2c8f3fe8c5650072186ee54baff3e3d1edfb00818
```

The screenshot is the Nova launcher surface, not SteamUI. No fresh Steam or
SteamUI process remained after the client exited; only the fresh X11 process
was present until teardown.

## Cleanup and rollback

The exact R26 scopes were removed after evidence capture:

```text
/data/local/tmp/nova-rootless-r26-rooted-device-public-steamui-20260811T130824Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r26/
/data/data/com.termux/files/home/.nova-rootless/
```

The fresh X11 PID `13840` was terminated and verified absent. Post-cleanup
verification found no matching Termux:X11, PRoot, Steam, SteamUI, or Xwayland
process and no port-6077 listener. Device free space returned to
`86102672 KiB`. The rooted rollback paths remained present:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

The obsolete R25 host staging tree and disposable R26 public archive were
removed after their hashes were recorded; reusable R24 provisioning inputs
remain for the next bounded experiment. No Steam authentication secret was
read, copied, backed up, or exported.

## Decision and next step

R26 confirms that the exact current rooted public client does not solve the
rootless `vgui2_s` fatal when mounted at `/opt/nova-steam` with
`HOME=/home/nova` and started from `/home/nova`. This closes the “stale client
revision only” hypothesis.

The next experiment should change only the path contract while keeping the
R26 public bytes and Holo closure fixed:

1. Present the public tree under the rooted nesting
   `/opt/nova-steam/home/.local/share/Steam`.
2. Launch the nested `steamrtarm64/steam` with the corresponding rooted HOME
   and working directory.
3. Keep fresh app-owned state, no auth data, direct X11, and the no-patch
   policy.

Do not create a guessed `bin/vgui2_s.dll` alias, preload an adapter, or patch
SteamUI. If the layout-only A/B still fails identically, inspect the client
build’s module-loader behavior and the rooted helper’s environment before
advancing to Runtime 4, Proton, or OOBE packaging.
