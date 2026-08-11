# Nova rootless R30 — R29 provider-off control result — 2026-08-11

Run ID: `nova-rootless-r30-r29-provider-off-20260811T144035Z`;
sub-run: `R30-rootless-supervisor-r29-provider-off-control`.

Status: complete as a valid bounded control. R30 changed only the effective
Vulkan ICD selector relative to R29: the rooted KGSL/Turnip files remained
staged, but `VK_ICD_FILENAMES` was explicitly unset. R30 crossed the R29
updater/X11 `SIGSEGV`, reached the native SteamUI and webhelper boundary, and
then reproduced the independent Vulkan, `/dev/shm`, and D-Bus prerequisites.
It did not enumerate a Vulkan physical device and did not produce a Steam
frame.

## Result and classification

R30 is a provider-off control that makes R29's selector/provider interaction
the leading explanation for the early crash. It is not a Vulkan PASS-A,
PASS-B, or FAIL-C:

- the same sanitized rooted public client, nested layout, HOME/cwd, SteamRT-
  first environment, app-UID PRoot, Holo closure, resolver, direct TCP
  Termux:X11, and Steam flags were used;
- the pinned provider files were still present at `/opt/nova-kgsl-driver/`,
  but no Vulkan selector was exported;
- R30 reached client build `1786141909`, initialized native SteamUI/system
  controllers, launched `steamwebhelper`, and remained free of the old
  `vgui2_s` fatal;
- `steamsysinfo` still reported `CVulkanTopology: failed to get physical
  device count` and exited `-2`;
- webhelper then reported the known missing `/dev/shm` fatal and repeated
  restarts; and
- the outer PRoot eventually ended with `vpid 1: terminated with signal 4`
  after the updater attempted a background manifest request.

The contrast with R29 is the useful result. R29, with
`VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`, ended in
the updater/X11 path with `signal 11` before `steamsysinfo`, Vulkan, SteamUI,
or webhelper evidence. R30, with that selector unset, reproduced the R28
native-client/UI boundary. This does not prove that the ICD was successfully
loaded in R29, nor that the driver is compatible; it identifies the
selector/provider interaction as the nearest measurable difference.

The single next experiment is predeclared in [doc 473](473-nova-rootless-r31-vk-driver-files-provider-selector-predeclaration-2026-08-11.md): use the same pinned ICD through `VK_DRIVER_FILES` only. Do not add `/dev/shm`, D-Bus, Mesa overrides, a privileged helper, Runtime 4, Proton, Gamescope, AHardwareBuffer, or packaging changes to that run.

## Controlled launch

The effective R30 guest command preserved the R28 contract and explicitly
unset the R29 selector for this control:

```text
export HOME=/opt/nova-steam/home
export USER=steam
export LOGNAME=steam
export LANG=C
export LC_ALL=C
export XDG_RUNTIME_DIR=/tmp/nova-steam-runtime
export PATH=/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/bin:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/bin:/usr/bin:/bin
export LD_LIBRARY_PATH=/opt/nova-steam/home/.local/share/Steam/steamrtarm64:/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu:/usr/lib:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu/pulseaudio
unset LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_LAYER_PATH VK_ICD_FILENAMES
cd /opt/nova-steam/home/.local/share/Steam
exec /opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui
DISPLAY=127.0.0.1:77
```

The supervisor preflight passed with the app UID and fresh R30 paths:

```text
nova_rootless_preflight=pass uid=10128 rootfs=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r30/guest-rootfs-closure proot=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r30/input/proot/proot
nova_rootless_state=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r30/state home=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r30/input/home steam_client=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r30/input
nova_rootless_free_kib=74064088
nova_rootless_resolv_conf=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r30/state/config/resolv.conf
```

The exact client, rootfs, and provider provenance remained:

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
libvulkan_freedreno.so size=12364688 sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810 mode=755 owner=10128:10128
freedreno-kgsl.icd.json size=194 sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70 mode=755 owner=10128:10128
```

The device was a Retroid Pocket Nova, serial `675a2365`, Android API 33,
architecture `arm64-v8a`. The repository branch at run start was
`feat/rootless-steamclienttermux-profile` at
`d3983c5bc707c5bb428a93509654015b7beed228`.

## Fresh Steam evidence

The first Steam log milestones were:

```text
[2026-08-11 14:52:27] Startup - Steam Client launched with: '/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam' '-gamepadui' '-steamos3' '-steampal' '-steamdeck' '-no-cef-sandbox' '-nobootstrapperupdate' '-skipinitialbootstrap' '-no-child-update-ui'
[2026-08-11 14:52:28] Client version: 1786141909
[2026-08-11 14:52:28] Initialized CSystemDockManagerController: 1
[2026-08-11 14:52:28] Initialized CSystemAudioDeviceController: 1
[2026-08-11 14:52:28] Initialized CSystemDisplayController: 1
[2026-08-11 14:52:28] Initialized CSystemPerfController: 1
[2026-08-11 14:52:28] Initialized CSteamUINetworkController: 0
[2026-08-11 14:52:28] Started webhelper process 30956
```

The old native-loader boundary did not recur. There was no `Fatal Error:
Could not load module 'bin/vgui2_s.dll'`, no `Could not load 'vgui2_s.so'`,
and no evidence of an authenticated Steam state.

The fresh Vulkan evidence was:

```text
[2026-08-11 14:52:28] Running query: 1 - GpuTopology
[2026-08-11 14:52:28] CVulkanTopology: failed to get physical device count
[2026-08-11 14:52:28] Failed to query vulkan gpu topology
[2026-08-11 14:52:28] Exit code: -2
vkEnumeratePhysicalDevices failed, unable to init and enumerate GPUs with Vulkan.
BInit - Unable to initialize Vulkan!
```

No provider-loader message identified a loaded or rejected ICD, so this run
does not close provider discovery or physical-device access.

The independent webhelper prerequisites were visible separately:

```text
Steam Runtime Launch Service: starting steam-runtime-launcher-service
steam-runtime-launcher-service[31029]: E: Can't find session bus: Cannot spawn a message bus without a machine-id: Unable to load /var/lib/dbus/machine-id or /etc/machine-id: No such file or directory
steamwebhelper: Failed to connect to the bus: Failed to connect to socket /run/dbus/system_bus_socket: No such file or directory
steamwebhelper: Creating shared memory in /dev/shm/.com.valvesoftware.Steam.* failed: No such file or directory (2)
steamwebhelper: Unable to access(W_OK|X_OK) /dev/shm: No such file or directory (2)
steamwebhelper: FATAL: This is frequently caused by incorrect permissions on /dev/shm.
```

SteamUI repeatedly restarted webhelper and finally timed out waiting for its
initialization. The updater later began a background manifest request and the
fresh PRoot log ended with `vpid 1: terminated with signal 4`. This later
termination is distinct from R29's early `signal 11` and is not evidence that
the provider-off control fixed Vulkan.

Other X11 messages were diagnostic rather than a new provider result:

```text
Error: XRRGetOutputInfo() is not available
sh: line 1: xwininfo: command not found
```

The fresh X11 process was `termux-x11 com.termux.x11 :77 -listen tcp -ac` and
the listener was present on TCP port 6077 during the run.

## Android log-consent foreground gate

The first foreground capture was covered by Android's system dialog:
`Allow Nova Steam to access all device logs?` The Steam process was already
running in the background, so this modal is not a Steam or X11 failure, but it
made an unqualified screenshot unusable as a display result.

For this run, the dialog was captured, scrolled, and granted the safer
`Allow one-time access` choice through ADB. The post-consent capture showed the
Nova launcher with `Nova session is stopped`; it was still not a Steam frame.
The durable first-run handling rule is now recorded in [doc 34](34-nova-runtime-harness-lifecycle.md): detect this modal before UI screenshots, scroll only after verifying its text, choose one-time access rather than persistent device-log access, and record both the dialog and post-consent captures. Do not grant or retain broader log access as a substitute for fresh run logs.

Screenshot provenance:

```text
/tmp/nova-r30-r29-provider-off-live.png
PNG 1280x960, size=136649, sha256=e1db347d3c36803db080b48f8a383d432cd463afec47bf39eb78ca72c9485cc1
visible=Android device-log consent modal over the Nova launcher; not a Steam frame

/tmp/nova-r30-device-log-dialog-scrolled.png
PNG 1280x960, size=not retained in the run record, sha256=ffad46f579d6edc7888c502a8ab68527d9e435358f60bf89c0adff269a4e2d15
visible=scrolled Android device-log consent modal with one-time and deny choices

/tmp/nova-r30-after-device-log-consent.png
PNG 1280x960, sha256=675dac3088dc124e2f7d15f2c8f3fe8c5650072186ee54baff3e3d1edfb00818
visible=Nova launcher, session stopped; not a Steam frame
```

## Device-node characterization

Read-only host inspection showed the expected Android-owned nodes:

```text
/dev/kgsl-3d0       crw-rw-rw- system system  u:object_r:gpu_device:s0
/dev/dri/renderD128 crw-rw-rw- root   graphics u:object_r:graphics_device:s0
/dev/dri/card0      crw-rw-rw- root   graphics u:object_r:graphics_device:s0
```

Inside the app-owned PRoot guest, the nodes were visible and zero-length
`dd` open probes returned zero. That is only a path/open smoke test: it did
not issue a KGSL ioctl or enumerate a Vulkan device. There was no concrete
device denial or SELinux denial in this run, so R30 must not be classified as
an app-UID GPU-access failure.

## Captured evidence

The evidence was pulled before teardown to `/tmp/nova-r30-evidence/` and was
not added to the repository:

```text
rootfs-extract.log        360 bytes    sha256=b49df78b3004849d42c8aa4afa2de26acb041d14f08c31265e632fcfbc140df1
guest-rootfs-prepare.log  14032 bytes  sha256=9c398a086188b4028ab1d5642b7709396c8404790deb32fa66ea48c5db8ab5ed
supervisor-preflight.log  797 bytes    sha256=a6f89998f40184ed3cc92f5e6b6b77311b13a8217ca37fb390ed160d777d3e89
rootless-supervisor.log   11892 bytes  sha256=b9b92265124d857579144602b7df6b457e6f9bd47a5a049ad75c2781da51e171
launch-command.log        53 bytes     sha256=b67a5645fb266d38c62c5815177175a1633da624ea0a3e17095a05c6912367e3
bootstrap_log.txt         1174 bytes   sha256=6c5d07e68e8fba2b2b0c609cd1ab105b3a3728aa86a0223d0c81a7cb9a3016ff
steamsysinfo.txt          325 bytes    sha256=78aec59ce384a2b469c7f807731afceb212b00556d106c070cf66319be1050f1
steamui_system.txt        920 bytes    sha256=4f7ce4603ba3d9d366d67863b372d77820ef20f36b4b57a2feff861dcdd6fbaf
steamui_html.txt          2281 bytes   sha256=63b508780b2c3dcf3cb5712bbf1982404f52d1083258c1beb821c8511a0dc66d
steamwebhelper.log        3610 bytes   sha256=0bf423cd5d8ff19095f707adfbd4f7cb85f9d375cceacd9528a03dac70687baf
webhelper.txt             25886 bytes  sha256=77e9df8c360919e4f7adccfaa272ad9958a970a881740f984dfcd17ec9128d9f
termux-x11-77.log         49 bytes     sha256=d670a8a488cb13b3b4ac4dffbd26e5bb7808adbe6ddedf5984d9d1fc5d63b78b
```

The Steam log paths above were fresh under the app-owned R30 input tree;
they were selected diagnostic logs only. No Steam configuration, cookies,
tokens, QR/session material, or authenticated home was read or copied.

## Cleanup and rollback proof

The APK and Termux:X11 were force-stopped. The exact X11 PID was verified as
`termux-x11 com.termux.x11 :77 -listen tcp -ac` before it was terminated. No
Steam, PRoot, webhelper, or Termux:X11 process remained and TCP port 6077 was
no longer listening.

The app bridge again used its current default Termux state rather than the
declared run-specific state. R30 therefore removed both the declared path and
the actual default path, which had been absent in the pre-run baseline:

```text
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r30/ absent
/data/local/tmp/nova-rootless-r30-r29-provider-off-20260811T144035Z/ absent
/data/data/com.termux/files/home/.nova-rootless-r30/ absent
/data/data/com.termux/files/home/.nova-rootless/ absent
```

Post-cleanup free space was `85990560 KiB`. The preserved rooted rollback
paths remained present:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs directory 3452 bytes mode 755 owner 0:0
/data/local/tmp/nova-active-runtime regular file 70 bytes mode 644 owner 0:0
```

No Steam authentication secret or authenticated Steam state was read,
copied, backed up, committed, or exported. The fresh R30 state was removed
with its exact run scopes.
