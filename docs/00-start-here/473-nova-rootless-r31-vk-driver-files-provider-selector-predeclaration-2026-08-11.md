# Nova rootless R31 — `VK_DRIVER_FILES` provider-selector predeclaration — 2026-08-11

Run ID: `nova-rootless-r31-vk-driver-files-provider-selector-20260811T145900Z`;
sub-run: `R31-rootless-supervisor-vk-driver-files-selector`.

Status: predeclared. R31 is the single loader/provider experiment justified
by R30. It changes only the Vulkan ICD selector syntax relative to the R30
provider-off control. It does not add a shared-memory directory, D-Bus, a
privileged escape, a Mesa override, Runtime 4, Proton, Gamescope,
AHardwareBuffer, SteamUI changes, or packaging work.

## Question and hypothesis

R29 selected the pinned rooted KGSL/Turnip ICD with:

```text
VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
```

That run ended in the updater/X11 path with `signal 11` before producing
Vulkan or SteamUI evidence. R30 held the same provider files physically
staged but explicitly unset the selector. It crossed the R29 crash, reached
native SteamUI/webhelper, and reproduced the later Vulkan and webhelper
boundaries.

The narrow next hypothesis is that the loader/provider interaction differs
between `VK_ICD_FILENAMES` and the `VK_DRIVER_FILES` contract used by the clean
SteamClientTermux prior-art launcher. This is a selector hypothesis only; the
prior art does not authorize importing its Mesa, PRoot, D-Bus, network, audio,
or Proton environment.

## Fixed inputs

Keep the R30/R28 baseline unchanged:

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
- rooted SteamRT-first `PATH` and `LD_LIBRARY_PATH`;
- `HOME=/opt/nova-steam/home`, `USER=steam`, `LOGNAME=steam`, `LANG=C`,
  `LC_ALL=C`, and `XDG_RUNTIME_DIR=/tmp/nova-steam-runtime`;
- app-UID PRoot `-0`, `/dev` and `/proc` bindings, resolver, fresh state,
  direct TCP Termux:X11 `DISPLAY=127.0.0.1:77`, and the R30 Steam flags; and
- provider files at `/opt/nova-kgsl-driver/` with these exact hashes:

```text
libvulkan_freedreno.so size=12364688 sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
freedreno-kgsl.icd.json size=194 sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
```

Do not read, copy, back up, or export Steam authentication state.

## Near-term fast-fixture profile

R31 is a fast A/B when the device already has an intact, hash-verified R30/R28
fixture. Do not repeat the multi-gigabyte client copy, Holo archive
extraction, or 161-package transaction solely to change the ICD selector.
Reuse only the immutable sanitized client/rootfs/provider/helper inputs after
recording their fixture marker and rechecking the pinned hashes. This does
not authorize reuse of any Steam HOME, config, updater/package state, logs,
temporary path, screenshot, X11 process, socket, or readiness result.

The R31 run must still create fresh app/device/Termux state, a fresh resolver
and temporary directory, a fresh Termux:X11 `:77` process/listener, fresh
Steam/SteamUI/webhelper logs, and a fresh screenshot. Verify the fixture after
teardown; if any immutable input changed, invalidate it and cold-provision a
new fixture before another A/B. If the current supervisor cannot demonstrate
that mutable Steam paths are isolated from the reused client fixture, fall
back to cold provisioning and record that limitation rather than silently
reusing a mutable tree.

Fixture reuse is a staging optimization only. It does not relax the one-change
contract: the only experimental variable remains `VK_DRIVER_FILES`.

## One changed variable

The effective R31 guest command must add exactly:

```text
export VK_DRIVER_FILES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
```

It must explicitly keep the other selector and exploratory variables unset:

```text
unset VK_ICD_FILENAMES
unset LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_LAYER_PATH
```

Do not add `LD_LIBRARY_PATH` entries, `LIBGL_DRIVERS_PATH`,
`MESA_LOADER_DRIVER_OVERRIDE`, `TU_DEBUG`, or any other SteamClientTermux
variable in this run. If a future experiment needs one of those, predeclare
it separately after R31.

## Evidence and decision

Capture the same fresh evidence as R30: exact client/provider/rootfs hashes,
preflight, command/environment, Steam bootstrap, `steamsysinfo`, SteamUI
system/HTML logs, webhelper log, Termux:X11 log, screenshot with the Android
log-consent gate handled, process/listener state, read-only device-node
inspection, and exact-scope cleanup.

Classify the result as follows:

- If the loader reaches an explicit ICD/driver message or Vulkan enumeration,
  record that provider-loader contract separately from any later `/dev/shm`,
  D-Bus, X11, or UI failure. Do not claim presentation is solved from device
  enumeration alone.
- If R31 reproduces R30's `CVulkanTopology`/`vkEnumeratePhysicalDevices`
  failure while remaining free of the R29 crash, `VK_DRIVER_FILES` reached a
  different or non-discriminating loader path; stop and record the loader
  result before choosing another variable.
- If R31 reproduces R29's updater/X11 `signal 11`, the selector/provider
  interaction is confirmed as the crash boundary. Do not add `/dev/shm` or
  D-Bus until a loader-only explanation is documented.
- If `vgui2_s` returns or preflight/client provenance changes, classify the
  run as a replay regression and repair the harness before interpreting
  Vulkan.

R31 is not authorized to make `/dev/shm`, machine-id/D-Bus, Runtime 4,
Proton, Gamescope/AHardwareBuffer, or packaging the next variable. The
Android log-consent foreground gate is a lifecycle observation only: if the
one-time prompt appears, verify and clear it before screenshots, and record
it without granting persistent device-log access.

## Scope and lifecycle

Use fresh scopes:

```text
/data/local/tmp/nova-rootless-r31-vk-driver-files-20260811T145900Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r31/
/data/data/com.termux/files/home/.nova-rootless-r31/
```

The current `RootlessTermuxBridge` still does not propagate a custom
`NOVA_ROOTLESS_TERMUX_STATE` into the Termux-sourced helper. Before accepting
R31 as valid, either fix that harness contract in a separately justified
change or explicitly record and clean the actual default
`/data/data/com.termux/files/home/.nova-rootless/` path. Never silently reuse
it as if it were the declared fresh scope.

Read [doc 34](34-nova-runtime-harness-lifecycle.md) before launch. Run
`android/nova-lab/test-rootless-profile.sh` and require
`rootless_profile_static=pass`. Preserve:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

After evidence capture, remove only the R31 app/device/Termux scopes and any
actual default helper scope created by that run. Verify that no Steam, PRoot,
webhelper, or Termux:X11 process remains, TCP port 6077 is absent, and both
preserved rooted paths still exist.
