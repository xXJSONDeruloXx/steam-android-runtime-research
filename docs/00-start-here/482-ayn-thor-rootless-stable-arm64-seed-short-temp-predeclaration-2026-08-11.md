# AYN Thor rootless stable ARM64 seed with short PRoot temporary path — predeclaration — 2026-08-11

Run ID: "thor-rootless-stable-arm64-short-temp-20260811T172139Z";
sub-run: "Thor-rootless-stable-arm64-seed-short-proot-temp".

Status: predeclared after [doc 481](481-ayn-thor-rootless-short-temp-public-seed-result-2026-08-11.md)
closed the independent long-temporary-path boundary. This is one fresh client
channel experiment. It is not an R31 Vulkan-selector, /dev/shm, D-Bus,
Runtime 4, Proton, Gamescope, SteamUI-patch, or packaging experiment.

## Question and controlled change

The older public ARM64 seed now fails at the native vgui2_s handoff even when
the PRoot temporary path is short. The next narrow question is whether the
stable ARM64 client pairing used by the audited SteamClientTermux path crosses
that client-loader boundary under the same Thor rootless transport.

Only the client channel/seed changes. Keep the short PRoot temporary paths,
rooted SteamRT-first environment, nested client layout, app-UID PRoot,
inherited Android network, direct TCP Termux:X11, provider files, and Steam
flags fixed.

The stable input must come from Valve's public ARM64 endpoint:

~~~text
https://client-update.steamstatic.com/steam_client_linuxarm64
~~~

Before launch, record the response bytes, HTTP result, archive/payload size
and SHA-256, stable manifest/version, and selected ARM64 client hashes. The
fresh staged stable tree must have no package/beta selector and must not be
patched or renamed. If the endpoint cannot provide a reproducible public
stable seed, stop and classify the setup rather than relaxing the gate.

## Device and scopes

~~~text
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
branch=feat/rootless-steamclienttermux-profile
~~~

The prior r32 tree was removed by the doc 481 cleanup, so this run must use a
fresh cold-provisioned r33 app scope. The host's verified immutable Holo,
package, PRoot, provider, and APK-helper inputs may be reused only after their
pinned hashes are rechecked. Do not reuse Steam HOME/config/updater state,
logs, temporary paths, X11 processes, sockets, screenshots, or readiness
baselines.

~~~text
/data/local/tmp/thor-rootless-stable-arm64-short-temp-20260811T172139Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r33/
/data/data/com.termux/files/home/.nova-thor-stable-arm64/
~~~

The current APK bridge does not propagate a custom
NOVA_ROOTLESS_TERMUX_STATE. If it again uses the default
/data/data/com.termux/files/home/.nova-rootless/ helper scope, record that
fact and remove only the exact fresh X11 log/PID files it creates.

## Fixed runtime contract

Use the same immutable inputs and app-owned Holo closure as doc 481:

- Holo ARM64 system.rootfs.zst, 384971555 bytes, SHA-256
  7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf;
- the 161 Holo package files plus the two pinned Debian GTK2 assets;
- PRoot, loader, libtalloc symlink closure, and libandroid-shmem hashes from
  doc 481;
- KGSL/Turnip files at guest /opt/nova-kgsl-driver with the pinned
  libvulkan_freedreno.so and freedreno-kgsl.icd.json hashes; and
- a fresh app-owned resolver using the current Android DNS value.

Keep all selector and exploratory provider variables unset:

~~~text
unset VK_ICD_FILENAMES VK_DRIVER_FILES
unset LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_LAYER_PATH
~~~

The physical provider files remain staged for parity, but this experiment does
not select them.

Use these short paths:

~~~text
NOVA_ROOTLESS_STATE=files/r33/state
NOVA_ROOTLESS_PROOT_TMP_DIR=files/r33/proot-tmp
NOVA_ROOTLESS_TMP_DIR=files/r33/tmp
DISPLAY=127.0.0.1:77
~~~

Start a fresh Termux:X11 server through the APK bridge, explicitly foreground
com.termux.x11/.MainActivity, and require a fresh app-UID xprop handshake
before Steam. Handle the Android device-log consent dialog only if it is
actually shown: verify its text, scroll the modal if necessary, and grant only
the one-time access option through a targeted ADB tap. If it is absent, record
log_access_consent=not-shown.

The guest launch environment and flags remain exactly:

~~~text
HOME=/opt/nova-steam/home
USER=steam
LOGNAME=steam
LANG=C
LC_ALL=C
XDG_RUNTIME_DIR=/tmp/nova-steam-runtime
PATH=/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/bin:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/bin:/usr/bin:/bin
LD_LIBRARY_PATH=/opt/nova-steam/home/.local/share/Steam/steamrtarm64:/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu:/usr/lib:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu/pulseaudio
cd /opt/nova-steam/home/.local/share/Steam
exec /opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -skipinitialbootstrap -no-child-update-ui
~~~

Do not add /dev/shm, machine-id, D-Bus, Runtime 4, Proton, Mesa
environment, audio/input bridge, Gamescope, AHardwareBuffer, SteamUI
patches, or guessed aliases.

## Acceptance and classification

Capture fresh rootfs/closure/preflight output, stable client provenance and
selected hashes, exact environment/command, resolver, X11 PID/listener,
xprop, Steam/bootstrap/update-UI logs, screenshot, process state, and
read-only /dev/kgsl* metadata. The positive client boundary is the absence of
the old vgui2_s fatal and progress into native SteamUI or webhelper. A visible
Steam frame is required before claiming display success.

Classify in this order:

1. setup/provenance mismatch or stale mutable state: invalid run;
2. short-temp warning returns: short-path infrastructure failure;
3. stable seed still returns vgui2_s: client-loader boundary remains open;
4. stable seed crosses vgui2_s: record the new SteamUI/webhelper/Vulkan
   boundary separately without adding another prerequisite in the same run.

No result from this experiment may be labeled R31. Do not infer Vulkan or WSI
from crossing vgui2_s alone.

## Cleanup

After evidence capture, force-stop only the Nova and Termux:X11 sessions,
terminate the exact fresh X11 PID after verifying its command, restore the
original Termux properties byte-for-byte, and remove only the three run scopes
plus any exact default helper log/PID files created by this run. Verify no
Steam/PRoot/webhelper/X11 process or 6077 listener remains and record
post-cleanup free space. Do not remove the preserved Nova rooted paths.

No Steam authentication secret, session token, cookie, QR state, or
authenticated Steam home may be read, copied, backed up, committed, or
exported.
