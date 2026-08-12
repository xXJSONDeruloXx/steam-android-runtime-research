# AYN Thor rootless R39 CEF-disable retry — result — 2026-08-12

Run identity: `thor-rootless-r39-public-beta-cef-disable-retry-20260812T024229Z`;
sub-run: `R39-retry-current-public-beta-cef-disable-gpu`.

Status: **valid rootless app-UID run; `-cef-disable-gpu` did not close the
post-`vkCreateDevice` PRoot signal-11 boundary**.

The first R39 attempt was invalid before Steam startup because its
Termux:X11 helper used the default state directory. The retry recorded in
[doc 514](514-ayn-thor-rootless-r39-cef-disable-retry-predeclaration-2026-08-12.md)
corrected only that lifecycle defect and is the result reported here.

## Decision

Adding only `-cef-disable-gpu` did not allow the rootless Steam process to
survive farther. The valid retry:

- passed app-UID rootless preflight;
- used the sanitized current public-beta selected-tree fixture;
- found the pinned `VK_DRIVER_FILES` ICD;
- loaded the pinned Turnip provider and enumerated `Turnip Adreno (TM) 740`;
- reached `vkCreateDevice`; and
- terminated with `proot info: vpid 1: terminated with signal 11` before
  native SteamUI, `steamwebhelper`, OOBE, or a Steam frame.

This is evidence for a PRoot/Turnip/device-use crash boundary, not a CEF-only
failure. It is not evidence for `/dev/shm`, D-Bus, WSI presentation, or KGSL
denial because the process stopped before those boundaries produced fresh
diagnostics. The next experiment is the patched-PRoot-only replay in [doc
516](516-ayn-thor-rootless-r40-steamclienttermux-proot-predeclaration-2026-08-12.md).

## Provenance and controlled variable

```text
branch=feat/rootless-steamclienttermux-profile
start_head=07433cf40180e9238f2371806aff254e35faeb5d
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
app_selinux=u:r:runas_app:s0:c138,c256,c512,c768
rootless_outer_uid=10138
rootless_inner_identity=uid=0(root) via PRoot -0
rootfs_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
public_client_gate=selected-tree-equivalence
public_client_archive_bytes=3457524736
public_client_archive_sha256=3b54ebe8dd92ebbe304376335d59da28ebd88b1467999d39fee1c07ec98cee9a
stock_proot_sha256=6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a
stock_proot_loader_sha256=44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04
```

Relative to the R33/rootless public-beta baseline, the only launch-variable
change was the Steam flag:

```text
add -cef-disable-gpu
```

The Vulkan selector, loader diagnostics, Holo closure, client files, PRoot
implementation, app UID, direct TCP X11, inherited Android network, launch
environment, and remaining Steam flags stayed fixed. Software-GL variables,
`/dev/shm`, machine-id, D-Bus, Runtime 4, Proton, FEX/DXVK, Gamescope,
AHardwareBuffer, input/audio helpers, SteamUI patches, and privileged Steam
launch were absent.

The immutable selected client files were:

```text
steamrtarm64/steam=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
steamrtarm64/steamwebhelper=7a65e4f7c89dd2eeb0668f85ea0a06cf737507b7f3324407e5fc9a9a488c31d0
installed_manifest=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
libvulkan_freedreno.so=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
freedreno-kgsl.icd.json=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
```

The source tree was the preserved rooted public client under the documented
sanitization boundary. No `appcache/`, `config/`, `logs/`, `steamapps/`,
`userdata/`, `.crash`, `local.vdf`, `update_hosts_cached.vdf`, `ssfn*`,
`loginusers.vdf`, `steam.token`, `user*.vdf`, `localconfig.vdf`, or
`sharedconfig.vdf` path was staged.

## Fresh run and evidence

The exact device scopes were:

```text
/data/local/tmp/thor-rootless-r39-public-beta-cef-disable-retry-20260812T024229Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r39-retry/
/data/data/com.termux/files/home/.nova-rootless-r39/
```

The run used a fresh Termux:X11 instance, PID `32113`, on display
`127.0.0.1:77` with TCP listener port `6077`. The Android all-device-log
consent dialog was not shown: `log_access_consent=not-shown`; therefore no
blind ADB acceptance was sent.

The effective launch record included:

```text
VK_DRIVER_FILES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
VK_LOADER_DEBUG=all
unset VK_ICD_FILENAMES LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_LAYER_PATH
flags=-gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -cef-disable-gpu -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui
DISPLAY=127.0.0.1:77
```

Fresh evidence was retained outside the repository at:

```text
/tmp/thor-rootless-r39-public-beta-cef-disable-retry-20260812T024229Z-evidence/
```

Selected evidence hashes:

```text
bootstrap_log.txt=63d78a8a04554f9fd805786a0ff012936389977496b64acf5dc42d2d754892f8
rootless-supervisor.log=afc822c5db93c27ebdf6f3d11032c53c5ad93c2839c5046f6622aa37ae10b1dd
supervisor-console.log=e0fc382578708421ae9a6d03c635d5f192190a2c6bfe26413627110ce4d44c5d
termux-x11.log=b3c924b6e9f1771a3140d332c7bff948d467f0b834c82f02f1556a2889019bd1
launch-contract.txt=28f8b98c4013722d29fbc1ae5033b849c7dbaf540357a82789f97ab62f0e3bfa
```

The Vulkan-loader trace recorded:

```text
Found ICD manifest file /opt/nova-kgsl-driver/freedreno-kgsl.icd.json
Turnip Adreno (TM) 740
Using "Turnip Adreno (TM) 740" with driver: "/opt/nova-kgsl-driver/libvulkan_freedreno.so"
proot info: vpid 1: terminated with signal 11
```

The screenshot was only transport/lifecycle evidence:

```text
path=/tmp/thor-rootless-r39-public-beta-cef-disable-retry-20260812T024229Z-evidence/screenshot.png
dimensions=1920x1080
bytes=51414
sha256=62763ac00c86c3ded6a6f1ab16868eda655ceafdf0a8ab6bda47157a3d6b73fa
visible=Nova launcher says the session is stopped; no Steam frame or QR
```

## Cleanup and rollback

After capture, the exact R39 app, device, and Termux scopes were removed. The
verified R39 Steam/PRoot/webhelper/X11 processes were absent, port `6077` had
no listener, and the rooted rollback paths remained present:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

Termux properties were restored byte-for-byte to SHA-256
`89094537f49531dc9b380a0dec3a441b2fb92577e0a4f1db505790eb8b7025b0`.

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, authenticated Steam home, or `steam.token` contents were read, copied,
backed up, committed, or exported.
