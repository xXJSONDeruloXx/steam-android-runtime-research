# AYN Thor rootless verified stable ARM64 payload replay — predeclaration — 2026-08-11

Run ID: thor-rootless-stable-payload-replay-20260811T175138Z; sub-run:
Thor-rootless-official-stable-native-payload-replay.

Status: predeclared after doc 483. This is a client-payload provenance
experiment, not R31 and not a Vulkan, /dev/shm, D-Bus, Runtime 4, Proton,
Gamescope/AHardwareBuffer, SteamUI patch, or packaging experiment.

## Question and one changed variable

Doc 483 proved that removing package/beta changes the client-reported channel
to steamdeck_stable, but the fresh staged tree retained the older public-seed
native hashes and did not perform a stable update transaction. The official
stable endpoint nevertheless supplied a reproducible ARM64 payload whose
native hashes match the stable pairing used by the audited SteamClientTermux
path.

The one changed variable in this run is therefore the native client payload
bytes: apply the verified Valve stable bins_linuxarm64_linuxarm64 payload to
a fresh sanitized client tree before launch. Preserve its official paths,
file modes, and symlink entries. This is an upstream payload replay, not a
guessed vgui2_s.dll alias, file rename, binary patch, or SteamUI patch.

Keep fixed from doc 483:

- the Holo ARM64 rootfs and 161-package plus 2-asset closure;
- app-UID PRoot -0, the nested /opt/nova-steam/home layout, and short
  files/r34/proot-tmp and files/r34/tmp paths;
- the rooted SteamRT-first PATH and LD_LIBRARY_PATH;
- inherited Android networking and a fresh app-owned resolver;
- direct TCP Termux:X11 at DISPLAY=127.0.0.1:77;
- the physical KGSL/Turnip files, with both Vulkan selector variables unset;
- the exact Steam flags and no SteamUI, runtime, or compositor changes; and
- fresh app-owned Steam state, logs, resolver, temporary paths, X11 process,
  listener, screenshot, and readiness baseline.

Do not add /dev/shm, a machine-id, D-Bus, VK_ICD_FILENAMES,
VK_DRIVER_FILES, LD_PRELOAD, Mesa overrides, Runtime 4, Proton, FEX, DXVK,
Gamescope, AHardwareBuffer, an input/audio bridge, or a product/APK change.

## Device and exact scopes

~~~text
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
branch=feat/rootless-steamclienttermux-profile
~~~

~~~text
/data/local/tmp/thor-rootless-stable-payload-replay-20260811T175138Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r34/
/data/data/com.termux/files/home/.nova-thor-stable-payload/
~~~

Preserve and verify these rooted rollback paths:

~~~text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
~~~

Use a cold, fresh r34 mutable scope. The host stable payload fixture may be
reused only after rechecking its hashes; do not reuse Steam HOME/config,
package/update state, logs, temporary directories, X11 state, screenshots, or
readiness results.

## Stable payload gate

Before device staging, require the exact official endpoint artifacts already
verified by doc 483:

~~~text
manifest_url=https://client-update.steamstatic.com/steam_client_linuxarm64
manifest_sha256=a2ad912ef6f150d373504a80c79f95210f8ed4ddbc42071593d0a120eb96ca91
stable_version=1785799196
payload=bins_linuxarm64_linuxarm64.zip.vz.11771d05f91515ca5337eeb9baf835098df71d3a_60815678
payload_size=60815678
payload_sha256=38dad8316435b1aea099f16c4eefb5da1fd57faa59fafe659945879ad5ae5148
decoded_zip_size=337453898
decoded_zip_sha256=aed451902b2239cbf8a16e1a2004e016cea803d562849a4969b01a93c9cb4821
decoded_entries=55
~~~

Decode and verify the VZ CRC and ZIP listing before copying anything to Thor.
Extract the official native payload into the fresh client tree at exactly
steamrtarm64/. The selected hashes must be:

~~~text
steamrtarm64/steam
  sha256=72f48fb9c3f2c19cf64f8f7bbf4c7b7af65a73571ae0eeaab05bffd1633f4126
steamrtarm64/steamui.so
  sha256=25ad66cfc78590b1745301ae7b86b70db64f5be0cd142d33134796e203fc8b76
steamrtarm64/vgui2_s.so
  sha256=705f45328bb03c42509d28b748b0b499938f5e0caf2db618e8c929f0c3044186
steamrtarm64/steamwebhelper
  sha256=3176d90436e49f7d34524ca2686cd324e2583806ba78841852b189fbcee0b83c
~~~

The staged tree must have no package/beta selector. Preserve the rest of the
sanitized public seed unchanged except for the official stable native payload
replacement. Do not synthesize package files, aliases, or wrapper executables.
If applying the payload requires an additional package metadata mutation, stop
and predeclare that as a separate experiment rather than folding it into this
run.

## Fixed launch contract

Use the exact rooted parity environment from doc 483:

~~~text
HOME=/opt/nova-steam/home
USER=steam
LOGNAME=steam
LANG=C
LC_ALL=C
XDG_RUNTIME_DIR=/tmp/nova-steam-runtime
PATH=/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/bin:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/bin:/usr/bin:/bin
LD_LIBRARY_PATH=/opt/nova-steam/home/.local/share/Steam/steamrtarm64:/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu:/usr/lib:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu/pulseaudio
DISPLAY=127.0.0.1:77
unset LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_LAYER_PATH VK_ICD_FILENAMES VK_DRIVER_FILES
cd /opt/nova-steam/home/.local/share/Steam
exec /opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -skipinitialbootstrap -no-child-update-ui
~~~

Preflight must show a real app UID, the fresh r34 paths, the free-space floor,
the exact resolver, and no root/su/chroot/mount escape in the Steam launch.

Start the X11 server through the APK bridge, explicitly foreground
com.termux.x11/.MainActivity, and require the fresh app-UID display handshake.
If the Android device-log consent dialog appears, capture its text and use a
targeted scroll/tap only to grant the one-time log access. If it is absent,
record log_access_consent=not-shown. Record the default helper path if the
APK again uses .nova-rootless rather than the declared Termux scope.

## Evidence and acceptance

Capture before teardown:

- endpoint headers, manifest/payload hashes, VZ/ZIP verification, and selected
  pre-launch stable hashes;
- device/APK identity, Holo/provider/PRoot hashes, app UID and SELinux/DAC
  evidence separately;
- exact staged-tree diff/provenance showing only the official native payload
  changed and package/beta is absent;
- rootfs extraction, closure, resolver, preflight, exact command/environment,
  X11 PID/listener, foreground result, and xprop handshake;
- fresh bootstrap, update-UI, Steam/SteamUI/webhelper logs, process state,
  screenshot dimensions/SHA-256, and the first client boundary; and
- exact cleanup, property restoration, post-cleanup free space, preserved
  rooted paths, and no-auth filename-only checks.

Classify in this order:

1. any payload/hash/device/UID/stale-state mismatch is invalid;
2. a short-temporary-path warning is an infrastructure failure;
3. a fresh stable native payload still returning vgui2_s keeps the
   client-loader boundary open;
4. crossing vgui2_s is only a native SteamUI/webhelper milestone; classify
   Vulkan, /dev/shm, D-Bus, X11, and visible presentation separately.

Do not call a black X11 canvas a Steam frame. Do not advance to the next
runtime prerequisite in the same run.

## Cleanup guardrail

After capture, force-stop only Nova and Termux:X11, verify and terminate the
exact fresh X11 PID, restore termux.properties byte-for-byte, and remove only
the three r34 scopes plus the exact fresh default X11 log/PID files if they
were created. Verify no Steam, webhelper, PRoot, or X11 process remains, no
6077 listener remains, the rollback paths still exist, and no authentication
secret/session state was read, copied, backed up, committed, or exported.
