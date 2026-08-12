# AYN Thor rootless R40b current public-tree patched PRoot replay — result — 2026-08-12

Run identity: `thor-rootless-r40b-current-public-tree-steamclienttermux-proot-20260812T133500Z`;
sub-run: `R40b-rootless-steamclienttermux-patched-proot-current-tree`.

Status: **valid patched-PRoot replay; the post-`vkCreateDevice` signal-11
boundary did not move**.

The first launch invocation stopped at a staging-layout assertion because the
fresh nested client home did not yet contain the conventional `.steam` links.
That was an infrastructure defect in the fresh fixture, not an experimental
result. The links were added with the rooted comparator's documented targets,
the same launch was replayed, and the replay below is the valid observation.

## Decision

SteamClientTermux's verified production PRoot and loader did not unblock the
rootless native Steam client on the AYN Thor. The valid replay:

- passed app-UID rootless preflight;
- started a fresh direct TCP Termux:X11 server;
- launched the current sanitized public-beta tree;
- found the pinned KGSL/Turnip ICD;
- enumerated `Turnip Adreno (TM) 740`;
- reached the `vkCreateDevice` dispatch path; and
- terminated with `proot info: vpid 1: terminated with signal 11` before
  native SteamUI, `steamwebhelper`, OOBE, or a Steam frame.

This is a valid observation against the current selected-tree-equivalence
fixture, but it is not byte-identical causality against the R39 fixture. The
current-tree archive is larger because the rooted public tree contains newer
public updater payloads. The unchanged selected native hashes make this a
useful PRoot comparison, not an exact R39 replay.

The result does **not** identify the crash as a KGSL permission or SELinux
denial. The app UID could read and write the world-mode `/dev/kgsl-3d0` node,
and the process reached Turnip physical-device enumeration and the device
dispatch path. No device-node write, ioctl probe, chmod/chown, SELinux change,
or privileged Steam launch was performed.

The single next experiment is the opt-in patched-PRoot crash trace in [doc
519](519-ayn-thor-rootless-r41-patched-proot-crash-trace-predeclaration-2026-08-12.md).

## Provenance and identity

```text
branch=feat/rootless-steamclienttermux-profile
start_head=2cc0e18bd7d752403b4125a1eaaee10dbef29868
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
app_selinux=u:r:runas_app:s0:c138,c256,c512,c768
rootless_outer_uid=10138
rootless_guest_mode=PRoot -0
sibling_checkout=/Users/kurt/Developer/steamclienttermux
sibling_revision=8d14c10195b34fe2714ba59df1680df27a852532
```

The sibling checkout was clean at the recorded revision. The device patch
stamp and selected input hashes were checked before launch. No sibling Steam
payload, Steam home, authentication state, or product data was copied.

## Controlled variable and fixture qualification

The intended R40 question was: does replacing stock Termux PRoot with the
verified SteamClientTermux production PRoot and loader move the R39 crash?
R40b kept that question while using the current sanitized public tree because
the historical R39 archive could not be recovered.

```text
public_client_gate=selected-tree-equivalence-current-tree
public_client_archive_bytes=3757731328
public_client_archive_sha256=97c3140d75c551953c915fb8e06b4ec51c18b2cc32ec4af620ad64df62a77548
public_client_tar_entries=21527
forbidden_filename_scan=empty
excluded_top_level_scan=empty
```

Selected client files were unchanged from the known-good rooted comparator:

```text
steamrtarm64/steam=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
steamrtarm64/steamwebhelper=7a65e4f7c89dd2eeb0668f85ea0a06cf737507b7f3324407e5fc9a9a488c31d0
installed_manifest=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
```

The pinned Holo and provider inputs were:

```text
holo_rootfs_bytes=384971555
holo_rootfs_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
holo_ui_audio_closure=161 packages plus 2 Debian GTK2 assets
guest_rootfs_marker=gtk2_and_ui_audio_closure=pass
guest_pacman_package_count=301
libvulkan_freedreno.so_sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
freedreno-kgsl.icd.json_sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
```

The patched PRoot artifacts came from the clean sibling checkout's existing
production build:

```text
patch_base_commit=a89b3732ec6ae1db674510f0843b2f3db54d0a2f
patchset_sha256=ce94daf1ae8a7fb994a4295d69006fe8604ac724bd6343daa25532f21f904f69
diff_sha256=e6fa2c6bd7073c7925f9b0d9bc5559b70aabc44515a81510301a07c99947d7c1
patched_proot_bytes=300456
patched_proot_sha256=0378e0631dbf7a8bd0061b54fc167bb881c70a76109f567b682f7262a063166c
patched_loader_bytes=18232
patched_loader_sha256=eab6b2135421a2e0268832cf171d877146a9e816d7b060ce425e5017d65f08a6
libtalloc.so.2.4.3_sha256=3c9b207c0a6ea2896b7523e03f55d9ab0d9e88baa115d4c32b84058ff4246fbb
libandroid-shmem.so_sha256=84475798e07c8174dbbfaec70a827fdb02f19ffa69a589380c13e7507fd0e731
```

The compatibility symlink `libtalloc.so.2 -> libtalloc.so.2.4.3` was created
inside the fresh app-owned PRoot input directory because the patched binary's
SONAME requires that conventional name. It did not change the PRoot binary,
loader, Steam environment, or guest runtime.

## Fresh scopes and launch contract

```text
/data/local/tmp/thor-rootless-r40b-current-public-tree-steamclienttermux-proot-20260812T133500Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r40b/
/data/data/com.termux/files/home/.nova-rootless-r40b/
```

The effective Steam launch script retained the R39 contract:

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
unset VK_ICD_FILENAMES LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_LAYER_PATH
flags=-gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -cef-disable-gpu -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui
```

The outer command named the patched paths directly and invoked the existing
app-UID supervisor with `run -- /bin/sh /run/steam-launch.sh`. The fixed
bindings were `/dev:/dev`, `/proc:/proc`, the app-owned resolver, app-owned
`/tmp`, and the fresh client/state/home paths. No `/dev/shm`, D-Bus,
machine-id, Runtime 4, Proton, FEX/DXVK, Gamescope/AHardwareBuffer, Mesa/WSI
variables, input/audio bridge, SteamUI patch, UID change, or `su` Steam launch
was added.

The fresh nested client home initially lacked the conventional links required
by this launch contract. The corrected fixture created these app-UID links:

```text
/opt/nova-steam/home/.steam/steam    -> ../.local/share/Steam
/opt/nova-steam/home/.steam/root     -> ../.local/share/Steam
/opt/nova-steam/home/.steam/sdk32    -> ../.local/share/Steam/linux32
/opt/nova-steam/home/.steam/sdk64    -> ../.local/share/Steam/linux64
/opt/nova-steam/home/.steam/sdkarm64 -> ../.local/share/Steam/linuxarm64
/opt/nova-steam/home/.steam/bin32    -> ../.local/share/Steam/ubuntu12_32
/opt/nova-steam/home/.steam/bin64    -> ../.local/share/Steam/ubuntu12_64
```

The first missing-link launch is retained only as a setup correction. The
second launch is the valid R40b result.

## Evidence

The fresh evidence bundle is retained outside the repository at:

```text
/tmp/thor-rootless-r40b-current-public-tree-steamclienttermux-proot-20260812T133500Z-evidence/
```

Termux:X11 started as UID 10135 with PID `10080`, display `:77`, and TCP
listener port `6077`. The Android all-device-log consent dialog was absent:
`log_access_consent=not-shown`; no blind ADB acceptance was sent. The X11 log
recorded normal startup and the existing EGL legacy-drawing fallback, with no
Steam-specific X11 failure.

The valid replay's bootstrap log recorded the public-beta launch and updater
UI selection. The Vulkan trace then recorded:

```text
Vulkan Loader Version 1.3.296
Found ICD manifest file /opt/nova-kgsl-driver/freedreno-kgsl.icd.json, version 1.0.1
Searching for ICD drivers named /opt/nova-kgsl-driver/libvulkan_freedreno.so
Original order: [0] Turnip Adreno (TM) 740
Using "Turnip Adreno (TM) 740" with driver: "/opt/nova-kgsl-driver/libvulkan_freedreno.so"
Failed writing minidump, nothing to upload.
proot info: vpid 1: terminated with signal 11
```

No native SteamUI, `steamwebhelper`, `/dev/shm`, D-Bus, OOBE, or Steam-frame
evidence was produced. The current-tree fixture therefore stops at the same
post-`vkCreateDevice` boundary observed with stock PRoot.

Selected evidence hashes:

```text
prelaunch.png=118653 bytes sha256=a4e4de4e4b4348529bd77184bdaaa538ac9fdd3d656306cf179ca98be5583577
postlaunch-replay.png=118653 bytes sha256=a4e4de4e4b4348529bd77184bdaaa538ac9fdd3d656306cf179ca98be5583577
supervisor-console-replay.log=16090 bytes sha256=d1f9ed8f57430aa6cf2f8490947097c7129f0ef66d5630b45c88c83e08a23103
rootless-supervisor.log=2480 bytes sha256=ad172939d4c9e28f2e25baa670eb61e5d90f610db3c171045683855c0052bec1
bootstrap_log.txt=435 bytes sha256=b0f67ec09e8928f6f0fd22160aa5579e73304f91d7e43c22d91fd0fc145ee6df
updateui_child.txt=99 bytes sha256=3d0f9e9d60bdb945ffbe5a610b2541f273ba2e74d613e6cc2b8c9ffee36b7721
termux-x11.log=3271 bytes sha256=ecfc726a11e92753c58f517b51bc2f9e8b0e11656790cf32c0227ff1eb320b85
```

The screenshot is lifecycle evidence only: it shows the Nova launcher in its
stopped state, not a Steam frame or QR screen.

Read-only device-access evidence was:

```text
/dev/kgsl-3d0=crw-rw-rw- system system u:object_r:gpu_device:s0 487,0
app_uid_test_read=0
app_uid_test_write=0
```

No ioctl or device mutation was attempted. The selected client, provider, and
patched PRoot hashes are also retained in `selected-client-hashes.txt`,
`provider-hashes.txt`, and `patched-proot-hashes.txt` in the evidence bundle.

## Cleanup and rollback

After capture, only the exact R40b scopes were removed. The exact X11 PID
`10080` was stopped through the fresh Termux helper before its state was
removed. Verification passed:

```text
run_scope_absent
app_scope_absent
termux_scope_absent
port_6077_absent
rooted_rootfs_present
active_runtime_present
post_cleanup_free_kib=16236092
```

The matching Steam/PRoot/webhelper/X11 processes were absent after cleanup;
the remaining Nova APK process was only the app launcher. The preserved
rollback paths remain:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Next boundary

The next experiment is deliberately diagnostic rather than another runtime
fix: enable the sibling PRoot's opt-in `PROOT_CRASH_LOG=1` tracer for one
fresh, bounded replay. SteamClientTermux documents that this tracer is
expensive and must not be enabled by default; it can reveal the translated
faulting instruction and PRoot boundary without importing the sibling
launcher’s shared-`/tmp`, D-Bus, Mesa, audio, Runtime 4, Proton, or helper
contracts. See [doc 519](519-ayn-thor-rootless-r41-patched-proot-crash-trace-predeclaration-2026-08-12.md).

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, authenticated Steam home, or `steam.token` contents were read, copied,
backed up, committed, or exported.
