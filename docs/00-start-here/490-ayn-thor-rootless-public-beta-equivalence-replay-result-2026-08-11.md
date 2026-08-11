# AYN Thor rootless current public-beta tree equivalence replay — result — 2026-08-11

Run identity: `thor-rootless-public-beta-equivalence-replay-20260811T191931Z`;
sub-run: `Thor-rootless-current-public-beta-tree-equivalence`.

Status: **valid selected-tree equivalence pass for the native client-loader
boundary; overall rootless SteamUI/OOBE run stopped at later session
prerequisites**.

This was not the historical R28 archive: the original `3447515136`-byte
archive and its hash were unavailable. The run used the freshly recreated,
authentication-free current public-beta tree from the preserved rooted
runtime. It therefore proves selected-file/tree equivalence, not archive
container identity.

## Decision

The current public-beta client is not rootless-blind to `vgui2_s`. With the
rootless Holo/PRoot, nested Steam layout, SteamRT-first environment, direct
TCP Termux:X11, app UID, and fresh Steam state, this run:

- launched the native ARM64 Steam client;
- did **not** reproduce `Fatal Error: Could not load module
  'bin/vgui2_s.dll'` or `Error: Could not load 'vgui2_s.so'`;
- initialized native SteamUI and `CSteamUINetworkController`;
- started `steamwebhelper` repeatedly; and
- reached the same later Vulkan/webhelper boundary seen by R28.

The rootless failure is therefore not a general inability to load the
current Steam client or SteamUI. The measured differences from the rooted
known-good path are the surrounding Linux session contract: rooted startup
provided `/dev/shm`, machine-id and D-Bus services, root-side SteamOS helpers,
and a different CEF/display environment. The run does not identify which of
those is sufficient by itself; that remains an A/B question.

The next experiment remains the already-predeclared Thor R31
`VK_DRIVER_FILES`-only provider-selector test in [doc
475](475-ayn-thor-rootless-r31-vk-driver-files-replication-predeclaration-2026-08-11.md).
Do not combine it with `/dev/shm`, D-Bus, Runtime 4, Proton, Gamescope,
AHardwareBuffer, or packaging changes.

## Provenance and identity

```text
branch=feat/rootless-steamclienttermux-profile
start_head=6be029bf4fb8d081fff441241a82aae1a5ccb55b
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
app_selinux=u:r:runas_app:s0:c138,c256,c512,c768
root_identity=uid=0(root) gid=0(root) context=u:r:magisk:s0
preflight_getenforce=Permissive
later_root_getenforce_query=Permission denied (read-only query)
sibling=/Users/kurt/Developer/steamclienttermux
sibling_head=8d14c10195b34fe2714ba59df1680df27a852532
```

The sibling checkout was clean at the start. No authentication-bearing Steam
home was read or used. The APK's app UID was the real outer UID; the inner
PRoot identity reported `uid=0(root)` only as PRoot's virtual root and did not
use `su`, `chroot`, or a privileged launch.

The exact run scopes were:

```text
/data/local/tmp/thor-rootless-public-beta-equivalence-replay-20260811T191931Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r36/
/data/data/com.termux/files/home/.nova-rootless/
```

## Immutable inputs

```text
public_beta_archive_bytes=3457525760
public_beta_archive_sha256=9a3507ce029c0aebe28ebd54ae03f79b56b1899e6ad4e530c88e9d33cbd0e7bb
package/beta_sha256=ef339938036ee25c4f533210a35791d5faf9f69dcbc72cce173263005500f9e4
installed_manifest_sha256=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
steamrtarm64/steam_sha256=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so_sha256=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so_sha256=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
steamrtarm64/steamwebhelper_sha256=7a65e4f7c89dd2eeb0668f85ea0a06cf737507b7f3324407e5fc9a9a488c31d0
holo_rootfs_bytes=384971555
holo_rootfs_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
holo_ui_audio_closure=161 packages
holo_package_manifest_sha256=f3f46d90ab246dd799cb22d75cbb219ff3c5d8e62f1ce6f53c3847c74238d83f
external_package_manifest_sha256=00c06ef768b5c86f67a9e46bbd4f661b2e8e8344d81457af6986d5f9a8ee7354
libvulkan_freedreno.so_bytes=12364688
libvulkan_freedreno.so_sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
freedreno-kgsl.icd.json_bytes=194
freedreno-kgsl.icd.json_sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
proot_bytes=239368
proot_sha256=6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a
proot_loader_bytes=18136
proot_loader_sha256=44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04
libtalloc.so.2.4.3_sha256=3c9b207c0a6ea2896b7523e03f55d9ab0d9e88baa115d4c32b84058ff4246fbb
libandroid-shmem.so_sha256=84475798e07c8174dbbfaec70a827fdb02f19ffa69a589380c13e7507fd0e731
```

The pinned KGSL provider files were staged inside the run scope but both
`VK_ICD_FILENAMES` and `VK_DRIVER_FILES` were explicitly unset for this
replay. Their presence was not treated as provider selection or Vulkan
causality.

## Controlled variable and launch contract

Relative to the stable-payload replay in [doc
485](485-ayn-thor-rootless-stable-payload-replay-result-2026-08-11.md), the
changed input was the current sanitized public-beta client tree. The rooted
client layout, Holo closure, PRoot, app UID, fresh state, inherited Android
network, direct TCP X11, and launch environment remained fixed. The effective
guest command was:

```text
/bin/sh -c 'export HOME=/opt/nova-steam/home; export USER=steam; export LOGNAME=steam; export LANG=C; export LC_ALL=C; export XDG_RUNTIME_DIR=/tmp/nova-steam-runtime; export PATH=/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/bin:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/bin:/usr/bin:/bin; export LD_LIBRARY_PATH=/opt/nova-steam/home/.local/share/Steam/steamrtarm64:/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu:/usr/lib:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu/pulseaudio; unset LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_LAYER_PATH VK_ICD_FILENAMES VK_DRIVER_FILES; mkdir -p "$XDG_RUNTIME_DIR"; cd /opt/nova-steam/home/.local/share/Steam; exec /opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -skipinitialbootstrap -no-child-update-ui'
```

The outer supervisor used PRoot `-0` with only the declared `/dev`, `/proc`,
resolver, app-owned `/run`, HOME, Steam-client, and temporary-directory
bindings. There was no `/dev/shm` binding, machine-id, D-Bus daemon, Runtime 4,
Proton, FEX, Gamescope/AHardwareBuffer, SteamUI patch, or provider preload.

Two setup attempts were discarded before the valid launch: the fixture first
needed its declared `libandroid-shmem.so` and executable PRoot loader, and the
client needed the rooted-compatible `.steam/steam -> ../.local/share/Steam`
layout link. The first launch stopped at that missing link before Steam
startup; its disposable mutable paths were removed, the layout was corrected,
and the valid run began only after `nova_rootless_preflight=pass`.

## Display, input, and preflight evidence

Termux:X11 was freshly started as PID `21004` with Activity PID `21221`,
`DISPLAY=127.0.0.1:77`, and TCP listeners on IPv4 and IPv6 port `6077`.
The consent dialog for all-device logs was not shown, so no ADB scroll or
selection was sent: `log_access_consent=not-shown`.

The X11 handshake screenshot was 1920x1080, 41,334 bytes, SHA-256
`b47a8be3581f20966eefda3d13af8a80add69150e60cdbde7f72bd784ad1a88e`; it
showed a live black Termux:X11 canvas and cursor. X11's own log enumerated an
`Xbox Wireless Controller`, but this run did not claim Steam controller
integration because Steam never produced a frame.

Read-only KGSL evidence was:

```text
/dev/kgsl-3d0: crw-rw-rw- system:system u:object_r:gpu_device:s0 487,0
app UID: 10138, context u:r:runas_app:s0:c138,c256,c512,c768
app-visible mode: 0666, uid/gid 1000/1000, readable=1
```

This proves pathname/DAC readability only. It does not prove that the Vulkan
loader or Turnip can perform the required KGSL operations, and no SELinux
denial was attributed from this run.

## Observed result

### Positive native-client boundary

Fresh logs recorded `Steam Client launched with ...` using the public-beta
client and the expected Gamepad UI flags. The old `vgui2_s` fatal did not
recur. SteamUI recorded:

```text
Initialized CSteamUINetworkController: 0
```

and reported only the expected missing Gamescope X11 properties for direct
X11. `steamui_html.txt` and `webhelper.txt` recorded repeated webhelper
launches and restarts, proving the client crossed the old native loader
boundary and attempted Chromium/webhelper initialization.

### Later Vulkan boundary

The fresh Steam logs recorded:

```text
CVulkanTopology: failed to get physical device count
vkEnumeratePhysicalDevices failed, unable to init and enumerate GPUs with Vulkan.
BInit - Unable to initialize Vulkan!
```

This is not a provider-selector result: both selectors were unset. It is the
same type of later Vulkan boundary observed by R28, and R31 remains the
narrowest next test.

### Later webhelper/session boundaries

CEF repeatedly reported the exact `/dev/shm` failure:

```text
Creating shared memory in /dev/shm/... failed: Permission denied (13)
Unable to access(W_OK|X_OK) /dev/shm: Permission denied (13)
FATAL: ... incorrect permissions on /dev/shm
```

The guest also had no private system bus or machine identity:

```text
Failed to connect to socket /run/dbus/system_bus_socket: No such file or directory
Can't find session bus: Cannot spawn a message bus without a machine-id
```

SteamOS and NetworkManager logs separately reported absent guest services:
`SteamOSManager: failed to connect to OS service`, failure to connect to
`login1`, and repeated inability to create an `NMClient`. These messages do
not contradict the inherited Android data plane: this run established X11
TCP transport, and earlier controlled runs demonstrated Android-network
downloads. They identify missing Linux service APIs, not missing Android
Wi-Fi.

The fresh screenshots remained 1920x1080 images of a black X11 canvas with
Android status/key bars and a cursor. The final valid snapshot was:

```text
path=/tmp/thor-rootless-public-beta-equivalence-replay-20260811T191931Z-evidence/rootless-steam-81s.png
dimensions=1920x1080
bytes=42138
sha256=37c9825dc5f48558ec19b5110583cf4e2f4e5ee286a093a21b07916a16a18a1f
visible=black Termux:X11 canvas, cursor, extra-key bar; no Steam frame or QR
```

The X11 log reported a 1920x970 drawable after Android insets/keybar. That is
the direct X11 surface geometry, not evidence that the Steam client reached a
4:3 Nova presentation mode.

## Rooted comparison and sister-repo context

The rooted comparator in [doc
486](486-ayn-thor-rooted-known-good-oobe-comparison-result-2026-08-11.md)
used the same selected public-beta hashes and reached Steam OOBE and QR
sign-in. It was intentionally not a one-variable match. Rooted startup also
supplied a private mount/chroot, root-side `/dev` and `/proc` setup, fresh
tmpfs `/dev/shm`, private system/session D-Bus, machine identity, SteamOS
helpers, `DISPLAY=:0`, software CEF/GL controls, root-only preloads, audio and
controller helpers, and normal updater/restart handling. Rootless R36 supplied
none of those extra services or controls. The evidence therefore narrows the
differential to these session contracts but does not yet rank them.

The audited SteamClientTermux sibling is consistent with that interpretation:
its launcher uses a larger contract containing `VK_DRIVER_FILES`, private Mesa
paths, `MESA_LOADER_DRIVER_OVERRIDE=kgsl`, WSI tuning, private D-Bus,
network/audio helpers, and a patched PRoot. Its source is useful as prior art
for narrow contracts, not as proof that all of those changes belong in Nova:

- [SteamClientTermux ARM launcher](https://github.com/huntergdavis/steamclienttermux/blob/c0ada6ea2f56a96872af2190f69f4b5385c68ee2/bin/steam-arm)
- [SteamClientTermux architecture](https://github.com/huntergdavis/steamclienttermux/blob/c0ada6ea2f56a96872af2190f69f4b5385c68ee2/docs/ARCHITECTURE.md)
- [SteamClientTermux bootstrap evidence](https://github.com/huntergdavis/steamclienttermux/blob/c0ada6ea2f56a96872af2190f69f4b5385c68ee2/docs/logs/bootstrap-driver-2.log)

Known from this matrix:

1. Current public-beta client bytes and the nested/native launch contract are
   sufficient to cross `vgui2_s` under the app UID.
2. Direct TCP Termux:X11 starts and receives the session, and the app UID can
   read the KGSL node metadata.
3. Rootless webhelper has a concrete `/dev/shm` permission failure and a
   separate missing machine-id/D-Bus failure.

Still unknown rather than guessed:

1. Whether R31's selector spelling is the missing Vulkan-provider contract.
2. Whether app-owned `/dev/shm` alone lets webhelper initialize.
3. Whether a fresh private machine-id/session bus is needed after `/dev/shm`,
   or whether another service contract is next.
4. Whether any remaining Vulkan failure is loader selection, KGSL operation,
   or a later WSI/presentation boundary.

## Cleanup and rollback

The app, exact R36 app/device scopes, exact Termux:X11 PID/log files, and
port-6077 session were removed. Post-cleanup checks showed:

```text
device_run_scope=absent
app_r36_scope=absent
x11_helper_scope=absent
matching_steam_proot_webhelper_x11_processes=none
port_6077_listener=absent
termux.properties_sha256=89094537f49531dc9b380a0dec3a441b2fb92577e0a4f1db505790eb8b7025b0
rooted_rollback_root=/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs (present)
rooted_active_marker=/data/local/tmp/nova-active-runtime (present)
post_cleanup_available_kib=21812048
```

The reconstructed public-beta archive and R36 staging scratch directories
were deleted after hashing. The 7.3 MiB host evidence directory remains
outside the repository at
`/tmp/thor-rootless-public-beta-equivalence-replay-20260811T191931Z-evidence/`;
its screenshots and sanitized excerpts contain no QR or authentication state.

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, or authenticated Steam home was read, copied, backed up, committed, or
exported.
