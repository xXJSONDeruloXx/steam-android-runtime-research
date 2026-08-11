# AYN Thor rootless current-tree post-bootstrap Vulkan-loader diagnostic — result — 2026-08-11

Run identity: `thor-rootless-current-tree-post-bootstrap-vk-loader-debug-20260811T213100Z`;
sub-run: `R33-current-tree-post-bootstrap-loader-debug`.

Status: valid app-UID rootless run. R33 closes the configured Vulkan-provider
and physical-device-enumeration boundary, but the Steam process crashes
immediately after `vkCreateDevice`, before native SteamUI,
`steamwebhelper`, `/dev/shm`, D-Bus, or OOBE. This is not a
Vulkan-presentation success and is not evidence that rootless KGSL access is
denied.

## Classification

R33 changed exactly one launch variable relative to R32b: it added
`-nobootstrapperupdate`. The existing post-bootstrap rootless fixture was
otherwise retained, including `VK_DRIVER_FILES` and `VK_LOADER_DEBUG=all`.

The run passed rootless preflight under app UID 10138, started a fresh direct
TCP Termux:X11 server, launched the current sanitized ARM64 public client, and
reached the Vulkan loader. The loader found the pinned ICD, opened the pinned
Turnip library, enumerated a physical device named
`Turnip Adreno (TM) 740`, and reached the `vkCreateDevice` dispatch path:

```text
INFO:              Vulkan Loader Version 1.3.296
DRIVER:            Found ICD manifest file /opt/nova-kgsl-driver/freedreno-kgsl.icd.json, version 1.0.1
DEBUG | DRIVER:    Searching for ICD drivers named /opt/nova-kgsl-driver/libvulkan_freedreno.so
INFO | DRIVER:     Original order:
INFO | DRIVER:           [0] Turnip Adreno (TM) 740
DRIVER | LAYER:    Using "Turnip Adreno (TM) 740" with driver: "/opt/nova-kgsl-driver/libvulkan_freedreno.so"
```

The process then ended with:

```text
08/11 22:05:01 Failed writing minidump, nothing to upload.
proot info: vpid 1: terminated with signal 11
```

Therefore R33 is **PASS-A for the provider-selector and physical-device
enumeration boundary, followed by a new early post-device-use crash**. It does
not prove that Turnip device creation, Vulkan WSI, Steam presentation, or the
Steam UI is usable. The older `vgui2_s` fatal did not recur, but SteamUI was
not reached in this run, so that absence is only a negative observation.

The nearest next question is whether the rooted and SteamClientTermux software
CEF contract avoids this early UI/GPU path. That is a hypothesis, not a proven
cause. The one-variable follow-up is predeclared in doc
[499](499-ayn-thor-rootless-current-tree-cef-disable-gpu-predeclaration-2026-08-11.md).

## Provenance and identity

```text
branch=feat/rootless-steamclienttermux-profile
start_head=e2782ce30aecad727136aa2174b5659b9c407bdc
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

The sibling `/Users/kurt/Developer/steamclienttermux` checkout was clean at
revision `8d14c10195b34fe2714ba59df1680df27a852532`. Its audited upstream
source revision is `c0ada6ea2f56a96872af2190f69f4b5385c68ee2`; no sibling
payload, authentication state, or code was copied into this run.

Exact run scopes were:

```text
/data/local/tmp/thor-rootless-current-tree-post-bootstrap-vk-loader-debug-20260811T213100Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r33-current-tree/
/data/data/com.termux/files/home/.nova-rootless/
```

The first two scopes and the R33 helper files were fresh for this run. The
shared `.nova-rootless` parent was not treated as reusable Steam state; only
fresh R33 helper/log paths were used. The preserved rooted rollback paths were
not read as Steam state and remained untouched:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Fixed artifacts

The current-tree fixture and all R33 inputs passed their prelaunch gates:

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
proot_loader_sha256=44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04a
libtalloc_sha256=3c9b207c0a6ea2896b7523e03f55d9ab0d9e88baa115d4c32b84058ff4246fbb
libandroid_shmem_sha256=84475798e07c8174dbbfaec70a827fdb02f19ffa69a589380c13e7507fd0e731
resolv_conf_sha256=b015772310392b7bd9127d8ea899e133a456346d6812dd2b7c77bec1d443cd68
```

The selected loader was the first Vulkan library in the fixed SteamRT-first
search path:

```text
path=/opt/nova-steam/home/.local/share/Steam/steamrtarm64/libvulkan.so.1
sha256=d114974137bb80154f08c12531a2adef6431dde112566a0d2625e307fbd7eedf
```

Static strings in that loader contain `VK_DRIVER_FILES`,
`VK_ICD_FILENAMES`, and `VK_LOADER_DEBUG`; the dynamic trace then confirmed
that `VK_DRIVER_FILES` was actually honored. Khronos documents the same
selector relationship: `VK_DRIVER_FILES` and deprecated
`VK_ICD_FILENAMES` select driver manifests, with `VK_DRIVER_FILES` taking
precedence when both are present. See the
[Khronos loader driver interface](https://github.com/KhronosGroup/Vulkan-Loader/blob/main/docs/LoaderDriverInterface.md).

## Controlled launch contract

Relative to R32b, the only launch-variable change was:

```text
added Steam flag: -nobootstrapperupdate
```

The effective guest environment retained:

```text
HOME=/opt/nova-steam/home
USER=steam
LOGNAME=steam
LANG=C
LC_ALL=C
XDG_RUNTIME_DIR=/tmp/nova-steam-runtime
DISPLAY=127.0.0.1:77
PATH=/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/bin:/opt/nova-steam/home/.local/share/Steam/steamrt3c_platform_3c.0.20260714.251839/files/bin:/usr/bin:/bin
LD_LIBRARY_PATH=/opt/nova-steam/home/.local/share/Steam/steamrtarm64:/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu:/usr/lib:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu/pulseaudio
VK_DRIVER_FILES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
VK_LOADER_DEBUG=all
VK_ICD_FILENAMES=unset
LD_PRELOAD=unset
MESA_LOADER_DRIVER_OVERRIDE=unset
GALLIUM_DRIVER=unset
LIBGL_ALWAYS_SOFTWARE=unset
VK_IMPLICIT_DRIVER_PATH=unset
```

The Steam command was:

```text
/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui
```

It ran through the existing stock rootless supervisor with app-UID PRoot
`-0`, the existing `/dev` and `/proc` binds, fresh app-owned temporary
paths, and direct TCP Termux:X11. R33 did not add `/dev/shm`, D-Bus, a
machine-id, software GL variables, WSI variables, Runtime 4, Proton,
Gamescope, a UID change, or a privileged helper.

## Android device-access evidence

The outer and inner identities were kept separate. Read-only inspection showed:

```text
root_context=u:r:magisk:s0
getenforce=Permissive
/dev/kgsl-3d0=crw-rw-rw- system system u:object_r:gpu_device:s0 487,0
/dev/kgsl-3d0_mode=0666 uid=1000 gid=1000 character_device
app_uid_test_read=0
app_uid_test_write=0
```

No device write or ioctl test was performed. No chmod, chown, SELinux change,
new Android permission, `su` Steam launch, or package-identity change was
performed. The R33 loader trace reached Turnip physical-device enumeration and
`vkCreateDevice`; therefore the evidence does not support classifying R33 as
an app-UID KGSL denial. Android log output contained normal permissive
`runas_app` noise from the app/PRoot environment, but no fresh KGSL denial
correlated with the crash. The unchanged tombstone inventory and the absence
of a debuggerd record also mean that `proot info: vpid 1: terminated with
signal 11` should be treated as the guest-process crash report, not as a
proven Android kernel or SELinux fault.

## X11 and screen evidence

The fresh Termux:X11 process was:

```text
pid=29984
command=com.termux.x11 :77 -listen tcp -ac
termux_x11_commit=8a77681862d30814eba48054108a13bcf1cd485a
termux_x11_version=1.03.01-8a77681-09.06.26
tcp_listener=6077 IPv4+IPv6
guest_xprop_handshake=pass
log_access_consent=not-shown
```

The X11 log showed normal startup plus the existing legacy EGL fallback
messages. It did not contain a Steam-specific Vulkan or WSI diagnosis. Both
fresh screenshots were 1920x1080, 118653 bytes, SHA-256
`a4e4de4e4b4348529bd77184bdaaa538ac9fdd3d656306cf179ca98be5583577`.
They show the Nova launcher with “Nova session is stopped”, not a Steam
frame. No QR/OOBE or Steam presentation claim is made from these images.

## Rooted comparison and sister-repository finding

The rooted Thor comparator in [doc
486](486-ayn-thor-rooted-known-good-oobe-comparison-result-2026-08-11.md)
reached Steam OOBE and the QR sign-in screen, but it changed several contracts
together. In particular, it used `-cef-disable-gpu`, software GL controls
(`swrast`, `softpipe`, and `LIBGL_ALWAYS_SOFTWARE=1`), private
`/dev/shm`, private D-Bus, root-side mounts and preloads, and a rooted Linux
UID/GID. It therefore proves that the device and client can reach OOBE, not
that rooted Turnip device creation is equivalent to R33.

The sister project reaches a similar split: its launcher selects a private
Turnip provider while passing `-cef-disable-gpu`, and its architecture notes
state that software CEF is for the Steam interface while Turnip remains for
games. See the audited
[SteamClientTermux launcher](https://github.com/huntergdavis/steamclienttermux/blob/c0ada6ea2f56a96872af2190f69f4b5385c68ee2/bin/steam-arm)
and [architecture notes](https://github.com/huntergdavis/steamclienttermux/blob/c0ada6ea2f56a96872af2190f69f4b5385c68ee2/docs/ARCHITECTURE.md).
That project also adds private Mesa search paths, `MESA_LOADER_DRIVER_OVERRIDE`,
`TU_DEBUG`, WSI tuning, D-Bus, PulseAudio, and patched PRoot. None of those
were imported into R33, so upstream prior art is evidence for a later contract,
not proof of R33's crash cause.

The current differential is therefore narrower than “rooted can see the GPU,
rootless cannot”:

| Boundary | Rootless R33 | Rooted comparator |
| --- | --- | --- |
| Client / native ARM64 Steam | current sanitized public tree | same public-beta bytes |
| Vulkan provider selection | `VK_DRIVER_FILES` found and used | not isolated; rooted run forced software GL |
| Physical device | Turnip Adreno 740 enumerated | not measured under the same GPU path |
| Steam UI GPU mode | Vulkan path reaches a post-device-use SIGSEGV | `-cef-disable-gpu` plus software GL |
| `/dev/shm`, D-Bus, root mounts | absent by contract | present |
| OOBE | not reached | language, timezone, network, QR reached |

R33 therefore closes the provider-visibility question and exposes the next
measurable distinction: whether avoiding CEF GPU compositing is sufficient to
keep the rootless client alive long enough to reach SteamUI. It is not yet
known whether the crash is in CEF-adjacent initialization, Steam's Vulkan
device-use path, Turnip under PRoot, or another unmeasured boundary.

## Evidence bundle

Non-sensitive run evidence remains outside the repository at:

```text
/tmp/thor-rootless-current-tree-post-bootstrap-vk-loader-debug-20260811T213100Z-evidence.cdOPSz/
```

Important captures and hashes:

```text
steam-console.txt       bytes=16637 sha256=06879a1ab225d42a3bf3664787506512db199557c180551f9be51eea94eca901
bootstrap_log.txt       bytes=416   sha256=a96858375ab34e263636e358fa011e5425932c070ac4a246d4f29155a8d5e68f
updateui_child.txt      bytes=99    sha256=980ad7624e86d478ebbd0a7e0ee6a371f5cc0f5f857bc6209a4930e957b212b5
rootless-supervisor.log bytes=2876  sha256=eccbef28e81a3708f1b22598c74ac96f430d2a5f75cae48d1af66080bc982dbf
termux-x11.log          bytes=4771  sha256=0b3ae88c292108ac4bc4541e44fcdbbfb8f2e784ac81c04d119fd6db6e1f380c
processes-after.txt     bytes=216   sha256=03f55c585b2d3d0bc3fe760aac6507a70e6160f996df634f7b94f867b7fdefe5
proc-net-after.txt      bytes=1402  sha256=6be35e351a5c6bdd88691275a79fd5c50f044c191df2f9349a0503fd712333fe
logcat-r33-targeted.txt bytes=75482 sha256=6b08c72b61617c154a1c046b72d65a8f624db8d8dfe1e3af9f6b2e5e52a9a583
x11-start.png           bytes=118653 sha256=a4e4de4e4b4348529bd77184bdaaa538ac9fdd3d656306cf179ca98be5583577
post-crash.png          bytes=118653 sha256=a4e4de4e4b4348529bd77184bdaaa538ac9fdd3d656306cf179ca98be5583577
```

The supervisor recorded preflight success and free space of
`10195032 KiB`; the launch-time preflight recorded `10189784 KiB`.

## Cleanup and rollback

Cleanup was identity- and scope-specific. It:

1. force-stopped the exact Nova APK package;
2. terminated the verified PID 29984 Termux:X11 process and stopped that
   exact X11 package;
3. restored `/data/data/com.termux/files/home/.termux/termux.properties`
   from the R33 backup with mode and ownership restored; its SHA-256 returned
   to `89094537f49531dc9b380a0dec3a441b2fb92577e0a4f1db505790eb8b7025b0`;
4. removed only the R33 device scope, app scope, and exact X11 helper files;
5. verified that no matching Steam, PRoot, webhelper, Nova, or Termux:X11
   process remained and that port 6077 had no listener; and
6. verified both rooted rollback paths remained present.

Post-cleanup device free space was `21948520 KiB` on the reported filesystem.
Disposable host staging directories were moved to the macOS Trash after the
run; the evidence bundle above was retained. No preserved rooted runtime or
active-runtime marker was deleted or reset.

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, authenticated Steam home, or `steam.token` contents were read, copied,
backed up, committed, or exported.
