# AYN Thor rootless public-seed refresh — X11 foreground rerun result — 2026-08-11

Run ID: `thor-rootless-public-seed-refresh-x11-foreground-20260811T155135Z`;
sub-run: `Thor-rootless-public-arm64-seed-x11-foreground`.

Status: complete as a valid X11-lifecycle rerun, but the public seed did not
refresh to a usable client. Explicitly foregrounding Termux:X11 closed the
preceding infrastructure failure: the app-UID PRoot `xprop` handshake passed,
the fresh X11 server stayed alive, and Steam reached its updater/native startup
path. The older public ARM64 seed then returned the known `vgui2_s` loader
fatal before Vulkan, SteamUI, webhelper, or a Steam frame.

This is not an R31 Vulkan-provider result. The client bytes were the older
public seed, not the exact rooted public-beta tree used by the Nova R28–R31
experiments. No conclusion about Vulkan, KGSL access, WSI, `/dev/shm`, D-Bus,
Proton, or Gamescope is justified from this run.

## Result and classification

The preceding Thor refresh was invalid at the display infrastructure boundary:
the Termux:X11 process disappeared before Steam's `XOpenDisplay` call. This
rerun changed only the X11 lifecycle sequence:

1. start a fresh `:77` server through the Nova bridge;
2. explicitly launch `com.termux.x11/.MainActivity`; and
3. require an app-UID PRoot `xprop` handshake before Steam.

That sequence passed. The fresh server was PID `3204`, listened on TCP
`0.0.0.0:6077` and `[::]:6077`, and the guest-side probe exited zero. Steam
was therefore not blocked by the prior X11 disappearance.

The public seed remained at client version `1785979169`; its selected native
files were unchanged after the run:

```text
steamrtarm64/steam       cb5ba36e6462b6ad8901c9fe51a4df54933669de6c354754399f9ab4c7e5fc85
steamrtarm64/steamui.so  972b2290aef95771fc716dbc0e4cf8d27bd846e3b738a596148fbe67b6346ad0
steamrtarm64/vgui2_s.so  a3e010415d3b1cda22a9fe6ad8e5a33e558113483cbc7639ec4cae560c676dd7
```

The launch output reached:

```text
proot-shm-helper: Temporary path too long
src/steamUI/Main.cpp (2385) : !"Fatal Error: Could not load module 'bin/vgui2_s.dll'"
Error: For more information visit https://support.steampowered.com/kb_article.php?ref=9205-OZVN-0660
Could not load module 'vgui2_s.so'
[2026-08-11 16:03:08] Shutdown
```

The first line is a separate PRoot temporary-path warning. It is not folded
into the client-loader classification: the long run-specific state path made
the configured PRoot temporary path too long, while the client continued far
enough to produce the same native `vgui2_s` failure seen with the older
rootless seed. The warning is a known independent contract from the earlier
R9/R10 records and must be isolated before a later client-channel comparison.

The correct classification is therefore:

```text
x11 foreground lifecycle       pass
app-UID PRoot xprop             pass
public-seed refresh             fail; client remained 1785979169
native vgui2_s handoff          fail; old fatal returned
Vulkan/provider                 not tested
SteamUI/webhelper/frame         not reached
```

The host-side channel audit remains relevant: Valve's stable ARM64 channel is
the upstream client pairing previously observed in the clean
SteamClientTermux path, while the public-beta client requests the absent
`bin/vgui2_s.dll` path. That stable-channel test is deferred until the fresh
Thor profile no longer emits the independent long-temporary-path warning.

## Device and provenance

```text
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
branch=feat/rootless-steamclienttermux-profile
start_head=3264a9edd38d27f0dc450c8c4cb9921483499701
```

The exact fixed rootless inputs were:

```text
holo_rootfs_archive_size=384971555
holo_rootfs_archive_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
holo_ui_audio_closure=161 packages plus 2 pinned GTK2 assets
provider_lib_size=12364688
provider_lib_sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
provider_icd_size=194
provider_icd_sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
public_seed_archive_size=1756623692
public_seed_archive_sha256=1f4336e1e7a0f620e08c0be6850960b611841e50b1ab7bf455387489f5b83124
public_seed_version=1785979169
public_seed_sha256=1c1dd74e63db8d2d64445c7d6156f02e3b2719141e569b52e91b883d39592e82
```

The client used the nested guest layout `/opt/nova-steam/home/.local/share/Steam`,
the rooted SteamRT-first `PATH` and `LD_LIBRARY_PATH`, app-UID PRoot `-0`,
`/dev` and `/proc` bindings, app-owned resolver, inherited Android network,
fresh app-owned state, and `DISPLAY=127.0.0.1:77`. No Vulkan selector was set;
`VK_ICD_FILENAMES`, `VK_DRIVER_FILES`, `LD_PRELOAD`,
`MESA_LOADER_DRIVER_OVERRIDE`, `GALLIUM_DRIVER`, `LIBGL_ALWAYS_SOFTWARE`, and
`VK_IMPLICIT_LAYER_PATH` were unset.

The effective guest command was:

```text
export HOME=/opt/nova-steam/home
export USER=steam
export LOGNAME=steam
export LANG=C
export LC_ALL=C
export XDG_RUNTIME_DIR=/tmp/nova-steam-runtime
export PATH=/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/bin:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/bin:/usr/bin:/bin
export LD_LIBRARY_PATH=/opt/nova-steam/home/.local/share/Steam/steamrtarm64:/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu:/usr/lib:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu/pulseaudio
unset LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_LAYER_PATH VK_ICD_FILENAMES VK_DRIVER_FILES
cd /opt/nova-steam/home/.local/share/Steam
exec /opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -skipinitialbootstrap -no-child-update-ui
DISPLAY=127.0.0.1:77
```

## Fresh evidence

The Android device-log consent dialog was not shown on Thor. The fresh
app-UID display handshake ended with:

```text
nova_rootless_preflight=pass uid=10138 rootfs=files/thor-public-refresh-x11/guest-rootfs-closure proot=files/thor-public-refresh-x11/input/proot/bin/proot
nova_rootless_exec=proot display=127.0.0.1:77
_NET_SUPPORTED:  no such atom on any window.
```

The final X11 log also records the Android controller inventory, including
`Xbox Wireless Controller`, but no Steam input/UI state was reached. It
recorded the fresh 1920x970 display surface and remained alive after Steam
exited.

Evidence was captured before teardown under:

```text
/tmp/thor-rootless-public-seed-refresh-x11-foreground-20260811T155135Z-evidence/
```

```text
bootstrap_log.txt       871 bytes    sha256=7d4a2354fc64482832fa4d73c6cdeda1c7ccde4cfda474d2665cc5f691d0cff7
updateui_child.txt       99 bytes    sha256=bb4cd34a946f7cd1d2dcf65ca5b5951650c87fc5c891f31326ba50806f7a5654
rootless-supervisor.log 1817 bytes    sha256=f86bb51814ddbfcc741ddae56354389fe90e5ff1ea462cccf21cf33779096298
termux-x11-77.log      22491 bytes    sha256=817384f326bd42194e20662740adcabc27cfef989bc6c7a2180fa69f7d3fe293
termux-x11-77.pid          5 bytes    sha256=5ad8a942488afda24964b039e277e16637f8dd17ae5a8b9a666c2b73947964da
xprop.txt                666 bytes    sha256=897a6c71975c968b12ab1e0ad4ed7902c3133e26114559b9e6c2d1c25726f
client-hashes.txt        466 bytes    sha256=763a9a419064e08aaec71011f200051968ff4ab5e91eb0f1232108208d183451
screenshot.png         42111 bytes    sha256=b6ac7273e05e3beb6a4ecb2ed27c90c3d2f5f4d830014f849bb5155af94da4ba
processes-post.txt       190 bytes    sha256=322b71dada243e21de390fcad33ba7268cfe6f17e364f4dd6aca589a8999f28d
listeners-post.txt       162 bytes    sha256=438d85c75f352089ff06387e72c0d52c05deaa0e01ff00b526e4ae11264673c9
```

The screenshot is a 1920x1080 Android capture of a black Termux:X11 canvas
with the keybar and X cursor. It is not a Steam frame. The screenshot file
identifies as PNG RGBA, 1920x1080; the SHA-256 is recorded above.

The fresh archive had no `loginusers.vdf`, `config.vdf`, or `ssfn*` files in
the filename-only preflight. Steam created `.steam/registry.vdf`,
`.steam/steam.pid`, and `.steam/steam.token` in the fresh run state; their
contents were not read, copied, backed up, or exported, and the exact scope
was removed during cleanup.

## Cleanup and rollback boundary

The exact X11 PID `3204` was verified from the captured process command before
termination. Nova and Termux:X11 were force-stopped; the Termux-owned PID was
then terminated explicitly. Thor's original Termux configuration was restored
before scope removal:

```text
termux.properties.before_sha256=89094537f49531dc9b380a0dec3a441b2fb92577e0a4f1db505790eb8b7025b0
restored_termux.properties_sha256=89094537f49531dc9b380a0dec3a441b2fb92577e0a4f1db505790eb8b7025b0
```

Only these run-specific targets were removed and verified absent:

```text
/data/local/tmp/thor-rootless-public-seed-refresh-x11-foreground-20260811T155135Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/thor-public-refresh-x11/
/data/data/com.termux/files/home/.nova-thor-public-refresh-x11/
/data/data/com.termux/files/home/.nova-rootless/termux-x11-77.log
/data/data/com.termux/files/home/.nova-rootless/termux-x11-77.pid
```

Post-cleanup verification found no matching Steam, PRoot, webhelper, Nova, or
Termux:X11 process and no TCP 6077 listener. Free space was
`26942660 KiB` (`89%` used on the reported data filesystem). The Nova rooted
rollback paths are not present on Thor; no preservation claim is made for
them on this device.

## Next boundary

Predeclare exactly one short-temporary-path rerun in [doc 479](479-ayn-thor-rootless-short-temp-public-seed-predeclaration-2026-08-11.md).
It keeps the public client, X11 foreground lifecycle, launch environment,
resolver, rootfs, provider files, Steam flags, and no-selector Vulkan state
fixed. It changes only the app-owned PRoot temporary-path contract so the
known warning is isolated before the stable ARM64 channel is tested.

No Steam authentication secret or authenticated Steam state was read, copied,
backed up, committed, or exported.
