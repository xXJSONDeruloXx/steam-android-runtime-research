# AYN Thor rootless current public-beta tree equivalence replay — predeclaration — 2026-08-11

Run identity: `thor-rootless-public-beta-equivalence-replay-20260811T191931Z`;
sub-run: `Thor-rootless-current-public-beta-tree-equivalence`.

Status: predeclared after the exact-client recovery gate in [doc 488](488-ayn-thor-rootless-exact-public-beta-recovery-gate-result-2026-08-11.md).
This is a full-tree provenance-equivalence experiment, not R31 and not a
Vulkan, `/dev/shm`, D-Bus, Runtime 4, Proton, Gamescope/AHardwareBuffer,
SteamUI-patch, or APK-packaging experiment.

## Question and one changed input

The historical R28 public-beta archive is unavailable, but the preserved
rooted Thor runtime still contains the same selected native client files,
public-beta selector, and installed manifest. Doc 488 recreated a fresh
authentication-free archive from that tree and recorded its complete hash.

This run tests whether that current sanitized public-beta tree is sufficient
to reproduce the rootless native-client boundary. Relative to the stable
payload replay, the only changed input is the client tree:

```text
archive_bytes=3457525760
archive_sha256=9a3507ce029c0aebe28ebd54ae03f79b56b1899e6ad4e530c88e9d33cbd0e7bb
steamrtarm64/steam=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
package/beta=ef339938036ee25c4f533210a35791d5faf9f69dcbc72cce173263005500f9e4
installed_manifest=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
```

This is explicitly not byte-equivalent to the historical R28 archive. The
run must report that distinction; a pass can establish selected-tree
equivalence for the observed `vgui2_s` boundary, not historical archive
identity.

## Fixed rootless contract

Keep doc 485's rootless Holo/PRoot, nested client layout, app UID `10138`,
fresh app-owned Steam state, inherited Android network, direct TCP
Termux:X11, and rooted SteamRT-first environment exactly fixed:

```text
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
```

Do not add rooted preloads, software-GL variables, Vulkan selectors,
`/dev/shm`, machine-id, D-Bus, Runtime 4, Proton, FEX, DXVK, Gamescope,
AHardwareBuffer, input/audio bridges, SteamUI patches, or guessed aliases.

## Thor scopes and freshness

```text
device_model=AYN Thor
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
/data/local/tmp/thor-rootless-public-beta-equivalence-replay-20260811T191931Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r36/
/data/data/com.termux/files/home/.nova-rootless-r36/
```

Only the verified immutable Holo/provider/PRoot/helper fixtures and the
recorded current client archive may be reused. Recreate Steam HOME, mutable
state, logs, resolver, temporary directories, X11 process/listener,
screenshots, and readiness baselines. If the APK bridge uses its default
`.nova-rootless` Termux helper scope, record and remove only the exact files
created there.

Before the first screenshot, check whether Android's device-log consent modal
is present. If present, verify its text, scroll it, and select only one-time
access through targeted ADB input. If absent, record
`log_access_consent=not-shown`.

## Evidence and classification

Capture the archive/tree hashes, rootfs/provider/PRoot hashes, device UID and
SELinux identity separately, app-UID preflight, exact environment and
command, X11 PID/listener/handshake, fresh Steam/bootstrap/SteamUI/webhelper
logs, process state, screenshot provenance, read-only KGSL metadata, and
exact-scope cleanup.

Classify in this order:

1. Any hash, device, UID, scope, environment, or freshness mismatch is
   invalid, not a Steam negative.
2. A fresh current tree returning `vgui2_s` keeps the native client-loader
   boundary open; do not infer Vulkan or webhelper behavior.
3. Absence of `vgui2_s` and native SteamUI/webhelper startup establishes
   selected-tree equivalence with R28/rooted for that boundary. It does not
   prove Vulkan presentation, `/dev/shm`, D-Bus, OOBE, or QR readiness.
4. If a visible Steam frame appears, record it without retaining QR or other
   authentication-bearing screenshots.

After capture, terminate only the exact fresh session, restore any temporary
Termux preference edit byte-for-byte, remove the three R36 scopes and exact
helper PID/log files, verify no matching process or port-6077 listener, and
verify the preserved rooted paths. Remove the retained host archive after
hashing/staging cleanup. No authentication state may be read, copied,
backed-up, committed, or exported.

## Follow-up decision

If this equivalence replay crosses `vgui2_s`, the next experiment remains the
already-predeclared Thor R31 `VK_DRIVER_FILES`-only selector test. If it does
not, stop at the client-loader differential and investigate only the
rootless loader/runtime contract; do not combine provider or webhelper fixes.
