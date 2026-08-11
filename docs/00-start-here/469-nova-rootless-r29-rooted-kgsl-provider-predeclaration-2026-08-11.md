# Nova rootless R29 — rooted KGSL/Turnip provider parity predeclaration — 2026-08-11

Run ID: `nova-rootless-r29-rooted-kgsl-20260811T141331Z`;
sub-run: `R29-rootless-supervisor-rooted-kgsl-turnip-provider`.

Status: predeclared after R28 crossed the native `vgui2_s` module boundary and
reached SteamUI/webhelper startup, then failed to enumerate a Vulkan physical
device. R29 changes only the Vulkan provider visibility contract by carrying
the exact driver and ICD already used by the rooted happy path into the
app-owned rootless guest.

## Hypothesis

R28 deliberately omitted the rooted `/opt/nova-kgsl-driver` payload. The
client therefore reported:

```text
CVulkanTopology: failed to get physical device count
vkEnumeratePhysicalDevices failed, unable to init and enumerate GPUs with Vulkan.
BInit - Unable to initialize Vulkan!
```

The rooted launcher’s hardware path selects the KGSL Turnip ICD at
`/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`. If the same driver and ICD
are visible inside the rootless PRoot guest, R29 should cross the Vulkan
physical-device topology boundary while preserving the R28 native SteamUI
result. If it still fails, the result will distinguish a missing provider
payload from an Android app-UID/SELinux device-access boundary.

This is a provider-only A/B. It does not add `/dev/shm`, machine-id, D-Bus,
UID/GID changes, `LD_PRELOAD`, Runtime 4, Proton, Gamescope/AHardwareBuffer,
SteamUI patches, or a different client tree.

## Exact provider artifacts

Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
`arm64-v8a`.

The rooted source and checked-in build asset are byte-identical:

```text
rooted_source=/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs/opt/nova-kgsl-driver/libvulkan_freedreno.so
repo_asset=android/nova-lab/build/apk-assets/libvulkan_freedreno.so
driver_size=12364688
driver_sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810

rooted_icd=/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
repo_icd=android/nova-lab/build/apk-assets/freedreno-kgsl.icd.json
icd_size=194
icd_sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
```

The ICD content is fixed:

```json
{
    "ICD": {
        "api_version": "1.4.318",
        "library_arch": "64",
        "library_path": "/opt/nova-kgsl-driver/libvulkan_freedreno.so"
    },
    "file_format_version": "1.0.1"
}
```

Stage these two files into the new app-owned guest rootfs at:

```text
/opt/nova-kgsl-driver/libvulkan_freedreno.so
/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
```

The source rooted runtime is read-only for this experiment. Do not modify or
replace the preserved rooted rollback.

## Fixed R28 inputs

Recreate the same sanitized current rooted public Steam tree and require the
same selected hashes before staging. No authentication/session data may be
read or copied:

```text
public_archive_bytes=3447515136
public_archive_sha256=4c62a8e35144b653864c31d84e682814a82384c3746001293e019d98bde25288
installed_manifest_sha256=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
steamrtarm64/steam_sha256=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so_sha256=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so_sha256=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
rootfs_archive_size=384971555
rootfs_archive_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
holo_ui_audio_package_closure=161 packages
```

Keep fixed from R28:

- rooted nested client root `/opt/nova-steam/home/.local/share/Steam`;
- `HOME=/opt/nova-steam/home`, `USER=steam`, `LOGNAME=steam`, `LANG=C`,
  `LC_ALL=C`, and `XDG_RUNTIME_DIR=/tmp/nova-steam-runtime`;
- rooted SteamRT-first `PATH` and `LD_LIBRARY_PATH` ordering;
- app-UID PRoot `-0`, the same Holo guest rootfs, `/proc`, resolver, and
  `/dev` binding;
- direct Termux:X11 with guest `DISPLAY=127.0.0.1:77` and a fresh listener;
- inherited Android network, input, audio, and storage behavior;
- client flags `-gamepadui -steamos3 -steampal -steamdeck
  -no-cef-sandbox -nobootstrapperupdate -skipinitialbootstrap
  -no-child-update-ui`; and
- fresh app-owned state with no Steam authentication data.

Explicitly keep these variables unset to make the provider change visible:

```text
LD_PRELOAD=unset
MESA_LOADER_DRIVER_OVERRIDE=unset
GALLIUM_DRIVER=unset
LIBGL_ALWAYS_SOFTWARE=unset
VK_IMPLICIT_LAYER_PATH=unset
```

## Changed launch contract

After the existing rootless supervisor enters PRoot, export only the ICD
selection in addition to the R28 environment:

```text
export VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
```

The exact guest command is:

```text
/bin/sh -c 'export HOME=/opt/nova-steam/home; export USER=steam; export LOGNAME=steam; export LANG=C; export LC_ALL=C; export XDG_RUNTIME_DIR=/tmp/nova-steam-runtime; export PATH=/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/bin:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/bin:/usr/bin:/bin; export LD_LIBRARY_PATH=/opt/nova-steam/home/.local/share/Steam/steamrtarm64:/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu:/usr/lib:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu/pulseaudio; unset LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_LAYER_PATH; export VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json; mkdir -p "$XDG_RUNTIME_DIR"; cd /opt/nova-steam/home/.local/share/Steam; exec /opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui'
```

## Device scope and acceptance

Use fresh, separately named scopes:

```text
/data/local/tmp/nova-rootless-r29-rooted-kgsl-20260811T141331Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r29/
/data/data/com.termux/files/home/.nova-rootless-r29/
```

Before launch, reread the lifecycle contract and run exact-scope cleanup.
Verify rootless preflight, free space, app-owned driver/ICD hashes and mode,
fresh Termux:X11 PID/listener, command/environment/cwd, Steam/client,
`steamsysinfo`, SteamUI, and webhelper logs. Pull fresh logs and screenshot
before teardown.

The acceptance boundary is:

1. `steamsysinfo` can enumerate the KGSL/Turnip physical device, or the logs
   explicitly classify app-UID/SELinux/device access as the blocker;
2. the R28 `vgui2_s`-free SteamUI startup remains intact; and
3. any later `/dev/shm`, D-Bus, X11, or webhelper failure is recorded as a
   later boundary rather than conflated with Vulkan provider visibility.

Do not add a shared-memory directory, machine-id, D-Bus daemon, root helper,
or compatibility patch in this run. Remove only the exact R29 app, Termux,
archive, and run scopes after evidence capture; preserve:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

No Steam authentication secret may be read, copied, backed up, or exported.
