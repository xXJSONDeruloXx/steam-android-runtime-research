# AYN Thor rootless R42 Mesa device-select isolation — result — 2026-08-12

Run identity: `thor-rootless-r42-nodevice-select-20260812T151500Z`
Sub-run: `R42-rootless-nodevice-select-layer-isolation`
Branch: `feat/rootless-steamclienttermux-profile`
Start HEAD: `c80e4bf8bde4404bd313d2c6658fb52104e71010`

## Result

R42 is a **valid selector-isolation result**. `NODEVICE_SELECT=1` was
effective: the Holo `VK_LAYER_MESA_device_select` manifest was discovered,
but the layer library was not loaded or inserted into the Vulkan call chain.
The loader reported the direct `Application -> Loader -> Drivers` instance
chain rather than the R41 layer chain.

That did not move the rootless boundary. Steam still:

- found the configured `VK_DRIVER_FILES` ICD;
- loaded the pinned KGSL/Turnip driver;
- enumerated `Turnip Adreno (TM) 740`;
- reached the Vulkan `vkCreateDevice` dispatch path; and
- terminated with signal 11 immediately afterward, before native SteamUI,
  `steamwebhelper`, OOBE, QR login, or a Steam frame.

The nearest conclusion is therefore:

> The Mesa device-select layer was not sufficient to explain the crash. The
> crash remains a post-device-use boundary in the app-UID PRoot/Steam Vulkan
> path. This run does not prove that PRoot is the cause, and it does not
> identify a KGSL or SELinux denial.

The patched PRoot from SteamClientTermux remains a valid fixed input for the
next diagnostic, but it is not a demonstrated unblocker for native Steam UI.

## Device and provenance

```text
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
app_selinux=u:r:runas_app:s0:c138,c256,c512,c768
root_shell_selinux=u:r:magisk:s0
rootless_guest_mode=PRoot -0
sibling_checkout=/Users/kurt/Developer/steamclienttermux
sibling_revision=8d14c10195b34fe2714ba59df1680df27a852532
```

The selected public client is a current sanitized-tree equivalence fixture,
not the unavailable historical R28 archive:

```text
public_client_archive_bytes=3757731328
public_client_archive_sha256=97c3140d75c551953c915fb8e06b4ec51c18b2cc32ec4af620ad64df62a77548
steamrtarm64/steam=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
steamrtarm64/steamwebhelper=7a65e4f7c89dd2eeb0668f85ea0a06cf737507b7f3324407e5fc9a9a488c31d0
installed_manifest=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
```

The fixed Holo/provider inputs were:

```text
holo_rootfs_bytes=384971555
holo_rootfs_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
holo_ui_audio_closure=161 packages plus 2 Debian GTK2 assets
libvulkan_freedreno.so_bytes=12364688
libvulkan_freedreno.so_sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
freedreno-kgsl.icd.json_bytes=194
freedreno-kgsl.icd.json_sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
```

The patched PRoot artifacts came from the clean sibling revision recorded
above:

```text
patch_base_commit=a89b3732ec6ae1db674510f0843b2f3db54d0a2f
patchset_sha256=ce94daf1ae8a7fb994a4295d69006fe8604ac724bd6343daa25532f21f904f69
diff_sha256=e6fa2c6bd7073c7925f9b0d9bc5559b70aabc44515a81510301a07c99947d7c1
patched_proot_bytes=300456
patched_proot_sha256=0378e0631dbf7a8bd0061b54fc167bb881c70a76109f567b682f7262a063166c
patched_loader_bytes=18232
patched_loader_sha256=eab6b2135421a2e0268832cf171d877146a9e816d7b060ce425e5017d65f08a6
libtalloc_sha256=3c9b207c0a6ea2896b7523e03f55d9ab0d9e88baa115d4c32b84058ff4246fbb
libandroid_shmem_sha256=84475798e07c8174dbbfaec70a827fdb02f19ffa69a589380c13e7507fd0e731
```

No sibling Steam payload, Steam home, authentication state, or product data
was copied.

## Controlled variable

Relative to R41, the only guest Steam environment change was:

```text
export NODEVICE_SELECT=1
```

The outer diagnostic `PROOT_CRASH_LOG=1`, patched PRoot and loader, client
fixture, Holo rootfs, pinned provider, SteamRT-first library ordering,
app-owned state, direct TCP Termux:X11, PRoot `-0`, `/dev` and `/proc`
bindings, resolver, and Steam flags remained fixed. The following remained
unset:

```text
VK_ICD_FILENAMES
LD_PRELOAD
MESA_LOADER_DRIVER_OVERRIDE
GALLIUM_DRIVER
LIBGL_ALWAYS_SOFTWARE
VK_IMPLICIT_LAYER_PATH
```

No `/dev/shm`, D-Bus, machine-id, Runtime 4, Proton, FEX/DXVK,
Gamescope/AHardwareBuffer, UI patch, input/audio helper, UID/GID change, or
privileged Steam launch was introduced.

The effective Steam environment was:

```text
HOME=/opt/nova-steam/home
USER=steam
LOGNAME=steam
LANG=C
LC_ALL=C
XDG_RUNTIME_DIR=/tmp/nova-steam-runtime
DISPLAY=127.0.0.1:77
PATH=/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/bin:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/bin:/usr/bin:/bin
LD_LIBRARY_PATH=/opt/nova-steam/home/.local/share/Steam/steamrtarm64:/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu:/usr/lib:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu/pulseaudio
VK_DRIVER_FILES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
VK_LOADER_DEBUG=all
NODEVICE_SELECT=1
```

Steam was launched with:

```text
-gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -cef-disable-gpu -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui
```

## Fresh-run evidence

The evidence bundle is retained outside the repository at:

```text
/tmp/thor-rootless-r42-nodevice-select-20260812T151500Z-evidence/
```

Preflight passed as app UID 10138 with `9960176 KiB` free. Termux:X11 was a
fresh process PID `25794`, running as Termux UID 10135, with TCP port 6077
listening on IPv4 and IPv6. The Android all-device-log consent dialog was not
shown (`log_access_consent=not-shown`), so no ADB acceptance input was sent.

The relevant fresh console sequence is:

```text
INFO:              Vulkan Loader Version 1.3.296
INFO:              Found manifest file /usr/share/vulkan/implicit_layer.d/VkLayer_MESA_device_select.json
DRIVER:            Found ICD manifest file /opt/nova-kgsl-driver/freedreno-kgsl.icd.json, version 1.0.1
DEBUG | DRIVER:    Searching for ICD drivers named /opt/nova-kgsl-driver/libvulkan_freedreno.so
LAYER:             vkCreateInstance layer callstack setup to:
LAYER:               <Application>
LAYER:                 ||
LAYER:               <Loader>
LAYER:                 ||
LAYER:               <Drivers>
INFO | DRIVER:                [0] Turnip Adreno (TM) 740
DRIVER | LAYER:    vkCreateDevice layer callstack setup to:
DRIVER | LAYER:           Using "Turnip Adreno (TM) 740" with driver: "/opt/nova-kgsl-driver/libvulkan_freedreno.so"
PROOT_CRASH pid=27842 vpid=1 signal=11 code=1 fault=0x0 ip=0 sp=0x7fd528b070 lr=0x7efe139c60 exe=/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam
proot info: vpid 1: terminated with signal 11
```

The loader still printed manifest discovery lines because it scans the Holo
implicit-layer directory. It did **not** print `Loading layer library`,
`Insert instance layer`, or the R41 `Failed to find vkGetDeviceProcAddr in
layer` line. The direct three-node call chain is the evidence that
`NODEVICE_SELECT=1` was honored.

The fresh Steam bootstrap logs only reached updater/X11 setup:

```text
Startup - Steam Client launched with: '/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam' ...
Opted in to client beta 'steamdeck_publicbeta' via beta file
Using update UI: xwin
Client version: 1786141909
Using update UI: xwin
```

No native SteamUI, `steamwebhelper`, `steamsysinfo`, `/dev/shm`, D-Bus,
OOBE, QR screen, or Steam frame was reached. The final screenshot is display
lifecycle evidence only:

```text
path=/tmp/thor-rootless-r42-nodevice-select-20260812T151500Z-evidence/postlaunch.png
dimensions=1920x1080
bytes=40369
sha256=298390691c36a8dcd753e214be80d42f058aabfad4da82ccc70368866199c66e
visible=black X11 canvas, Android status bar, cursor, and Termux keyboard strip; no Steam frame
```

The selected client hashes were unchanged after the run. The app-visible
KGSL node remained world-readable and world-writable:

```text
/dev/kgsl-3d0 crw-rw-rw- system system u:object_r:gpu_device:s0 487,0
app_uid_metadata=readable,writable
```

These are metadata/readability checks only. No ioctl, device write, chmod,
chown, or SELinux change was performed.

Selected evidence file hashes:

```text
r42-supervisor-console.log=935e793e9b838adc0f24c33d4ac88e040cadc9efe721272ab7bf8c67604f6476
rootless-supervisor.log=8ec6ad6da556aa5f9d69829226ca929596c5c68ef621c4464e7ef9f0addfc758
bootstrap_log.txt=0fbf5e74571ab6e5c3bd480f2c10ed402b0f1ab8db5eb9fbc0e69f003abf9e86
updateui_child.txt=e693d63cce01c25d886174175b57cd29a7f7300892626f8c42e47e080db12d24
termux-x11.log=873897f6f52feec1afa7ba470420fdc3894b5a333596d00e9160b2c901598d56
postlaunch.png=298390691c36a8dcd753e214be80d42f058aabfad4da82ccc70368866199c66e
```

## Cleanup and rollback

The exact R42 scopes were removed:

```text
/data/local/tmp/thor-rootless-r42-nodevice-select-20260812T151500Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r42/
/data/data/com.termux/files/home/.nova-rootless-r42/
```

The normal Termux helper could not resolve `PREFIX` when invoked through
`run-as`, so it failed before signaling the X11 PID. The exact recorded X11
PID `25794` and its logcat child `25820` were then terminated directly and
verified absent. This was an exact-PID fallback, not a broad process kill.

Post-cleanup verification showed:

```text
matching_r42_steam_proot_webhelper_x11_processes=absent
port_6077=absent
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs=present
/data/local/tmp/nova-active-runtime=present
post_cleanup_free_kib=16087668
```

The remaining matching process was only the Nova APK launcher. No preserved
rooted runtime path was changed.

## Next boundary

The single next experiment is [doc
523](523-ayn-thor-rootless-r43-sysvipc-diagnostic-predeclaration-2026-08-12.md):
retain the R42 selector-disabled profile and add only the patched PRoot's
`PROOT_SYSVIPC_LOG=1` diagnostic. The sibling patch specifically adds
Android-compatible robust-list and SysV semaphore/shared-memory handling;
this bounded trace can show whether Steam exercises that emulation before the
post-device crash. It is diagnostic evidence, not a proposed fix, and must
not import the sibling launcher's D-Bus, `/dev/shm`, Mesa/WSI, audio, route,
Runtime 4, Proton, or helper contracts.

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, authenticated Steam home, or `steam.token` contents were read, copied,
backed up, committed, or exported.
