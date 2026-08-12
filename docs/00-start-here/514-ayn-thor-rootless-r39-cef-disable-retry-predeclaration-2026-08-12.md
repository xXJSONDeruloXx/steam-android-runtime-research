# AYN Thor rootless R39 CEF-disable retry — predeclaration — 2026-08-12

Run identity: `thor-rootless-r39-public-beta-cef-disable-retry-20260812T024229Z`.
Sub-run: `R39-retry-current-public-beta-cef-disable-gpu`.

Status: predeclared as a fresh infrastructure retry of [R39](513-ayn-thor-rootless-r39-public-beta-cef-disable-replay-predeclaration-2026-08-12.md).
The first R39 attempt was invalid before classification because the Termux:X11
helper used its default `.nova-rootless` state instead of the declared
run-specific `.nova-rootless-r39` state. That attempt is closed as invalid;
this retry changes no Steam, Vulkan, CEF, rootfs, client, or provider variable.

## Controlled experiment

Relative to the existing rootless public-beta R33 contract, add only:

```text
-cef-disable-gpu
```

Keep `VK_DRIVER_FILES`, `VK_LOADER_DEBUG=all`, the pinned KGSL/Turnip ICD and
driver, direct TCP Termux:X11 on `127.0.0.1:6077`, app-UID PRoot `-0`, the
R28 environment/library ordering, and all other R39 flags fixed. Keep
`/dev/shm`, D-Bus, machine-id, software-GL overrides, Runtime 4, Proton,
FEX/DXVK, Gamescope/AHardwareBuffer, input/audio helpers, SteamUI patches,
and privileged Steam launch paths absent.

## Fresh retry scopes

```text
/data/local/tmp/thor-rootless-r39-public-beta-cef-disable-retry-20260812T024229Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r39-retry/
/data/data/com.termux/files/home/.nova-rootless-r39/
```

The retry is valid only if all three scopes are fresh, the X11 PID and log are
created under `.nova-rootless-r39`, and no prior Steam/authenticated state is
read or reused. The preserved rooted rollback paths remain untouched:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Preconditions already satisfied

The retry fixture has passed the following gates before Steam launch:

```text
device=AYN Thor / kalama / d234a848 / Android API 33 / arm64-v8a
app_uid=10138
app_selinux=u:r:runas_app:s0:c138,c256,c512,c768
termux_uid=10135
rootfs_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
rootfs_bytes=384971555
public_client_gate=selected-tree-equivalence
steamrtarm64/steam=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
holo_ui_audio_closure=161 packages plus 2 Debian GTK2 assets
driver_sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
icd_sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
preflight=pass
inner_proot_identity=root
```

The client is app-UID extracted with normalized archive metadata. Native
executables are `0755`; `.steam` is `0700`; `.steam/steam` is the app-created
symlink `../.local/share/Steam`; forbidden authentication-bearing paths are
absent.

## Decision and evidence

Capture fresh bootstrap, SteamUI/webhelper, Vulkan-loader, supervisor, X11,
process, listener, screenshot, and read-only `/dev/kgsl*` evidence. If the
same Turnip physical-device enumeration and post-`vkCreateDevice` signal 11
recur, classify CEF-disable as not sufficient and stop before adding any
other variable. If the crash disappears, record native SteamUI/webhelper
progress separately from Vulkan presentation; do not infer OOBE or QR from a
black X11 canvas.

The first invalid attempt's useful diagnostic trace is not this retry's
acceptance evidence: it found the configured ICD, loaded Turnip Adreno 740,
and reached `vkCreateDevice` before PRoot signal 11, but its X11 lifecycle
scope was wrong.

No Steam authentication secret, session token, cookie, QR state,
machine-auth file, authenticated Steam home, or `steam.token` contents may be
read, copied, backed up, committed, or exported.
