# Nova rootless R28 — rooted launch-environment/library-path parity result — 2026-08-11

Run ID: `nova-rootless-r28-rooted-launch-env-20260811T135325Z`;
sub-run: `R28-rootless-supervisor-rooted-launch-environment`.

Status: complete. Carrying the rooted launch environment into rootless was a
good idea: R28 crossed the earlier `vgui2_s` module fatal and reached native
SteamUI plus webhelper startup. The run then stopped at later rootless
provider/runtime prerequisites—no visible Vulkan device, no `/dev/shm`, and no
usable D-Bus machine/session contract—not at the client-tree boundary.

## Result

R28 held the current rooted public client bytes, rooted nested client-root,
Holo ARM64 rootfs, 161-package UI/audio closure, PRoot identity, TCP
Termux:X11, and client flags fixed. It changed only the guest launch
environment/library search path to match the rooted launcher:

```text
HOME=/opt/nova-steam/home
USER=steam
LOGNAME=steam
LANG=C
LC_ALL=C
XDG_RUNTIME_DIR=/tmp/nova-steam-runtime
PATH=/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/bin:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/bin:/usr/bin:/bin
LD_LIBRARY_PATH=/opt/nova-steam/home/.local/share/Steam/steamrtarm64:/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu:/usr/lib:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu/pulseaudio
```

The previous fatal did not recur:

```text
src/steamUI/Main.cpp (2385) : !"Fatal Error: Could not load module 'bin/vgui2_s.dll'"
Error: Could not load 'vgui2_s.so'
```

Instead, the client reported build `1786141909`, initialized its native
SteamOS/system controllers, loaded the SteamUI system component, and entered
the webhelper launch loop:

```text
[2026-08-11 13:59:51] Client version: 1786141909
[2026-08-11 13:59:51] Initialized CSystemAudioDeviceController: 1
[2026-08-11 13:59:51] Initialized CSystemDisplayController: 1
[2026-08-11 13:59:51] Initialized CSteamUINetworkController: 0
[2026-08-11 13:59:51] Started webhelper process 19724
```

That is the first positive rootless result after R25: the current rooted
client tree alone was not enough, and the rooted launch environment removed
the native SteamUI module-resolution boundary. Webhelper did not become
stable, so R28 did not reach OOBE, QR login, or a visible Steam frame.

## What “raw stable seed” meant here

The earlier rootless path was not the same runtime as the rooted happy path:

| Area | Earlier/rootless starting point | Rooted known-good path | R28 parity carried over |
|---|---|---|---|
| Client | Public ARM64 Steam seed plus incremental provider files | Current rooted public-beta tree, build `1786137466` | Exact sanitized current rooted public tree |
| Layout | Flattened `/opt/nova-steam`, `/home/nova`, rootless cwd | Nested `/opt/nova-steam/home/.local/share/Steam`, rooted HOME/cwd | Rooted nested layout and links |
| Launch env | Rootless defaults and minimal library path | `USER=steam`, `LANG=C`, rooted SteamRT-first `PATH`/`LD_LIBRARY_PATH`, `/tmp/nova-steam-runtime` | Rooted environment/library ordering |
| Privilege/display | App-UID PRoot and TCP X11 | Rooted helper/setpriv and `DISPLAY=:0` | App-UID PRoot and `DISPLAY=127.0.0.1:77` remained fixed |
| Device providers | No rooted driver bind in this run | Known-good KGSL/Turnip visibility | Deliberately deferred to isolate R28 |

So this was not an apples-to-apples “stable seed versus rooted” comparison
until R28. R26 tested the exact public rooted tree under the flattened layout;
R27 added the rooted nested layout; both still failed at `vgui2_s`. R28 then
added the rooted environment and crossed that boundary. This supports carrying
forward the rooted implementation’s known-good contracts into rootless, while
keeping each privileged provider (driver, shared memory, D-Bus, UID/GID) as a
separate experiment.

## Later failure classification

### 1. Vulkan provider visibility is not closed

The Steam client and `steamsysinfo` could not enumerate a physical device:

```text
CVulkanTopology: failed to get physical device count
Failed to query vulkan gpu topology
vkEnumeratePhysicalDevices failed, unable to init and enumerate GPUs with Vulkan.
BInit - Unable to initialize Vulkan!
```

R28 intentionally did not bind the known-good rooted KGSL/Turnip driver or
ICD. This is therefore a rootless Vulkan-provider visibility result, not yet a
Vulkan/WSI surface result and not evidence against the rooted client tree.

### 2. Webhelper has missing Linux runtime contracts

The fresh webhelper log shows both missing D-Bus and missing shared memory:

```text
Failed to connect to the bus: Failed to connect to socket /run/dbus/system_bus_socket: No such file or directory
Can't find session bus: Cannot spawn a message bus without a machine-id
Creating shared memory in /dev/shm/.com.valvesoftware.Steam... failed: No such file or directory
FATAL: ... Unable to access(W_OK|X_OK) /dev/shm
```

Steam retried webhelper eleven times in the captured `steamui_html` log. The
missing `/dev/shm` is a direct Chromium startup failure. Missing
`/var/lib/dbus/machine-id` or `/etc/machine-id` prevents the runtime launcher
from creating its session bus; it is a separate prerequisite and should not be
papered over with a SteamUI patch.

### 3. Nonfatal SteamOS integration warnings

`XRRGetOutputInfo()` was unavailable through the TCP X11 path, `xwininfo` was
not present, and the SteamOS-only `jupiter-dock-updater` helper was absent.
The client also logged failed controller shared-memory mappings because the
run did not provide `/dev/shm`. These are useful follow-up evidence, but they
are not the earlier `vgui2_s` loader failure.

The process eventually ended with:

```text
proot info: vpid 1: terminated with signal 4
```

No authentication state was read or exported, and the controller-config
assertions refer to fresh local state rather than a logged-in account.

## Artifact and device provenance

Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
`arm64-v8a`.

The exact sanitized rooted public archive was recreated and verified before
staging:

```text
archive_bytes=3447515136
archive_sha256=4c62a8e35144b653864c31d84e682814a82384c3746001293e019d98bde25288
sanitized_file_count=19557
package/beta sha256=ef339938036ee25c4f533210a35791d5faf9f69dcbc72cce173263005500f9e4
installed_manifest sha256=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
steamrtarm64/steam sha256=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so sha256=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so sha256=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
```

The pinned Holo inputs were unchanged:

```text
rootfs_archive_size=384971555
rootfs_archive_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
Holo/UI-audio package closure=161 packages
```

Fresh run artifacts were captured before teardown:

```text
/tmp/nova-r28-rootfs-extract.log
sha256=7fc2b00f089fc0338f5e82c20602dcb8f8874296299fa8dc8eb92ec9781c30a1

/tmp/nova-r28-guest-rootfs-prepare.log
sha256=62fff64dfb4a611ebbf338809191557bde275eaadfc2a2025c14052753a9536f

/tmp/nova-r28-supervisor-preflight.log
sha256=43e2b036ef98dc1dade9642e8ee859a60f01c9ca8ad01246847debe884e17529
preflight_free_kib=74117396

/tmp/nova-r28-rooted-launch-env-command.log
size=11558
sha256=f0e7408d8ffa78adabee561672f26c85ca8a8e389e61647b103177e023dbbdca

/tmp/nova-r28-bootstrap_log.txt
size=873
sha256=a0b53fb24a0ae5965703be8885b87f8c18448a90ecc29a93a83d73f3c0ad4978

/tmp/nova-r28-updateui_child.txt
size=99
sha256=c1cf116ee3f014e7266ccb717489402c3fb9696b401d33fa52f21988080dae73

/tmp/nova-r28-steamsysinfo.txt
size=325
sha256=528d178a488b053279b4e638564578124de368e27502ae7cc71caa5b19a9f29a

/tmp/nova-r28-steamui_system.txt
size=920
sha256=c5d7fca53bbe04bc6246248cf6fe98e690a0e8cb9d4ded34562aca1bdcfce2c4

/tmp/nova-r28-steamui_html.txt
size=2045
sha256=f3928167454b3bd0c514e125bf01ca65835872bf4f58b542abc50146c0cdddc1

/tmp/nova-r28-steamwebhelper.log
size=3610
sha256=fa3a246e5ff4344e8d5aab1c00bd2cc93607adc1ab1c1d7a305311ffc7330064

/tmp/nova-r28-webhelper.txt
size=25044
sha256=ed2ba6f4a301e2071ae2a2ebdd7974eec3b8ead2192165c5d3496c44f5871014

/tmp/nova-r28-termux-x11.log
size=6853
sha256=461c78f90d22f1f16072bca61278b358aa472a6781e2b32f5a79c37bec9eba24

/tmp/nova-r28-rootless-supervisor.log
size=1628
sha256=ab09831973b31cf51a63504212825e809a18681e317ff56adc35845f29847a5c
```

Fresh Termux:X11 was PID `19349`, launched as
`termux-x11 com.termux.x11 :77 -listen tcp -ac`, with listener `0.0.0.0:6077`.
The guest used `DISPLAY=127.0.0.1:77`. The captured screenshot was the Nova
launcher Activity after Steam exited, not a Steam frame:

```text
/tmp/nova-r28-rooted-launch-env-live.png
PNG 1280x960, size=102456
sha256=675dac3088dc124e2f7d15f2c8f3fe8c5650072186ee54baff3e3d1edfb00818
```

## Cleanup and rollback

After evidence capture, the APK was force-stopped and the exact fresh X11 PID
`19349` was terminated with root because it was owned by Termux. The exact
R28 app, Termux, archive, and infrastructure scopes were removed:

```text
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r28/
/data/data/com.termux/files/home/.nova-rootless/
/data/local/tmp/nova-r28-rooted-public.tar
/data/local/tmp/nova-r28-infra/
/data/local/tmp/nova-rootless-r28-rooted-launch-env-20260811T135325Z/ (absent)
```

Verification found no live R28 Steam/PRoot/Termux:X11 process and no port-6077
listener. Post-cleanup free space was `86109116 KiB`. The rooted rollback
remained intact:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

No Steam authentication secret was read, copied, backed up, or exported.

## Decision and next step

R28 validates the proposed strategy: bring the rooted happy-path contracts
forward into rootless first, then isolate the remaining privileged/runtime
boundaries. The raw seed is no longer the right comparison baseline for the
native client; the rooted public tree plus rooted nesting and launch
environment are now the rootless baseline candidate.

The next experiment should be predeclared as a driver-only parity test:

1. carry the known-good KGSL Turnip driver and Vulkan ICD into the same
   rootless guest-visible path;
2. keep the R28 client bytes, layout, environment, display, PRoot identity,
   and flags unchanged;
3. require fresh Vulkan topology and SteamUI/webhelper logs; and
4. only after that result, add an app-owned `/dev/shm` contract and then a
   minimal machine-id/session-bus contract as separate A/B experiments.

Do not add a SteamUI patch, guessed module alias, Runtime 4, Proton, or
Gamescope/AHardwareBuffer change until those provider/runtime prerequisites
are classified.
