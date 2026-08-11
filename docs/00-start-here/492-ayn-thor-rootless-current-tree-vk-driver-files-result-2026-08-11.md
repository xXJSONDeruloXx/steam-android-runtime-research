# AYN Thor rootless current-tree `VK_DRIVER_FILES` selector A/B — result — 2026-08-11

Run identity: `thor-rootless-current-tree-vk-driver-files-20260811T200332Z`;
sub-run: `R31-current-tree-selector-equivalence`.

Status: **valid infrastructure/provenance run; no Vulkan provider boundary was
reached**.

Classification: **`selector-nondiscriminating` (qualified early-exit
observation)**. The run did not reproduce the historical R29 `SIGSEGV`, but it
also did not reach the Vulkan loader, SteamUI, or `steamwebhelper`. This label
means that the selector did not close the provider boundary; it does **not**
mean that the R36 Vulkan error repeated, that KGSL access was denied, or that
the ICD was loaded.

## Result in one paragraph

The rootless Thor fixture was valid, the fresh Termux:X11 server accepted a
client, and the Android app UID could see the KGSL device node's metadata. The
only declared guest-environment change from the successful R36 current-tree
replay was replacing both unset Vulkan selectors with
`VK_DRIVER_FILES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`. Steam wrote
only its three early bootstrap lines, remained a single sleeping process, and
then the PRoot session reported `vpid 1: terminated with signal 35`. No
`libvulkan`, Turnip, KGSL, SteamUI, or webhelper process evidence appeared.
Therefore this run narrows the next question to “did the relevant process
reach and honor the loader selector, or did the `-0`/early-runtime boundary
terminate first?” It does not support a rootless KGSL/SELinux diagnosis.

## Provenance and identity

```text
branch=feat/rootless-steamclienttermux-profile
start_head=1ccdc58da43c0ed749c7a66ac36ae742186e2c5f
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
app_selinux=u:r:runas_app:s0:c138,c256,c512,c768
root_available=uid=0(root) gid=0(root) context=u:r:magisk:s0
sibling=/Users/kurt/Developer/steamclienttermux
sibling_head=8d14c10195b34fe2714ba59df1680df27a852532
```

The historical exact R31 archive remains unavailable. This run used the
current sanitized public-beta tree under the equivalence gate from [doc
491](491-ayn-thor-rootless-current-tree-vk-driver-files-predeclaration-2026-08-11.md):

```text
archive_bytes=3457524736
archive_sha256=3b54ebe8dd92ebbe304376335d59da28ebd88b1467999d39fee1c07ec98cee9a
installed_manifest_sha256=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
package/beta_sha256=ef339938036ee25c4f533210a35791d5faf9f69dcbc72cce173263005500f9e4
steamrtarm64/steam_sha256=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so_sha256=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so_sha256=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
steamrtarm64/steamwebhelper_sha256=7a65e4f7c89dd2eeb0668f85ea0a06cf737507b7f3324407e5fc9a9a488c31d0
holo_rootfs_bytes=384971555
holo_rootfs_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
holo_ui_audio_closure=161 packages
libvulkan_freedreno.so_sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
freedreno-kgsl.icd.json_sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
proot_sha256=6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a
```

The archive is a staging fingerprint, not a claim of byte identity with the
unavailable historical archive. The selected files, installed manifest, and
authentication-free entry scan were the validity gate.

## Controlled variable and fixture corrections

Relative to [doc 490](490-ayn-thor-rootless-public-beta-equivalence-replay-result-2026-08-11.md),
the only effective guest-environment change in the measured launch was:

```text
unset VK_ICD_FILENAMES
export VK_DRIVER_FILES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
unset LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_LAYER_PATH
```

The fixed contract remained Holo ARM64, app-UID PRoot `-0`, the nested
`/opt/nova-steam/home/.local/share/Steam` layout, SteamRT-first library order,
fresh app-owned Steam state, inherited Android networking, direct TCP
Termux:X11, `DISPLAY=127.0.0.1:77`, and the predeclared Steam flags.

Three setup issues were corrected before the measured launch and are not
treated as results: the exact package files were moved into app-owned input
storage so the guest closure could unpack them; the supervisor's client bind
was corrected to the parent containing the `steam-client` tree; and the fresh
HOME received the rooted-compatible
`.steam/steam -> ../.local/share/Steam` link. The mutable HOME/state paths
were removed between attempts. The measured launch began only after
`nova_rootless_preflight=pass`.

## Launch and display evidence

The supervisor recorded:

```text
nova_rootless_preflight=pass uid=10138
nova_rootless_free_kib=10283840
nova_rootless_exec=proot display=127.0.0.1:77
```

The fresh Termux:X11 server was PID `14284`; its Android Activity process was
PID `14412`; port `6077` listened on IPv4 and IPv6. An X11 handshake using
`xprop -root _NET_SUPPORTING_WM_CHECK` succeeded. The X11 log observed an
`Xbox Wireless Controller` and a 1920x970 drawable after Android insets.

The Android all-device-log consent dialog was not shown:
`log_access_consent=not-shown`. No blind scroll or ADB tap was sent. This
matches the lifecycle contract: if the dialog is absent, record that fact and
do not use a consent action as a substitute for run evidence.

The final screenshot was captured before teardown:

```text
path=/tmp/thor-rootless-current-tree-vk-driver-files-20260811T200332Z-evidence/steam-selector-live.png
dimensions=1920x1080
bytes=41405
sha256=52ee8c2ab1e8a3bc825fa1dba1d1d5df433b339fe189df11bfd87c5796b07eb3
visible=black Termux:X11 canvas, cursor, Android bars and extra-key row; no Steam frame
```

The fresh X11-start screenshot was also 1920x1080, 42165 bytes, SHA-256
`60f478d3d18b8fbc8721e7f8652d496a146ee38ab84db53d32f5444088dd2cd2`.

## Measured startup result

The fresh bootstrap log was only 392 bytes, SHA-256
`7c73a330a77cad7717cac10e2085e4c96279454abfaf2ccb9e2a3baec6f4e1f3`, and
contained:

```text
[2026-08-11 20:34:41] Startup - updater built Aug  7 2026 20:15:47
[2026-08-11 20:34:41] Startup - Steam Client launched with: '/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam' '-gamepadui' '-steamos3' '-steampal' '-steamdeck' '-no-cef-sandbox' '-skipinitialbootstrap' '-no-child-update-ui'
[2026-08-11 20:34:41] Opted in to client beta 'steamdeck_publicbeta' via beta file
```

The old `vgui2_s` fatal was not observed, but this is only a negative
observation before the client reached that stage. Steam PID `18940` remained
one sleeping process; it had no `libvulkan`, `libvulkan_freedreno`, or KGSL
mapping, and no SteamUI or `steamwebhelper` child/log appeared. After the
bounded wait the outer session reported:

```text
proot info: vpid 1: terminated with signal 35
```

The official PRoot documentation also presents `vpid 1: terminated with
signal N` as a PRoot-level diagnostic form; the signal number alone is not a
Vulkan, KGSL, or SELinux attribution. See [PRoot's official
documentation](https://proot-me.github.io/blog/ish-on-ios/).

No fresh evidence reached any of these later boundaries, so none is
classified by this run:

- Vulkan ICD discovery or physical-device enumeration;
- `CVulkanTopology`, `vkEnumeratePhysicalDevices`, or WSI/presentation;
- Chromium `/dev/shm`;
- D-Bus or machine-id;
- SteamUI, webhelper, OOBE, or QR login.

## Provider and loader evidence

The pinned provider files were present at their declared guest paths with the
declared hashes. Read-only device metadata under the app context showed:

```text
/dev/kgsl-3d0: crw-rw-rw- system system u:object_r:gpu_device:s0 487,0
app_uid=10138
app_selinux=u:r:runas_app:s0:c138,c256,c512,c768
```

This proves pathname visibility and DAC metadata only. It does not prove a
successful device open or KGSL ioctl, and no SELinux denial was captured.

Static inspection established that both candidate Linux loaders contain the
selector names:

```text
holo=/usr/lib/libvulkan.so.1.4.328
holo_sha256=9858a253ce4a125eb0408f5b309657dd96f5f032b630d2cd8a54a8f445eda238
steamrt=/opt/nova-steam/home/.local/share/Steam/steamrtarm64/libvulkan.so.1
steamrt_sha256=d114974137bb80154f08c12531a2adef6431dde112566a0d2625e307fbd7eedf
strings=VK_DRIVER_FILES,VK_ADD_DRIVER_FILES,VK_ICD_FILENAMES,VK_LOADER_DEBUG
```

This is useful static evidence, not proof that either loader was executed in
the failed Steam process. The current Vulkan Loader contract documents
`VK_DRIVER_FILES` and the older `VK_ICD_FILENAMES` as selector mechanisms,
with the newer variable taking precedence when both are present, and warns
that selector variables are ignored for elevated/super-user applications.
See the [official Vulkan Loader driver interface
documentation](https://github.com/KhronosGroup/Vulkan-Loader/blob/main/docs/LoaderDriverInterface.md).

That last rule creates a concrete, testable rootless hypothesis: the guest is
launched with PRoot `-0`, so the guest identity is virtual root even though
the real Android process is UID 10138. We have not observed the loader in this
run and therefore cannot say that it ignored the selector. The next diagnostic
must capture the loader's own decision before any UID or PRoot change is
considered.

## Rooted versus rootless matrix

| Path | Current client | Session contract | Measured boundary |
|---|---|---|---|
| Rooted comparator, [doc 486](486-ayn-thor-rooted-known-good-oobe-comparison-result-2026-08-11.md) | Same selected public-beta hashes | Root-side mount/chroot, `/dev/shm`, D-Bus/machine-id, software CEF/GL controls, updater/helper/audio/controller setup | Steam OOBE through QR sign-in |
| Rootless R36, [doc 490](490-ayn-thor-rootless-public-beta-equivalence-replay-result-2026-08-11.md) | Same selected public-beta hashes | App UID, PRoot `-0`, direct X11, no `/dev/shm` or D-Bus | Native SteamUI/webhelper startup; then Vulkan, `/dev/shm`, and D-Bus failures |
| Current Thor selector A/B | Same current-tree selected hashes | R36 contract plus only `VK_DRIVER_FILES` | Early PRoot signal-35 exit; no provider evidence |

The rooted result is therefore not proof that rooted KGSL access is the
missing ingredient: its software CEF/GL and root-only service contract can
avoid the rootless Vulkan/webhelper boundary altogether. Conversely, the
current rootless result is not proof that app-UID KGSL access is denied. The
measured difference is an early process/loader boundary, and the virtual-root
selector rule is the first concrete hypothesis to test.

## Sister-repository and web findings

The audited `steamclienttermux` revision
`c0ada6ea2f56a96872af2190f69f4b5385c68ee2` uses a deliberately larger child
contract: `VK_DRIVER_FILES`, private Mesa paths, `LIBGL_DRIVERS_PATH`,
`MESA_LOADER_DRIVER_OVERRIDE=kgsl`, `TU_DEBUG=noconform`, WSI present-mode
tuning, software-rendered CEF, private D-Bus, PulseAudio, network helpers,
and a patched PRoot. See its [ARM64 launcher](https://github.com/huntergdavis/steamclienttermux/blob/c0ada6ea2f56a96872af2190f69f4b5385c68ee2/bin/steam-arm)
and [architecture notes](https://github.com/huntergdavis/steamclienttermux/blob/c0ada6ea2f56a96872af2190f69f4b5385c68ee2/docs/ARCHITECTURE.md).

That prior art confirms that `VK_DRIVER_FILES` can be part of a working
Android/PRoot Steam stack, but it does not prove that the selector alone is
enough on Thor. It also gives us no permission to import the Mesa, WSI,
D-Bus, audio, or patched-PRoot changes into this A/B. Those remain separate
future contracts.

## Cleanup and rollback

Only the current run's exact scopes were removed:

```text
/data/local/tmp/thor-rootless-current-tree-vk-driver-files-20260811T200332Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r31-current-tree/
/data/data/com.termux/files/home/.nova-rootless/
```

Post-cleanup checks recorded:

```text
device_run_scope=absent
app_run_scope=absent
termux_helper_scope=absent
matching_steam_proot_webhelper_x11_processes=none
port_6077_listener=absent
termux.properties_sha256=89094537f49531dc9b380a0dec3a441b2fb92577e0a4f1db505790eb8b7025b0
rooted_rollback_root=/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs (present)
rooted_active_marker=/data/local/tmp/nova-active-runtime (present)
post_cleanup_available_kib=21842568
```

The non-sensitive host evidence remains outside the repository at
`/tmp/thor-rootless-current-tree-vk-driver-files-20260811T200332Z-evidence/`.
The staging archive and mutable device state were removed after hashing.

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, authenticated Steam home, or `steam.token` contents were read, copied,
backed up, committed, or exported.

## Next decision

The only next experiment predeclared from this result is [doc
493](493-ayn-thor-rootless-current-tree-vk-loader-debug-predeclaration-2026-08-11.md):
retain `VK_DRIVER_FILES` and add only `VK_LOADER_DEBUG=all`. Its purpose is to
observe whether the actual SteamRT loader honors, ignores, opens, or rejects
the configured manifest before changing PRoot identity, Mesa variables,
`/dev/shm`, D-Bus, or any other subsystem.
