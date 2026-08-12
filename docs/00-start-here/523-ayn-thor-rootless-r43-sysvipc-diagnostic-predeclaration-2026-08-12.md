# AYN Thor rootless R43 patched PRoot SysV IPC diagnostic — predeclaration — 2026-08-12

Run identity: `thor-rootless-r43-sysvipc-20260812T153000Z`
Sub-run: `R43-rootless-patched-proot-sysvipc-diagnostic`
Status: predeclared as the single next experiment after [doc
522](522-ayn-thor-rootless-r42-nodevice-select-result-2026-08-12.md).

## Question and one controlled change

R42 proved that the Holo `VK_LAYER_MESA_device_select` layer was disabled by
`NODEVICE_SELECT=1`, but the patched PRoot Steam process still crashed after
Turnip physical-device enumeration and the `vkCreateDevice` dispatch path.
The crash trace did not identify a translated syscall or a faulting mapping.

The audited SteamClientTermux PRoot patch adds Android-compatible handling for
`set_robust_list`/`get_robust_list` and emulated SysV semaphores/shared memory.
Its implementation has an opt-in SysV diagnostic stream. R43 asks only
whether the Steam process exercises that patched emulation immediately before
the existing crash.

The only changed variable relative to R42 is:

```text
export PROOT_SYSVIPC_LOG=1
```

Set it in the outer app-UID PRoot environment so the patched PRoot emits its
diagnostic records. Preserve R42's `NODEVICE_SELECT=1` guest environment and
`PROOT_CRASH_LOG=1` outer diagnostic. Do not add `PROOT_VERBOSE`, change the
patched source, or import any other SteamClientTermux launcher behavior.

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

Use fresh scopes:

```text
/data/local/tmp/thor-rootless-r43-sysvipc-20260812T153000Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r43/
/data/data/com.termux/files/home/.nova-rootless-r43/
```

Reuse only the verified immutable R42 payloads. Steam HOME, mutable state,
logs, resolver, temporary directories, X11 PID/listener, screenshot, and
readiness baseline must be fresh. Preserve and verify untouched:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

The client, Holo rootfs, provider, patched PRoot, loader, libtalloc, and
libandroid-shmem hashes must match [doc 522](522-ayn-thor-rootless-r42-nodevice-select-result-2026-08-12.md).
The current-tree client remains a selected-tree-equivalence fixture, not a
historical byte-identical R28 archive.

## Fixed launch contract

Retain R42 exactly:

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
NODEVICE_SELECT=1
PROOT_CRASH_LOG=1
unset VK_ICD_FILENAMES LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_LAYER_PATH
```

Keep the same SteamRT-first `PATH` and `LD_LIBRARY_PATH`, nested client
layout, app-owned `/tmp`, resolver, `/dev` and `/proc` bindings, direct TCP
Termux:X11, PRoot `-0`, and flags:

```text
-gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -cef-disable-gpu -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui
```

The only additional effective variable is:

```text
PROOT_SYSVIPC_LOG=1
```

Do not add `/dev/shm`, D-Bus, machine-id, software GL, Mesa/WSI variables,
Runtime 4, Proton, FEX/DXVK, Gamescope/AHardwareBuffer, UI patches,
input/audio helpers, UID/GID changes, or a privileged Steam launch.

## Evidence and classification

Before launch, verify device identity, app UID/SELinux identity, immutable
payload hashes, fresh scopes, free space, inner/outer identity, exact
command/environment, X11 PID/listener, consent state, and read-only KGSL
metadata. If the Android all-device-log consent dialog is absent, record
`log_access_consent=not-shown`; never send blind input.

Capture bounded fresh copies of:

- `PROOT_SYSVIPC` diagnostic lines;
- the patched PRoot crash trace and complete bounded console;
- Steam/bootstrap and Vulkan loader logs;
- native SteamUI/webhelper evidence if reached;
- process/listener state, screenshot, and screenshot hash;
- selected post-run client hashes and exact cleanup evidence.

Classify in this order:

1. Wrong device, hash, scope, freshness, environment, authentication
   boundary, conventional layout, or lifecycle state is invalid.
2. If SysV/robust-list-related records occur immediately before the crash,
   record that as the nearest observed PRoot emulation activity. Do not call
   it causal without a separate control.
3. If no relevant SysV records occur and the same post-device signal 11
   remains, close this diagnostic as non-discriminating; do not add another
   sibling PRoot variable in the same run.
4. If Steam progresses, classify Vulkan, native SteamUI, webhelper, `/dev/shm`,
   D-Bus, display, OOBE, and frame progress separately. Survival is not
   presentation proof.

Do not run a device ioctl probe, chmod/chown KGSL nodes, alter SELinux, or
launch Steam through `su`.

## Cleanup and authentication boundary

After capture, stop only the exact R43 Steam/PRoot/X11 processes. Remove only:

```text
/data/local/tmp/thor-rootless-r43-sysvipc-20260812T153000Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r43/
/data/data/com.termux/files/home/.nova-rootless-r43/
```

Verify no matching process or TCP 6077 listener remains, verify both rooted
rollback paths, and record post-cleanup free space. If the Termux helper is
invoked outside its normal Termux environment, ensure its required variables
are present before using it; otherwise use only the exact recorded PID as a
fallback. Never broad-kill Termux, clear app data, delete
`/data/local/tmp/nova-active-runtime`, or touch the preserved rooted runtime.

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, authenticated Steam home, or `steam.token` contents may be read,
copied, backed up, committed, or exported.
