# AYN Thor rootless current-tree Vulkan-loader diagnostic — result — 2026-08-11

Run identity: `thor-rootless-current-tree-refresh-vk-loader-debug-20260811T210138Z`;
sub-run: `R32b-current-tree-loader-debug`.

Status: valid fixture and app-UID launch, but stopped in the Steam updater
before the Vulkan-loader or SteamUI boundary. This is a pre-Vulkan updater
handoff result, not a provider, KGSL, or `vgui2_s` result.

## Classification

R32b kept the current-tree selector fixture unchanged and added only the
observation variable `VK_LOADER_DEBUG=all`. The run passed rootless preflight,
started PRoot under app UID 10138, launched the ARM64 Steam updater, and kept
one Steam process alive. It did not create `steamwebhelper`, SteamUI logs, or a
Vulkan-loader trace.

The first new boundary was the updater's X11 font-file check:

```text
src/steamexe/updateui_xwin.cpp (1481) : BFileExists( m_FontFileRegular )
src/steamexe/updateui_xwin.cpp (1481) : BFileExists( m_FontFileRegular )
/data/src/steamexe/updateui_xwin.cpp 1481 BFileExists( m_FontFileRegular )
```

The bootstrap log stopped after client-beta selection. No `VK_LOADER_DEBUG`,
`VK_DRIVER_FILES`, ICD, Turnip, KGSL, physical-device, `vgui2_s`, or
`steamwebhelper` line appeared. The old `vgui2_s` fatal was therefore not
retested: its absence here is only a pre-stage negative observation.

This does not show that rootless Vulkan is blind. The R32b process never
called the loader. The more immediate difference from the rooted known-good
path is launch lifecycle: the rooted path completes the public update and
restarts with `-nobootstrapperupdate -skipinitialbootstrap
-no-child-update-ui`; R32b intentionally omitted `-nobootstrapperupdate`.
Earlier rootless R30 evidence using that post-bootstrap flag reached client
build and SteamUI system initialization. The next A/B therefore adds only
that missing handoff flag while retaining the loader diagnostic.

The `BFileExists` line is recorded as an updater symptom, not as a proven
missing-font cause. The sanitized public tree contains
`clientui/fonts/GoNotoKurrent-Regular.ttf` and the rooted public tree contains
the same regular font. A separate static comparison is required if the
post-bootstrap handoff still stops there.

## Provenance and identity

```text
branch=feat/rootless-steamclienttermux-profile
start_head=3662085c25464394225b7df21708900bac89a958
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
app_selinux=u:r:runas_app:s0:c138,c256,c512,c768
rootless_outer_uid=10138
rootless_guest_mode=PRoot -0
android_selinux=getenforce: Permissive
```

The sibling prior-art checkout was clean at
`8d14c10195b34fe2714ba59df1680df27a852532`. Its launcher uses a deliberately
larger contract—patched PRoot, private D-Bus, PulseAudio, software CEF, and
additional Mesa/Turnip variables—so none of those were imported into R32b.
See the [SteamClientTermux launcher](https://github.com/huntergdavis/steamclienttermux/blob/c0ada6ea2f56a96872af2190f69f4b5385c68ee2/bin/steam-arm)
and [architecture notes](https://github.com/huntergdavis/steamclienttermux/blob/c0ada6ea2f56a96872af2190f69f4b5385c68ee2/docs/ARCHITECTURE.md).

## Fixed artifacts

The reproducible current-tree fixture gate passed before launch:

```text
archive_bytes=3457525760
archive_sha256=9a3507ce029c0aebe28ebd54ae03f79b56b1899e6ad4e530c88e9d33cbd0e7bb
tar_entries=21513
forbidden_filename_scan=empty
installed_manifest_sha256=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
steamrtarm64/steam_sha256=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so_sha256=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so_sha256=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
steamrtarm64/steamwebhelper_sha256=7a65e4f7c89dd2eeb0668f85ea0a06cf737507b7f3324407e5fc9a9a488c31d0
package/beta_sha256=ef339938036ee25c4f533210a35791d5faf9f69dcbc72cce173263005500f9e4
holo_rootfs_bytes=384971555
holo_rootfs_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
holo_ui_audio_closure=161 packages
holo_manifest_sha256=f3f46d90ab246dd799cb22d75cbb219ff3c5d8e62f1ce6f53c3847c74238d83f
libvulkan_freedreno.so_sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
freedreno-kgsl.icd.json_sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
proot_sha256=6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a
proot_loader_sha256=44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04
libtalloc_sha256=3c9b207c0a6ea2896b7523e03f55d9ab0d9e88baa115d4c32b84058ff4246fbb
libandroid_shmem_sha256=84475798e07c8174dbbfaec70a827fdb02f19ffa69a589380c13e7507fd0e731
resolv_conf_sha256=b015772310392b7bd9127d8ea899e133a456346d6812dd2b7c77bec1d443cd68
```

The only launch-variable addition relative to the selector fixture was:

```text
VK_DRIVER_FILES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
VK_LOADER_DEBUG=all
VK_ICD_FILENAMES=unset
LD_PRELOAD=unset
MESA_LOADER_DRIVER_OVERRIDE=unset
GALLIUM_DRIVER=unset
LIBGL_ALWAYS_SOFTWARE=unset
VK_IMPLICIT_DRIVER_PATH=unset
```

The fixed Steam environment used the rooted SteamRT-first `PATH` and
`LD_LIBRARY_PATH`, `HOME=/opt/nova-steam/home`,
`DISPLAY=127.0.0.1:77`, `USER=steam`, `LOGNAME=steam`, `LANG=C`,
`LC_ALL=C`, and `XDG_RUNTIME_DIR=/tmp/nova-steam-runtime`. The exact
flags were:

```text
-gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox
-skipinitialbootstrap -no-child-update-ui
```

## Loader and device-access evidence

Static inspection identified the first loader in the fixed
`LD_LIBRARY_PATH` as:

```text
path=/opt/nova-steam/home/.local/share/Steam/steamrtarm64/libvulkan.so.1
sha256=d114974137bb80154f08c12531a2adef6431dde112566a0d2625e307fbd7eedf
```

Its strings include `VK_DRIVER_FILES`, `VK_ICD_FILENAMES`, and
`VK_LOADER_DEBUG`. This establishes selector support in the selected loader;
it does not establish that R32b reached the loader dynamically. The fallback
Holo loader was `usr/lib/libvulkan.so.1.4.328`, SHA-256
`9858a253ce4a125eb0408f5b309657dd96f5f032b630d2cd8a54a8f445eda238`, but it
was later in the search path.

Read-only Android device evidence was:

```text
/dev/kgsl-3d0: crw-rw-rw- system system u:object_r:gpu_device:s0 487,0
app_uid_test_r_kgsl_3d0=0
app_uid_test_w_kgsl_3d0=0
```

These are only pathname and DAC checks. No device write, ioctl, chmod, chown,
SELinux change, or privileged Steam launch was performed. No fresh KGSL denial
was correlated with this run.

## X11, process, and screen evidence

The APK started a fresh Termux:X11 server as PID 5199 with
`com.termux.x11 :77 -listen tcp -ac`. TCP 6077 was listening and the app-UID
`xprop -root` handshake exited successfully. No Android device-log consent
dialog was shown, so no consent input was sent.

The foreground screenshot was 1920x1080, SHA-256
`a4e4de4e4b4348529bd77184bdaaa538ac9fdd3d656306cf179ca98be5583577`. It
showed the Nova launcher with “Nova session is stopped”; it was not a Steam
frame. The X11 log reported normal startup and legacy EGL fallback messages,
not a Steam Vulkan or WSI result.

The fresh process sequence was:

```text
PRoot pid=8801
Steam pid=8839
steamwebhelper=absent
SteamUI log=absent
Vulkan-loader log=absent
```

The Steam console capture was 1,781 bytes, SHA-256
`aab06555199373c61a932a7a7673a27735ac564b05765c758952dfb1a9162a75`.
The fresh bootstrap log was 392 bytes, SHA-256
`c1c8d7f58c1649262291c81258e1448f6f2be4f5e31255aa4a1a12a05983843f`.
Run-scoped evidence is retained outside the repository at
`/tmp/thor-rootless-current-tree-vk-loader-debug-20260811T204834Z-evidence.bFNAxR/`.

## Cleanup and rollback

Only the exact R32b scopes were removed:

```text
/data/local/tmp/thor-rootless-current-tree-refresh-vk-loader-debug-20260811T210138Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r32b-current-tree/
/data/data/com.termux/files/home/.nova-rootless/termux-x11-77.log
/data/data/com.termux/files/home/.nova-rootless/termux-x11-77.pid
```

The Termux properties file was restored byte-for-byte:

```text
sha256=89094537f49531dc9b380a0dec3a441b2fb92577e0a4f1db505790eb8b7025b0
```

No matching Steam, PRoot, webhelper, or Termux:X11 process remained; no
6077 listener remained; and both rooted rollback paths remained present.
Post-cleanup free space was `21932108 KiB` on the reported device
filesystem.

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, authenticated Steam home, or `steam.token` contents were read, copied,
backed up, committed, or exported.
