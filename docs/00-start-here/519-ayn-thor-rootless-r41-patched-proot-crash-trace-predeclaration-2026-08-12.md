# AYN Thor rootless R41 patched PRoot crash trace — predeclaration — 2026-08-12

Run identity: `thor-rootless-r41-patched-proot-crash-trace-20260812T140500Z`;
sub-run: `R41-rootless-steamclienttermux-patched-proot-crash-trace`.

Status: predeclared as the single diagnostic follow-up after [doc
518](518-ayn-thor-rootless-r40b-current-tree-patched-proot-result-2026-08-12.md).

## Question and one controlled change

R40b used the verified SteamClientTermux patched PRoot and still reached
Turnip physical-device enumeration and `vkCreateDevice` before PRoot reported
signal 11. The next question is whether the crash trace identifies a PRoot
syscall-translation boundary, a translated instruction/faulting mapping, or
only confirms that the guest Steam process itself exits.

The only changed variable is:

```text
PROOT_CRASH_LOG=1
```

It is an outer app-UID PRoot diagnostic variable. It must be present for the
patched PRoot invocation and must not be added to the Steam guest environment
as a second runtime change. The sibling source documents that this tracer is
expensive; this run is bounded and diagnostic-only.

Do not add `PROOT_VERBOSE`, `--shared-tmp`, `/dev/shm`, D-Bus, machine-id,
software-GL variables, Mesa/WSI variables, Runtime 4, Proton, FEX/DXVK,
Gamescope/AHardwareBuffer, input/audio helpers, SteamUI patches, UID/GID
changes, or a privileged Steam launch.

## Device and fresh scopes

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
/data/local/tmp/thor-rootless-r41-patched-proot-crash-trace-20260812T140500Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r41/
/data/data/com.termux/files/home/.nova-rootless-r41/
```

Only verified immutable payloads may be reused from R40b. Steam HOME, mutable
state, logs, resolver, temporary directories, X11 PID/listener, screenshots,
and readiness baselines must be fresh. Preserve and verify untouched:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

The current-tree fixture remains provenance-qualified, not byte-identical to
R39:

```text
public_client_archive_bytes=3757731328
public_client_archive_sha256=97c3140d75c551953c915fb8e06b4ec51c18b2cc32ec4af620ad64df62a77548
steamrtarm64/steam=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
steamrtarm64/steamwebhelper=7a65e4f7c89dd2eeb0668f85ea0a06cf737507b7f3324407e5fc9a9a488c31d0
installed_manifest=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
```

Retain the R40b patched PRoot provenance:

```text
patch_base_commit=a89b3732ec6ae1db674510f0843b2f3db54d0a2f
patchset_sha256=ce94daf1ae8a7fb994a4295d69006fe8604ac724bd6343daa25532f21f904f69
diff_sha256=e6fa2c6bd7073c7925f9b0d9bc5559b70aabc44515a81510301a07c99947d7c1
patched_proot_sha256=0378e0631dbf7a8bd0061b54fc167bb881c70a76109f567b682f7262a063166c
patched_loader_sha256=eab6b2135421a2e0268832cf171d877146a9e816d7b060ce425e5017d65f08a6
```

## Fixed launch contract

Keep the R40b Holo, provider, SteamRT-first library ordering, nested client
layout, conventional `.steam` links, direct TCP Termux:X11, resolver,
`/dev`/`/proc` bindings, app-owned `/tmp`, and Steam flags fixed:

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

The outer supervisor invocation must show the patched binary and loader
directly. Add only `PROOT_CRASH_LOG=1` to that outer app-UID environment.
Capture the complete supervisor stderr/stdout and the guest Steam console
separately, with a bounded output and storage cap.

## Evidence and classification

Before launch capture the screen and record the Android all-device-log consent
state. If the dialog is present, use only targeted one-time acceptance after
reading it; if absent record `log_access_consent=not-shown`. Capture fresh
artifact hashes, outer UID/SELinux identity, inner PRoot identity, free space,
exact environment, exact command, X11 PID/listener, read-only `/dev/kgsl*`
metadata, process state, Steam/bootstrap/Vulkan logs, and screenshot
provenance.

The trace must be classified in this order:

1. Wrong device, hash, scope, freshness, environment, authentication boundary,
   or missing conventional layout is invalid.
2. If the trace identifies a PRoot translation operation or faulting guest
   mapping, record that concrete boundary; do not call it a fix.
3. If it only repeats the post-`vkCreateDevice` signal 11, close the
   diagnostic as non-discriminating and do not import another sibling helper
   into the same run.
4. If Steam survives, separately record native SteamUI, webhelper, Vulkan,
   `/dev/shm`, D-Bus, display, and OOBE progress. Survival alone is not a
   presentation result.

Do not infer an Android KGSL or SELinux denial without fresh denial/access
evidence. Do not run a device ioctl probe, chmod/chown the node, alter SELinux,
or launch Steam through `su`.

## Cleanup and authentication boundary

After capture, stop only the exact R41 Steam/PRoot/X11 processes, remove only
the three R41 scopes, verify port 6077 and matching processes are absent, and
verify both rooted rollback paths remain. Never broad-kill Termux, clear app
data, delete `/data/local/tmp/nova-active-runtime`, or touch the preserved
rooted runtime.

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, authenticated Steam home, or `steam.token` contents may be read, copied,
backed up, committed, or exported.
