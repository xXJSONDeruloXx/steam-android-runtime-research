# AYN Thor rootless R40 patched PRoot replay — predeclaration — 2026-08-12

Run identity: `thor-rootless-r40-steamclienttermux-proot-20260812T113326Z`;
sub-run: `R40-rootless-steamclienttermux-patched-proot`.

Status: predeclared as the single next rootless A/B after the valid R39 retry
in [doc 515](515-ayn-thor-rootless-r39-cef-disable-retry-result-2026-08-12.md).

## Question and one controlled change

R39 used stock Termux PRoot and reached the pinned Turnip provider,
`vkCreateDevice`, then terminated with signal 11 before SteamUI/webhelper.
SteamClientTermux's production PRoot carries narrow Android/Pressure-Vessel
compatibility patches, including robust-list/SysV IPC and runtime mount/path
handling. R40 tests whether that PRoot implementation changes the observed
crash boundary.

The only controlled implementation change is:

```text
replace stock PRoot and its loader with the verified SteamClientTermux patched PRoot and loader
```

This is still a PRoot-only A/B. Do not import the sibling launcher's private
Mesa paths, `MESA_LOADER_DRIVER_OVERRIDE`, `TU_DEBUG`, WSI variables, private
D-Bus, `--shared-tmp`, route shadow, PulseAudio, Proton, Runtime 4, or any
other service/helper contract into R40.

## Device and freshness contract

```text
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
app_selinux=u:r:runas_app:s0:c138,c256,c512,c768
rootless_guest_mode=PRoot -0
```

Fresh scopes:

```text
/data/local/tmp/thor-rootless-r40-steamclienttermux-proot-20260812T113326Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r40/
/data/data/com.termux/files/home/.nova-rootless-r40/
```

Preserve and verify untouched:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

Fresh Steam HOME, mutable state, logs, resolver, temporary paths, X11 PID,
socket/listener, screenshots, and readiness baselines are required. Only
immutable authentication-free payloads may be reused.

## Patched PRoot provenance

The artifacts are the production build already present in the clean sibling
Termux installation on the Thor. The sibling checkout is clean at
`8d14c10195b34fe2714ba59df1680df27a852532`; the device build stamp records:

```text
patch_base_commit=a89b3732ec6ae1db674510f0843b2f3db54d0a2f
patchset_sha256=ce94daf1ae8a7fb994a4295d69006fe8604ac724bd6343daa25532f21f904f69
diff_sha256=e6fa2c6bd7073c7925f9b0d9bc5559b70aabc44515a81510301a07c99947d7c1
patches=proot-steam-android.patch proot-link2symlink-getdents.patch proot-link2symlink-host-path.patch proot-link2symlink-force-exdev.patch proot-runtime-bind-exact-detranslate.patch proot-pivot-detached-root.patch proot-pivot-drop-stale-bindings.patch proot-mountinfo-escape-paths.patch proot-runtime-mount-stack.patch proot-runtime-directory-bind-target.patch
patched_proot_bytes=300456
patched_proot_sha256=0378e0631dbf7a8bd0061b54fc167bb881c70a76109f567b682f7262a063166c
patched_loader_bytes=18232
patched_loader_sha256=eab6b2135421a2e0268832cf171d877146a9e816d7b060ce425e5017d65f08a6
```

Stage copies only inside the R40 app-owned input scope, for example:

```text
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r40/input/proot/bin/proot
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r40/input/proot/loader/loader
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r40/input/proot/lib/libtalloc.so.2.4.3
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r40/input/proot/lib/libandroid-shmem.so
```

The Termux support libraries remain fixed at the R39 values:

```text
libtalloc.so.2.4.3_sha256=3c9b207c0a6ea2896b7523e03f55d9ab0d9e88baa115d4c32b84058ff4246fbb
libandroid-shmem.so_sha256=84475798e07c8174dbbfaec70a827fdb02f19ffa69a589380c13e7507fd0e731
stock_proot_sha256=6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a
stock_proot_loader_sha256=44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04
```

The stock and patched PRoot binaries must not coexist ambiguously in the
effective command. The evidence must show the R40 patched path and hash, the
patched loader path/hash, and the unchanged support-library hashes.

## Fixed payload and launch contract

Keep the R39 retry fixture fixed:

```text
public_client_gate=selected-tree-equivalence
public_client_archive_bytes=3457524736
public_client_archive_sha256=3b54ebe8dd92ebbe304376335d59da28ebd88b1467999d39fee1c07ec98cee9a
steamrtarm64/steam=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
steamrtarm64/steamwebhelper=7a65e4f7c89dd2eeb0668f85ea0a06cf737507b7f3324407e5fc9a9a488c31d0
installed_manifest=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
holo_rootfs_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
holo_ui_audio_closure=161 packages plus 2 Debian GTK2 assets
driver_sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
icd_sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
```

Retain the R39 launch environment and flags exactly:

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
flags=-gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -cef-disable-gpu -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui
```

Use the same R28 SteamRT-first `PATH`/`LD_LIBRARY_PATH`, nested client
layout/cwd, app-owned `/tmp`, `/dev` and `/proc` bindings, resolver, direct
TCP Termux:X11, and inherited Android network. Keep `/dev/shm`, machine-id,
D-Bus, software GL, Runtime 4, Proton/FEX/DXVK, Gamescope/AHardwareBuffer,
input/audio bridges, SteamUI patches, guessed aliases, and `su`/root launch
absent.

## Consent, evidence, and classification

Before interpreting the first screenshot, capture the current display and
check whether Android's `Allow Nova Steam to access all device logs?` modal
owns focus. If present, read the visible text, scroll only within that modal,
and use targeted ADB input to choose one-time access. Never grant persistent
access or send blind coordinates when the modal is absent. Record
`log_access_consent=accepted-one-time` or `not-shown`.

Capture fresh hashes and records for the fixture, patched PRoot/loader/support
libraries, rootfs/provider, app UID/SELinux and inner PRoot identity, free
space, exact command/environment, X11 PID/listener, supervisor and Steam
bootstrap/client/SteamUI/webhelper/Vulkan logs, read-only `/dev/kgsl*` metadata,
process state, and screenshot provenance. A black X11 canvas is not a Steam
frame.

Classify in this order:

1. Any wrong hash, device, UID, scope, stale state, helper drift, auth
   exposure, or undeclared variable is invalid.
2. If the PRoot signal 11 disappears, record the furthest native SteamUI,
   webhelper, Vulkan, and display boundaries separately; do not claim WSI or
   OOBE from survival alone.
3. If the same post-`vkCreateDevice` signal 11 recurs, classify patched PRoot
   as insufficient for this boundary; do not add another variable in R40.
4. If the crash moves earlier, record the new concrete boundary rather than
   treating it as a pass.

## Cleanup and authentication boundary

After evidence capture, terminate only the verified R40 Steam/PRoot and
Termux:X11 processes, restore any temporary Termux properties byte-for-byte,
remove only the three R40 scopes, and verify no matching process or port-6077
listener remains. Recheck both rooted rollback paths and the post-cleanup free
space. Do not broad-kill Termux, clear package data, delete the rooted runtime,
or touch `/data/local/tmp/nova-active-runtime`.

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, authenticated Steam home, or `steam.token` contents may be read, copied,
backed up, committed, or exported.
