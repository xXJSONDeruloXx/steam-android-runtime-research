# AYN Thor rootless R40b current public-tree patched PRoot replay — predeclaration — 2026-08-12

Run identity: `thor-rootless-r40b-current-public-tree-steamclienttermux-proot-20260812T133500Z`;
sub-run: `R40b-rootless-steamclienttermux-patched-proot-current-tree`.

Status: predeclared as a provenance-qualified companion to [doc
516](516-ayn-thor-rootless-r40-steamclienttermux-proot-predeclaration-2026-08-12.md).
The exact R40 R39-fixture archive is no longer present and cannot be
reconstructed from the current rooted tree. R40b therefore preserves the
patched-PRoot question while explicitly using the current sanitized public
tree as a selected-tree-equivalence fixture. It must not be compared as a
byte-identical replay of R39.

## Question and controlled change

R39 reached the pinned Turnip provider and `vkCreateDevice`, then terminated
with a PRoot signal 11 before native SteamUI or webhelper. R40 asks whether
SteamClientTermux's verified patched PRoot and loader move that boundary.

R40b changes only the PRoot implementation and loader relative to the current
rootless CEF-disable profile. The public client is the current sanitized tree,
not the unavailable R39 archive. Do not import the sibling launcher's Mesa,
WSI, D-Bus, shared-`/tmp`, audio, route, Runtime 4, Proton, or helper
environment.

## Device, scope, and preservation

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
/data/local/tmp/thor-rootless-r40b-current-public-tree-steamclienttermux-proot-20260812T133500Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r40b/
/data/data/com.termux/files/home/.nova-rootless-r40b/
```

Preserve and verify untouched:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Public-tree fixture gate

The archive was rebuilt from the preserved rooted public client with the
existing authentication-free exclusions. Its complete fingerprint is:

```text
public_client_gate=selected-tree-equivalence-current-tree
public_client_archive_bytes=3757731328
public_client_archive_sha256=97c3140d75c551953c915fb8e06b4ec51c18b2cc32ec4af620ad64df62a77548
public_client_tar_entries=21527
forbidden_filename_scan=empty
excluded_top_level_scan=empty
```

The archive differs from the R39 fixture because the rooted public tree now
contains 13 newer public updater payloads in `package/`, approximately 300 MB
of additional bytes. The following selected files remain unchanged:

```text
steamrtarm64/steam=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
steamrtarm64/steamwebhelper=7a65e4f7c89dd2eeb0668f85ea0a06cf737507b7f3324407e5fc9a9a488c31d0
installed_manifest=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
```

No `appcache/`, `config/`, `logs/`, `steamapps/`, `userdata/`, `.crash`,
`local.vdf`, `update_hosts_cached.vdf`, `ssfn*`, `loginusers.vdf`,
`steam.token`, `user*.vdf`, `localconfig.vdf`, or `sharedconfig.vdf` path may
be staged. No authenticated Steam home or mutable Steam state may be read.

## Patched PRoot provenance

Use only the already verified production artifacts from the clean sibling
checkout `/Users/kurt/Developer/steamclienttermux` at
`8d14c10195b34fe2714ba59df1680df27a852532`:

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

Stage these only under the fresh app-owned R40b input scope. The effective
command must name the patched binary and loader directly; the stock PRoot
must not remain ambiguous in the selected path.

## Fixed Holo, provider, and launch contract

Keep the R39 retry contract fixed apart from the PRoot implementation and the
documented current-tree fixture:

```text
holo_rootfs_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
holo_ui_audio_closure=161 packages plus 2 Debian GTK2 assets
driver_sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
icd_sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
VK_DRIVER_FILES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
VK_LOADER_DEBUG=all
DISPLAY=127.0.0.1:77
```

Unset `VK_ICD_FILENAMES`, `LD_PRELOAD`, `MESA_LOADER_DRIVER_OVERRIDE`,
`GALLIUM_DRIVER`, `LIBGL_ALWAYS_SOFTWARE`, and `VK_IMPLICIT_LAYER_PATH`.
Retain the R28 SteamRT-first `PATH`/`LD_LIBRARY_PATH`, nested client layout,
fresh app-owned HOME/state/tmp, `/dev` and `/proc` bindings, resolver, direct
TCP Termux:X11, inherited Android network, and flags:

```text
-gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -cef-disable-gpu
-nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui
```

No `/dev/shm`, machine-id, D-Bus, software-GL variable, Runtime 4, Proton,
FEX/DXVK, Gamescope/AHardwareBuffer, input/audio bridge, SteamUI patch,
guessed alias, UID/GID change, `su` Steam launch, device-node chmod/chown, or
SELinux change is allowed.

## Evidence and classification

Before launch capture the current screen and record whether the Android
all-device-log consent dialog owns focus. If present, read and scroll only
within that dialog and select one-time access with targeted ADB input; never
send blind coordinates or grant persistent access. If absent record
`log_access_consent=not-shown`.

Capture fresh artifact hashes, app UID/SELinux identity, inner PRoot identity,
free space, exact command/environment, X11 PID/listener, supervisor and Steam
logs, Vulkan/Turnip lines, read-only `/dev/kgsl*` metadata, process state, and
screenshot provenance.

Classify in this order:

1. Wrong hash, device, UID, scope, freshness, environment, or authentication
   exposure is invalid.
2. If signal 11 disappears, record the furthest Vulkan, native SteamUI,
   webhelper, display, `/dev/shm`, and D-Bus boundaries separately.
3. If the same post-`vkCreateDevice` signal 11 recurs, patched PRoot is
   insufficient for this boundary.
4. If the crash moves earlier, record the concrete new boundary.

R40b cannot claim byte-equivalent causality against R39; its valid result is a
patched-PRoot observation against the selected-file-equivalent current tree.

After capture, terminate only the exact R40b Steam/PRoot/X11 processes,
remove only the three R40b scopes, verify port 6077 and matching processes are
gone, and verify both rooted rollback paths remain. Never export or back up
Steam authentication secrets.
