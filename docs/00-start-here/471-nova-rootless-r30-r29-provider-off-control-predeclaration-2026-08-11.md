# Nova rootless R30 — R29 provider-off control predeclaration — 2026-08-11

Run ID: `nova-rootless-r30-r29-provider-off-control-20260811T144035Z`;
sub-run: `R30-rootless-supervisor-r29-provider-off-control`.

Status: predeclared. R30 is the single next-variable control required by R29's
pre-Vulkan crash. It is not a `/dev/shm`, D-Bus, loader-alternative, Proton,
Runtime 4, Gamescope, or packaging experiment.

## Question

R29 staged the correct rooted KGSL/Turnip provider and selected it with
`VK_ICD_FILENAMES`, then Steam crashed in updater/X11 startup before producing
Vulkan evidence. R30 keeps the provider files physically staged but removes
their selection from the effective guest environment. The purpose is to test
whether selecting the provider is the discriminating change, while holding
the rooted client/layout/environment contract fixed.

## Fixed inputs

Keep the R29/R28 baseline unchanged:

- sanitized public rooted-beta archive SHA-256
  `4c62a8e35144b653864c31d84e682814a82384c3746001293e019d98bde25288`;
- installed manifest SHA-256
  `4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7`;
- `steamrtarm64/steam` SHA-256
  `6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf`;
- `steamrtarm64/steamui.so` SHA-256
  `69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171`;
- `steamrtarm64/vgui2_s.so` SHA-256
  `aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e`;
- Holo rootfs `384971555` bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`;
- the exact 161-package UI/audio closure and two pinned GTK2 assets;
- rooted nested `/opt/nova-steam/home/.local/share/Steam` layout;
- `HOME=/opt/nova-steam/home`, `USER=steam`, `LOGNAME=steam`, `LANG=C`,
  `LC_ALL=C`, `XDG_RUNTIME_DIR=/tmp/nova-steam-runtime`;
- rooted SteamRT-first `PATH` and `LD_LIBRARY_PATH`;
- app-UID PRoot `-0`, `/dev` and `/proc` bindings, resolver, fresh state,
  direct TCP Termux:X11 `DISPLAY=127.0.0.1:77`, and the R29 Steam flags; and
- the provider files at `/opt/nova-kgsl-driver/` with their pinned hashes,
  even though R30 will not select them.

No authenticated Steam home, config, cookie, QR/session data, or other
authentication state may be copied or read.

## One changed variable

R30 must explicitly unset the provider selector in the guest command:

```text
unset VK_ICD_FILENAMES
```

Keep these variables unset as in R29:

```text
LD_PRELOAD
MESA_LOADER_DRIVER_OVERRIDE
GALLIUM_DRIVER
LIBGL_ALWAYS_SOFTWARE
VK_IMPLICIT_LAYER_PATH
```

Do not replace `VK_ICD_FILENAMES` with `VK_DRIVER_FILES` in R30. That would be
a second provider-loader hypothesis and is only justified if this control
proves that the current selector is the discriminating boundary.

## Acceptance and decision

Capture the same fresh client, SteamUI, webhelper, Vulkan, X11, screenshot,
process, and cleanup evidence required by R29.

- If provider-off R30 returns to R28's `Client version`/native SteamUI or
  webhelper boundary, classify R29's crash as provider-selection/provider
  interaction and predeclare a loader/provider-only follow-up.
- If R30 crashes at the same updater/X11 point, provider selection is not the
  discriminating variable; do not add `/dev/shm` or D-Bus, and predeclare only
  a targeted native-crash/loader evidence experiment afterward.
- If `vgui2_s` returns, treat R30 as a regression or invalid replay and
  compare all R28 environment/layout/client hashes before drawing conclusions.

R30 must not advance to `/dev/shm`, D-Bus, Runtime 4, Proton, Gamescope,
AHardwareBuffer, SteamUI patches, or product packaging until this control is
closed.

## Scope and lifecycle

Use fresh, separately named scopes:

```text
/data/local/tmp/nova-rootless-r30-r29-provider-off-20260811T144035Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r30/
/data/data/com.termux/files/home/.nova-rootless-r30/
```

The current `RootlessTermuxBridge` does not propagate a custom
`NOVA_ROOTLESS_TERMUX_STATE` into its Termux-sourced script. Before accepting
R30 as valid, the launcher path must either honor the run-specific Termux
scope above or explicitly record and clean the actual default scope as a
harness deviation. A hidden reuse of `/data/data/com.termux/files/home/.nova-rootless/`
must not be treated as a fresh run.

Read [doc 34](34-nova-runtime-harness-lifecycle.md) before launch. Preserve:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

Run `android/nova-lab/test-rootless-profile.sh` before device work and require
`rootless_profile_static=pass`. Remove only the R30 app, device, and Termux
scopes after evidence capture; verify no Steam/PRoot/webhelper/X11 process or
port-6077 listener remains. No Steam authentication secret may be read,
copied, backed up, committed, or exported.
