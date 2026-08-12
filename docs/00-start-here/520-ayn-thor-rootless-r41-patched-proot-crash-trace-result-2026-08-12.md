# AYN Thor rootless R41 patched PRoot crash trace — result — 2026-08-12

Run identity: `thor-rootless-r41-patched-proot-crash-trace-20260812T140500Z`
Sub-run: `R41-rootless-steamclienttermux-patched-proot-crash-trace`
Branch: `feat/rootless-steamclienttermux-profile`
Start HEAD: `793aed5f5df91fa86a4aedad0a4dd14dc630642d`
Device: AYN Thor / `kalama` / serial `d234a848` / Android API 33 / `arm64-v8a`
App UID: `10138`
App SELinux identity: `u:r:runas_app:s0:c138,c256,c512,c768`
Root-shell context used for read-only staging and cleanup: `u:r:magisk:s0`

## Result

The valid final R41 replay is closed as a **non-discriminating patched-PRoot
crash trace**.

The patched PRoot did not move the rootless boundary. The app-UID guest again
found the configured KGSL/Turnip provider, enumerated `Turnip Adreno (TM) 740`,
and reached the Vulkan `vkCreateDevice` layer callstack. It then exited with
signal 11 before native SteamUI, `steamwebhelper`, OOBE, or a Steam frame.
The patched tracer reported `fault=0x0` and `ip=0`; it did not identify a
translated syscall, a concrete PRoot operation, or a faulting guest mapping.

This is evidence against “the stock PRoot binary alone is the immediate
fix.” It is not evidence that PRoot is definitively the cause, and it is not
evidence of a KGSL or SELinux denial. Vulkan provider discovery and physical
device enumeration remain working boundaries in this profile.

Two earlier invocations were excluded as invalid infrastructure attempts:
the first host-side capture closed its output pipe before a usable trace was
collected, and the second missed the temporary `/run/steam-launch.sh` helper.
The result above is from the corrected final replay with fresh X11 state and
drained output; neither invalid attempt is used as a Steam result.

## Controlled variable

Relative to R40b, the only intended runtime change was the predeclared outer
diagnostic variable. The verified SteamClientTermux patched PRoot and loader
were already fixed R40b inputs and remained unchanged:

```text
PROOT_CRASH_LOG=1
```

The variable was applied to the outer app-UID PRoot invocation, not exported
into Steam’s guest environment. No shared `/tmp`, `/dev/shm`, D-Bus,
machine-id, software-GL, additional Mesa/WSI variables, Runtime 4, Proton,
FEX/DXVK, Gamescope/AHardwareBuffer, SteamUI patch, UID/GID change, or
privileged Steam launch was added.

## Provenance

The current-tree public client fixture was selected without reading or copying
authenticated Steam state:

```text
public_client_archive_bytes=3757731328
public_client_archive_sha256=97c3140d75c551953c915fb8e06b4ec51c18b2cc32ec4af620ad64df62a77548
steamrtarm64/steam=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
steamrtarm64/steamwebhelper=7a65e4f7c89dd2eeb0668f85ea0a06cf737507b7f3324407e5fc9a9a488c31d0
installed_manifest=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
```

The Holo ARM64 rootfs was unchanged:

```text
holo_archive_bytes=384971555
holo_archive_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
holo_package_closure=161
holo_manifest_sha256=f3f46d90ab246dd799cb22d75cbb219ff3c5d8e62f1ce6f53c3847c74238d83f
```

The pinned provider remained:

```text
/opt/nova-kgsl-driver/libvulkan_freedreno.so bytes=12364688 sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
/opt/nova-kgsl-driver/freedreno-kgsl.icd.json bytes=194 sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
```

The patched PRoot was built from sibling revision
`8d14c10195b34fe2714ba59df1680df27a852532` and the following source/build
provenance:

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

The sibling checkout remained clean at the audited revision. The provider,
client, rootfs, and patched PRoot files were staged as immutable payloads; the
R41 Steam HOME, logs, X11 process/listener, temporary files, screenshot, and
readiness state were fresh.

## Fixed launch contract

R41 retained the R40b nested client layout, Holo rootfs, direct TCP
Termux:X11 display `127.0.0.1:77`, fresh app-owned `/tmp`, `/dev` and `/proc`
bindings, resolver setup, PRoot `-0`, SteamRT-first path ordering, and these
Steam flags:

```text
-gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -cef-disable-gpu -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui
```

The effective guest contract included:

```text
HOME=/opt/nova-steam/home
USER=steam
LOGNAME=steam
LANG=C
LC_ALL=C
XDG_RUNTIME_DIR=/tmp/nova-steam-runtime
DISPLAY=127.0.0.1:77
VK_DRIVER_FILES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
VK_LOADER_DEBUG=all
unset VK_ICD_FILENAMES LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_LAYER_PATH
```

## Fresh run evidence

The final supervisor log reported Vulkan loader 1.3.296, found the configured
ICD manifest, and opened the configured
`/opt/nova-kgsl-driver/libvulkan_freedreno.so`. The relevant sequence was:

```text
INFO | DRIVER:                [0] Turnip Adreno (TM) 740
INFO | LAYER:      Failed to find vkGetDeviceProcAddr in layer "libVkLayer_MESA_device_select.so"
DRIVER | LAYER:    vkCreateDevice layer callstack setup to:
DRIVER | LAYER:           Using "Turnip Adreno (TM) 740" with driver: "/opt/nova-kgsl-driver/libvulkan_freedreno.so"
PROOT_CRASH pid=22430 vpid=1 signal=11 code=1 fault=0x0 ip=0 sp=0x7ff6a1f7f0 lr=0x7782139c60 exe=/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam
proot info: vpid 1: terminated with signal 11
```

The Holo rootfs contains the implicit Mesa device-select manifest at
`/usr/share/vulkan/implicit_layer.d/VkLayer_MESA_device_select.json`:

```text
bytes=473
sha256=7cf0e893f7da6c36f19bddb526d9fc1da417a8ea40971b34b0f85dae1700352b
disable_environment.NODEVICE_SELECT=1
library=libVkLayer_MESA_device_select.so
library_bytes=133368
library_sha256=e921ba03c5de00a0434252f7f244cf2cfec5beb7c22b9e054816d3c29eb26cf9
```

This layer was loaded in R41. Its loader diagnostic immediately preceded the
`vkCreateDevice` callstack, making its declared disable variable the nearest
single-variable follow-up. R41 did not establish that the layer caused the
crash; it only establishes that it was active at the boundary.

Read-only Android device evidence was:

```text
/dev/kgsl-3d0 crw-rw-rw- system:system u:object_r:gpu_device:s0 487,0
app_uid_kgsl_read=0
app_uid_kgsl_write=0
```

These are metadata/readability probes only. No device ioctl, chmod/chown, or
SELinux change was performed. The successful Vulkan enumeration plus these
results do not support classifying R41 as an app-UID DAC/SELinux denial.

No native SteamUI, `steamwebhelper`, Steam OOBE, QR screen, or visible Steam
frame was reached. The final screenshot is a black X11 canvas with the
Termux keyboard strip, Android status bar, and cursor; it is not a Steam
frame:

```text
path=/tmp/thor-rootless-r41-patched-proot-crash-trace-20260812T140500Z-evidence/final-screen.png
dimensions=1920x1080
bytes=40144
sha256=887ab4abe5f78830bf2cb1dbb56f551a4fe9ed0515620a87769fa4c511f57468
```

The Android all-device-log consent dialog was not shown:
`log_access_consent=not-shown`. No blind acceptance action was sent.

The captured evidence bundle is retained outside the repository at
`/tmp/thor-rootless-r41-patched-proot-crash-trace-20260812T140500Z-evidence/`.
The primary files and hashes are:

```text
r41-supervisor-console-final.log bytes=16831 sha256=b3758944535555370681a449045e11fa431da6106ce16c01b3c2c0ce50941e7b
rootless-supervisor-final.log bytes=833 sha256=b23d4bb8b4655c3b6161fa1f41ad90f01b10fc2c85b0f2cb67d7980e1e7c7eea
bootstrap_log-final.txt bytes=435 sha256=73667f74dccaf89c8b9f9a379e7191d132ce5fb582dbaf8c1d0eb7f0554ac49d
updateui_child-final.txt bytes=99 sha256=b6566b95529d31ba5de94a2cacdd3df62241dc4c386423f14a65add1edf0caf8
termux-x11-final.log bytes=158274 sha256=ede07621fb9826c7048d9f02036d4c84fc98b5d2a0c1980b1365e1d26e8426ca
outer-id-final.txt bytes=325 sha256=ec27cb07ca0ad5adec4150e3ea8ea9563c2f2b57e0cbd36b880c3fd641dda4bb
kgsl-ls-lz-final.txt bytes=93 sha256=faf61367f7d723cb70b23ed189708d143f7244649c81e6aaa30b9bfd8ed6abeb
kgsl-access-final.txt bytes=41 sha256=10625e96edc5142ff085f6fd3afe28e7377e84137ffef7549d14e3a51f9e42ac
```

## Cleanup

Only the exact R41 scopes and temporary R41 launch helpers were removed:

```text
/data/local/tmp/thor-rootless-r41-patched-proot-crash-trace-20260812T140500Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r41/
/data/data/com.termux/files/home/.nova-rootless-r41/
/data/local/tmp/nova-r41-termux-x11.sh
/data/local/tmp/nova-r41-steam-launch.sh
```

After the exact Termux:X11 PID was stopped, cleanup verification showed no
R41 Steam, PRoot, webhelper, or Termux:X11 process and no listener on TCP
6077. The Nova launcher process was the only remaining matching app process.
The preserved rollback paths remained present:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

Post-cleanup free space was `16228256 KiB` (approximately 15.5 GiB). The
pre-cleanup state capture intentionally shows the still-running X11 PID and
listener; the later exact-PID cleanup verification is authoritative.

No Steam authentication secret, session token, cookie, QR state,
machine-auth file, authenticated Steam home, or `steam.token` contents were
read, copied, backed up, committed, or exported.
