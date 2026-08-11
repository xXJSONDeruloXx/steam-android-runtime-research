# AYN Thor rootless R31 — `VK_DRIVER_FILES` replication predeclaration — 2026-08-11

Run identity: `thor-rootless-r31-vk-driver-files-20260811T153030Z`;
sub-run: `R31-Thor-rootless-supervisor-vk-driver-files-selector`.

Status: predeclared. This is a hardware replication of the already declared
R31 selector A/B on an AYN Thor (`kalama`, Snapdragon 8 Gen 2 class), not a
replacement for the Nova result. Evidence from this run must remain separate
from the Retroid Pocket Nova result.

## Hardware and artifact gate

The target is:

```text
model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
root=available (Magisk uid 0)
```

The Thor is a clean target for this project. The Nova rooted rollback paths
are not present and must not be fabricated or treated as evidence:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

The R31 client gate remains the exact sanitized public rooted client:

```text
archive_bytes=3447515136
archive_sha256=4c62a8e35144b653864c31d84e682814a82384c3746001293e019d98bde25288
steamrtarm64/steam_sha256=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so_sha256=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so_sha256=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
```

The only local Steam tree currently available on the host is the older
public-seed bootstrap tree, not that sanitized rooted archive:

```text
archive=android/nova-lab/build/steam-bootstrap/steam-home.tar.gz
archive_bytes=1756623692
archive_sha256=1f4336e1e7a0f620e08c0be6850960b611841e50b1ab7bf455387489f5b83124
steamrtarm64/steam_sha256=cb5ba36e6462b6ad8901c9fe51a4df54933669de6c354754399f9ab4c7e5fc85
steamrtarm64/steamui.so_sha256=972b2290aef95771fc716dbc0e4cf8d27bd846e3b738a596148fbe67b6346ad0
steamrtarm64/vgui2_s.so_sha256=a3e010415d3b1cda22a9fe6ad8e5a33e558113483cbc7639ec4cae560c676dd7
```

Therefore a run using the local bootstrap tree is not a valid exact R31
selector A/B. It may only be used later as a separately named exploratory
bootstrap observation, with its client difference called out. Do not silently
substitute it for the R31 client or claim a Vulkan result against the Nova
baseline. The exact R31 archive must be transferred from a verified source or
recreated from the preserved Nova public tree before a valid Thor R31 launch.

## Controlled R31 variable

Once the exact client gate passes, keep the R30 contract fixed: Holo ARM64
rootfs and 161-package closure, app-UID PRoot `-0`, nested Steam layout,
rooted SteamRT-first environment, fresh app-owned state, inherited Android
network, direct TCP Termux:X11, `/dev` and `/proc` bindings, and the pinned
KGSL/Turnip files:

```text
libvulkan_freedreno.so size=12364688 sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
freedreno-kgsl.icd.json size=194 sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
```

The one changed guest selector is:

```text
unset VK_ICD_FILENAMES
export VK_DRIVER_FILES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
unset LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_LAYER_PATH
```

Do not add `/dev/shm`, D-Bus, Runtime 4, Proton, Gamescope/AHardwareBuffer,
SteamUI changes, or additional Mesa variables.

Thor-specific fresh scopes are:

```text
/data/local/tmp/thor-rootless-r31-vk-driver-files-20260811T153030Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/thor-r31/
/data/data/com.termux/files/home/.nova-thor-r31/
```

No authentication data may be read, copied, backed up, or exported.

## Android and Termux preflight

The current Thor APK was installed from the repository debug artifact. The
first rootless bridge attempt failed before X11 because Termux's existing
configuration had `allow-external-apps` commented out. The bounded setup step
may uncomment that single Termux setting, preserving a copy in the Thor run
scope and restoring it during exact-scope cleanup. No other Termux data or
Android package state is in scope.

If Android presents the one-time “Allow Nova Steam to access all device logs?”
gate, inspect it through `uiautomator` first, accept only the explicit
permission requested by the user, and record the result before collecting
early logs. Do not bypass it with a persistent privilege change. If no such
gate appears, record `log_access_consent=not-shown`.

## Evidence and classification

Capture the exact client/provider/rootfs provenance, preflight, command and
environment, Steam/bootstrap/UI/webhelper logs, Termux:X11 log, screenshot,
process/listener state, and read-only `/dev/kgsl*` visibility/access evidence.
Classify against R31's existing decision tree:

- explicit ICD/driver discovery or physical-device enumeration is recorded
  separately from presentation/WSI;
- the R30 Vulkan failure without the R29 crash means the selector is
  non-discriminating on Thor;
- the R29 updater/X11 `SIGSEGV` confirms the selector/provider crash boundary;
- a client or preflight mismatch is an invalid replication, not a Vulkan
  conclusion.

After capture, remove only the Thor R31 scopes and exact fresh X11/session
processes, verify port 6077 is absent, and report the device's post-cleanup
free space. No Nova rollback-path assertion applies to this Thor run.
