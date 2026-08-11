# Nova rootless R29 — rooted KGSL/Turnip provider parity result — 2026-08-11

Run ID: `nova-rootless-r29-rooted-kgsl-20260811T141331Z`;
sub-run: `R29-rootless-supervisor-rooted-kgsl-turnip-provider`.

Status: complete as a bounded observation. R29 did not reach Vulkan
enumeration, so it does not close provider parity or prove an app-UID/SELinux
device-access failure. The provider-enabled Steam process instead crashed in
the updater/X11 startup path before it emitted `steamsysinfo`, Vulkan-loader,
SteamUI, or webhelper evidence. The earlier `vgui2_s` fatal remained absent.

## Result

R29 reproduced the R28 rootless baseline and added only the rooted KGSL/Turnip
provider visibility contract plus its explicit ICD selector:

```text
VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
```

The fixed client tree, nested layout, HOME/cwd, SteamRT-first library order,
app-UID PRoot, Holo closure, resolver, TCP Termux:X11, and Steam flags were
otherwise held constant. The final corrected supervisor bind used the input
root as the source of `/opt/nova-steam`, so the guest-visible client path was:

```text
/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam
```

The provider files were visible in the app-owned guest closure at:

```text
/opt/nova-kgsl-driver/libvulkan_freedreno.so
/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
```

The final Steam launch reached the real ARM64 executable and the X11 updater:

```text
CProcessEnvironmentManager is ready, 5 preallocated environment variables.
[2026-08-11 14:36:04] Startup - updater built Aug  7 2026 20:15:47
[2026-08-11 14:36:04] Startup - Steam Client launched with: '/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam' '-gamepadui' '-steamos3' '-steampal' '-steamdeck' '-no-cef-sandbox' '-nobootstrapperupdate' '-skipinitialbootstrap' '-no-child-update-ui'
[2026-08-11 14:36:04] Opted in to client beta 'steamdeck_publicbeta' via beta file
[2026-08-11 14:36:04] Using update UI: xwin
08/11 14:36:04 Init: Installing breakpad exception handler for appid(steam)/version(1786141909)/tid(27005)
proot info: vpid 1: terminated with signal 11
nova_r29_steam_exit=0
```

The `nova_r29_steam_exit=0` line is the outer shell's status; the PRoot
signal line is the meaningful native-process result. Steam did not emit the
R28 `Client version`, `CVulkanTopology`, `vkEnumeratePhysicalDevices`,
`BInit`, SteamUI-system, or webhelper milestones before exiting.

## Classification

This is a provider-enabled, pre-Vulkan startup crash—not a Vulkan PASS-A,
PASS-B, or FAIL-C classification:

- the configured driver and ICD were staged with the pinned hashes and were
  visible at the required guest paths;
- app-UID supervisor preflight passed and the guest reached the real Steam
  executable through the rooted nested layout;
- no fresh loader message proves that the ICD was opened, parsed, or rejected;
- no physical-device count, GPU name, vendor ID, `vkEnumeratePhysicalDevices`
  result, or `CVulkanTopology` line was produced;
- no concrete KGSL open/ioctl denial or SELinux denial was captured; and
- `/dev/shm`, D-Bus, Chromium, and webhelper were not reached in this run.

Therefore R29 does not justify saying that the Nova app UID cannot access
KGSL, nor that `VK_ICD_FILENAMES` is insufficient. The first useful next
experiment is a fresh provider-off control with every other R29 input fixed.
That control is predeclared in [doc 471](471-nova-rootless-r30-r29-provider-off-control-predeclaration-2026-08-11.md).

## Device and artifact provenance

Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
`arm64-v8a`. Branch at start: `feat/rootless-steamclienttermux-profile`;
start HEAD: `50e8488d3010a56595e2819eddcb554b09cd61dd`.

The sanitized rooted public archive was recreated from the preserved rooted
rollback and matched the previous R28 archive exactly:

```text
archive_bytes=3447515136
archive_sha256=4c62a8e35144b653864c31d84e682814a82384c3746001293e019d98bde25288
installed_manifest_sha256=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
steamrtarm64/steam_sha256=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so_sha256=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so_sha256=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
rootfs_archive_size=384971555
rootfs_archive_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
holo_ui_audio_package_closure=161 packages
```

The exact rooted provider artifacts and their app-owned copies were:

```text
libvulkan_freedreno.so size=12364688
libvulkan_freedreno.so sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
freedreno-kgsl.icd.json size=194
freedreno-kgsl.icd.json sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
```

The app-owned Holo package staging passed all 161 manifest hashes and both
Debian GTK2 external hashes. An initial staging attempt correctly rejected
the unfiltered 202-package cache; selecting the manifest's exact 161 files
was completed before the Steam launch. An initial guest-bind command also
pointed `/opt/nova-steam` at the nested Steam directory itself and exited
before Steam started; the final launch used the corrected rooted source-side
bind and is the only launch used for this result.

Fresh preflight and preparation evidence pulled before cleanup:

```text
/tmp/nova-r29-rootfs-extract.log
size=360
sha256=79ffb3cf8d4b2ff3ba4b039a819c970c73658fadb5923b9fb97a506c3f7cca03

/tmp/nova-r29-guest-rootfs-prepare.log
size=14032
sha256=b4c2b00b07ff1ba686f0696f08868763523b6fb0773a4aa6801df3f6b4685286

/tmp/nova-r29-supervisor-preflight.log
size=797
sha256=053f80fdba7580d78c849218da07804b080c78dab3c6f1ae45cfaf6f26272560
preflight_free_kib=74043468

/tmp/nova-r29-supervisor.log
size=3328
sha256=d8511c98124b2494ee521cd98dd5da002d883cd7afc6b59b4e41749a311997e3
```

The final launch used `DISPLAY=127.0.0.1:77`, app UID `10128`, and a fresh
Termux:X11 process:

```text
termux-x11 com.termux.x11 :77 -listen tcp -ac
pid=25546
listener=0.0.0.0:6077
/tmp/nova-r29-termux-x11.log size=5941 sha256=8dd9689158f90a083f697442b245e4d2980d1ef4f977707e452128efad433db3
```

The Android capture was not a Steam frame. It showed the Nova launcher
Activity after the guest Steam process exited:

```text
/tmp/nova-r29-rooted-kgsl-live.png
PNG 1280x960
size=102456
sha256=675dac3088dc124e2f7d15f2c8f3fe8c5650072186ee54baff3e3d1edfb00818
```

The device nodes remained Android-owned `0666` character devices:

```text
/dev/kgsl-3d0 character device 666 1000:1000 1df:0
/dev/dri/renderD128 character device 666 0:1003 e2:80
/dev/dri/card0 character device 666 0:1003 e2:0
```

Those mode/ownership facts are not enough to explain the crash. No device
node was modified, no SELinux setting was changed, and Steam was not rerun
under root.

## Scope deviation and cleanup

The declared Termux scope was
`/data/data/com.termux/files/home/.nova-rootless-r29/`, but the current
`RootlessTermuxBridge` does not pass `NOVA_ROOTLESS_TERMUX_STATE` to the
Termux-sourced helper. The fresh X11 helper therefore used its existing
default `/data/data/com.termux/files/home/.nova-rootless/` directory. This is
a launcher-scope defect to correct before productization; it did not change
the guest Steam environment, and both the declared and actual exact paths
were removed.

After evidence capture:

```text
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r29/                       absent
/data/local/tmp/nova-rootless-r29-rooted-kgsl-20260811T141331Z/                    absent
/data/data/com.termux/files/home/.nova-rootless-r29/                                absent
/data/data/com.termux/files/home/.nova-rootless/                                    absent
```

The APK and Termux:X11 were force-stopped. No R29 Steam, PRoot, webhelper, or
Termux:X11 process remained, and port `6077` was no longer listening.
Post-cleanup free space was `86109320 KiB`. The preserved rooted rollback
paths remained present and their provider hashes still matched:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
libvulkan_freedreno.so sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
freedreno-kgsl.icd.json sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
```

No Steam authentication secret or authenticated Steam state was read, copied,
backed up, committed, or exported. The fresh app state was removed with the
R29 scope.
