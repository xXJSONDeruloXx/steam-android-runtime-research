# Nova rootless R27 — rooted nested-layout replay result — 2026-08-11

Run ID: `nova-rootless-r27-rooted-layout-20260811T133336Z`;
sub-run: `R27-rootless-supervisor-rooted-nested-layout`.

Status: complete; the rooted nested client-root, HOME, and working-directory
mapping did not cross the `vgui2_s` module boundary. R27 used the same current
rooted public client that reached rooted OOBE, but Steam stopped at the same
fatal as R25 and R26.

## Result

R27 staged the current rooted public client below
`/opt/nova-steam/home/.local/share/Steam` and launched it with
`HOME=/opt/nova-steam/home` and that directory as the working directory. The
rootless supervisor, app-UID PRoot, Holo rootfs, 161-package UI/audio
closure, direct Termux:X11, and client bytes remained fixed.

The client recognized the current `steamdeck_publicbeta` tree and reported
version `1786141909`, then stopped immediately:

```text
src/steamUI/Main.cpp (2385) : !"Fatal Error: Could not load module 'bin/vgui2_s.dll'"
Error: Could not load module 'vgui2_s.so'
Shutdown
```

No fresh `steamui.so` load, `steamwebhelper`, Steam frame, OOBE, QR screen,
Vulkan initialization, or game launch was reached. The nested rooted layout
therefore does not explain the rootless failure. This is still a native Steam
module-resolution/lifecycle boundary, not a display, Vulkan, WSI, network,
audio, input, Gamescope, or AHardwareBuffer result.

The controlled sequence is now:

| Test | Client bytes | Client-root/HOME/cwd | Result |
|---|---|---|---|
| R25 | Older host public-beta tree, installed manifest `1785979614` | Flattened rootless layout | `vgui2_s` fatal |
| R26 | Current rooted public tree, manifest `1786137466` | Flattened rootless layout | `vgui2_s` fatal |
| R27 | Current rooted public tree, manifest `1786137466` | Rooted nested layout and HOME/cwd | Same `vgui2_s` fatal |

R26 and R27 together close both the stale-client-revision and rooted-nesting
hypotheses. Do not add a guessed `.dll` alias, preload an adapter, or patch
SteamUI based on this result.

## Artifact and layout provenance

Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, `arm64-v8a`.

The public source archive was recreated from the preserved rooted rollback
tree and matched R26 exactly:

```text
archive_bytes=3447515136
archive_sha256=4c62a8e35144b653864c31d84e682814a82384c3746001293e019d98bde25288
sanitized_file_count=19557
public_tree_input_size_kib=3392713
package/beta sha256=ef339938036ee25c4f533210a35791d5faf9f69dcbc72cce173263005500f9e4
installed_manifest sha256=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
installed_manifest_first_record=androidarm64/,-1;1786137466;0
steamrtarm64/steam sha256=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so sha256=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so sha256=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
```

The guest saw these fresh nested links:

```text
/opt/nova-steam/home/.steam/steam    -> ../.local/share/Steam
/opt/nova-steam/home/.steam/root     -> ../.local/share/Steam
/opt/nova-steam/home/.steam/sdk32    -> ../.local/share/Steam/linux32
/opt/nova-steam/home/.steam/sdk64    -> ../.local/share/Steam/linux64
/opt/nova-steam/home/.steam/sdkarm64 -> ../.local/share/Steam/linuxarm64
/opt/nova-steam/home/.steam/bin32    -> ../.local/share/Steam/ubuntu12_32
/opt/nova-steam/home/.steam/bin64    -> ../.local/share/Steam/ubuntu12_64
```

The pinned Holo inputs were unchanged:

```text
rootfs_archive_size=384971555
rootfs_archive_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
Holo/UI-audio package closure=161 packages
```

## Provisioning and launch evidence

The app-owned rootfs extraction and closure completed before launch. The
closure log recorded the expected non-booted-system warnings from package
hooks and ended with `nova_rootless_guest_rootfs=pass`.

```text
/tmp/nova-r27-rootfs-extract.log
sha256=4fc7408fa99ae5c480b2bd73aa1aaa54c43280c841d1cf534c9485522dc302ee

/tmp/nova-r27-guest-rootfs-prepare.log
sha256=db0b0f6e27ee4c01933e1ca1df18f2ff74f68bf8aa7cf3ef31dfc39d2cb104c8

/tmp/nova-r27-supervisor-preflight.log
sha256=a82b7ce3f050ebc0d83b1f2a167db3529add008c254de9bc9066f6ece121399e8
preflight_free_kib=74120560
launch_preflight_free_kib=74120096
```

Fresh Termux:X11 was PID `16718`, invoked as
`termux-x11 com.termux.x11 :77 -listen tcp -ac`. Its listener was
`0.0.0.0:6077`; the guest used `DISPLAY=127.0.0.1:77`.

The exact changed launch command was:

```text
/bin/sh -c 'export HOME=/opt/nova-steam/home; cd /opt/nova-steam/home/.local/share/Steam; exec /opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui'
```

The client output contained the nested rooted path and the same fatal:

```text
/tmp/nova-r27-rooted-layout-command.log
size=2939
sha256=09fda2dcf977db604d6f15eb444339d657c27a0876ce4312b4c9d4f604231d88
```

Fresh nested client logs were pulled before teardown:

```text
/tmp/nova-r27-bootstrap_log.txt
size=905
sha256=953347ced554733ed07287c1927e10a4661b02d8268da81f5bebdf033eeaf460

/tmp/nova-r27-updateui_child.txt
size=99
sha256=e181e2fcaad3cb5156d52c72a989ed3ed79f3cdaec8881cc9d62cce20909b95f

/tmp/nova-r27-termux-x11.log
size=6853
sha256=bb8f352897336d8ea1fa48b79bd763c256e2194f1285d2c549d0bdb1726203ce
```

The screenshot was the Nova launcher surface after Steam exited, not a Steam
frame:

```text
/tmp/nova-r27-rooted-layout-after-launch.png
PNG 1280x960, size=102456
sha256=675dac3088dc124e2f7d15f2c8f3fe8c5650072186ee54baff3e3d1edfb00818
```

## Cleanup and rollback

After evidence capture, the APK was force-stopped and the exact fresh X11 PID
`16718` was terminated with root because the shell UID could not signal the
Termux-owned process. Verification found no matching Termux:X11, PRoot,
Steam, SteamUI, Xwayland, Gamescope, or port-6077 listener.

Removed exact disposable scopes:

```text
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r27/
/data/data/com.termux/files/home/.nova-rootless/
/data/local/tmp/nova-r27-rooted-public-20260811T133336Z.tar
/data/local/tmp/nova-r27-infra/
/data/local/tmp/nova-rootless-r27-rooted-layout-20260811T133336Z/ (if present)
/tmp/nova-r27-rooted-public-20260811T133336Z.tar
```

Post-cleanup device free space was `85989388 KiB`. The rooted rollback paths
remained intact:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

No Steam authentication secret was read, copied, backed up, or exported.

## Decision and next step

R27 closes the “rooted nested layout is the missing rootless variable”
hypothesis. The next step should be a read-only module-loader/environment
audit, not another client tree copy or a speculative patch:

1. Compare rooted and rootless `cwd`, `HOME`, `argv[0]`, `/proc/self/maps`,
   `LD_LIBRARY_PATH`, `DT_NEEDED`, `DT_RPATH`/`DT_RUNPATH`, and actual
   `bin/`/`steamrtarm64` path visibility at the `vgui2_s` load boundary.
2. Use loader diagnostics or a narrow non-invasive probe to determine whether
   `vgui2_s.so` is rejected because it is not found, because one dependency is
   unresolved, or because the Steam module loader applies a different root.
3. Only after that evidence, decide whether the fix belongs in the rootless
   launch contract, the Holo provider closure, or a small upstream-compatible
   compatibility layer. Keep Runtime 4, Proton, Gamescope/AHardwareBuffer,
   and OOBE packaging deferred until native SteamUI can load.

Do not create a guessed `bin/vgui2_s.dll` alias, preload an adapter, or patch
SteamUI based on R27.
