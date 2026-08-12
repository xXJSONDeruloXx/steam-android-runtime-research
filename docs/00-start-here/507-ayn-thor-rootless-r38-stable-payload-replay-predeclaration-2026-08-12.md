# AYN Thor rootless R38 official stable ARM64 payload replay — predeclaration — 2026-08-12

Run identity: `thor-rootless-r38-stable-payload-replay-20260812T001312Z`;
sub-run: `R38-official-stable-native-payload-replay`.

Status: predeclared as the single next native-client experiment after doc
506. R37 failed before any update transaction because its older public seed
returned the native `vgui2_s` fatal. R38 answers the nearest unresolved
question: does the verified official stable ARM64 native payload cross that
loader boundary under the same app-UID Thor rootless transport?

This is a client-payload/channel provenance experiment. It is not a Vulkan,
KGSL, `/dev/shm`, D-Bus, Runtime 4, Proton, FEX/DXVK, Gamescope/AHardwareBuffer,
SteamUI patch, input/audio, or APK experiment.

## One controlled change

Use the official stable ARM64 payload gate from docs 483 and 484, applied to a
fresh credential-free stable-channel client tree. The source tree must have no
`package/beta` selector and must contain the official stable native payload at
`steamrtarm64/`. Do not rename, alias, patch, or synthesize any native file.

The host-only gate must be completed before any Thor mutation:

```text
manifest_url=https://client-update.steamstatic.com/steam_client_linuxarm64
manifest_sha256=a2ad912ef6f150d373504a80c79f95210f8ed4ddbc42071593d0a120eb96ca91
stable_version=1785799196
payload=bins_linuxarm64_linuxarm64.zip.vz.11771d05f91515ca5337eeb9baf835098df71d3a_60815678
payload_bytes=60815678
payload_sha256=38dad8316435b1aea099f16c4eefb5da1fd57faa59fafe659945879ad5ae5148
decoded_zip_bytes=337453898
decoded_zip_sha256=aed451902b2239cbf8a16e1a2004e016cea803d562849a4969b01a93c9cb4821
decoded_entries=55
```

If the live endpoint no longer matches these pinned values, stop at the
host-only gate and create a new predeclaration. Do not silently substitute a
new channel or payload.

Required selected native hashes:

```text
steamrtarm64/steam=72f48fb9c3f2c19cf64f8f7bbf4c7b7af65a73571ae0eeaab05bffd1633f4126
steamrtarm64/steamui.so=25ad66cfc78590b1745301ae7b86b70db64f5be0cd142d33134796e203fc8b76
steamrtarm64/vgui2_s.so=705f45328bb03c42509d28b748b0b499938f5e0caf2db618e8c929f0c3044186
steamrtarm64/steamwebhelper=3176d90436e49f7d34524ca2686cd324e2583806ba78841852b189fbcee0b83c
```

The staged tree must be freshly reconstructed from credential-free public
inputs. It may reuse only the sanitized public seed and the official stable
payload after the host gate proves the exact resulting tree. Do not reuse
Steam HOME/config, package/update state, logs, temporary directories, X11
processes, sockets, screenshots, readiness, or any authenticated data. If the
stable tree cannot be produced without an additional metadata mutation beyond
the declared channel selection and official payload application, stop and
predeclare that difference separately.

## Device and scopes

```text
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
branch=feat/rootless-steamclienttermux-profile
```

Use cold, fresh scopes:

```text
/data/local/tmp/thor-rootless-r38-stable-payload-replay-20260812T001312Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r38/
/data/data/com.termux/files/home/.nova-rootless/
```

Preserve and verify untouched:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

The current APK bridge may use the default `.nova-rootless` helper scope; if
so, record that fact and remove only its exact fresh R38 files. Temporarily
enable Termux external commands only if needed, back up
`termux.properties`, and restore it byte-for-byte during cleanup.

## Fixed rootless contract

Recheck before staging:

```text
Holo system.rootfs.zst=384971555 bytes,
  sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
Holo UI/audio closure=161 packages plus 2 Debian GTK2 assets
PRoot sha256=6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a
PRoot loader sha256=44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04
libtalloc.so.2.4.3 sha256=3c9b207c0a6ea2896b7523e03f55d9ab0d9e88baa115d4c32b84058ff4246fbb
libandroid-shmem.so sha256=84475798e07c8174dbbfaec70a827fdb02f19ffa69a589380c13e7507fd0e731
```

Use the established short app-owned temporary paths from the valid Thor
stable-channel baseline:

```text
NOVA_ROOTLESS_STATE=files/r38/state
NOVA_ROOTLESS_PROOT_TMP_DIR=files/r38/proot-tmp
NOVA_ROOTLESS_TMP_DIR=files/r38/tmp
```

Keep fixed:

```text
rootless_guest_mode=PRoot -0
outer_uid=10138
display=127.0.0.1:77
network=Android-inherited namespace
resolver=fresh app-owned file from current Android DNS
Vulkan selectors=unset
LD_PRELOAD/Mesa/software-GL overrides=unset
```

Do not add `VK_DRIVER_FILES`, `VK_ICD_FILENAMES`, `VK_LOADER_DEBUG`,
`LD_PRELOAD`, `MESA_LOADER_DRIVER_OVERRIDE`, `GALLIUM_DRIVER`,
`LIBGL_ALWAYS_SOFTWARE`, `VK_IMPLICIT_LAYER_PATH`, `/dev/shm`, a machine-id,
D-Bus, Runtime 4, Proton, FEX/DXVK, Gamescope, AHardwareBuffer, a controller
bridge, an audio bridge, or a SteamUI/client patch.

The guest command remains:

```text
HOME=/opt/nova-steam/home
USER=steam
LOGNAME=steam
LANG=C
LC_ALL=C
XDG_RUNTIME_DIR=/tmp/nova-steam-runtime
DISPLAY=127.0.0.1:77
PATH=/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/bin:/opt/nova-steam/home/.local/share/Steam/steamrt3c_platform_3c.0.20260714.251839/files/bin:/usr/bin:/bin
LD_LIBRARY_PATH=/opt/nova-steam/home/.local/share/Steam/steamrtarm64:/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu:/usr/lib:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu/pulseaudio
cd /opt/nova-steam/home/.local/share/Steam
exec /opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -skipinitialbootstrap -no-child-update-ui
```

## Evidence and decision tree

Before launch capture the host endpoint/payload gate, full staged-tree diff,
selected hashes, device identity, app UID/SELinux identity, DAC/KGSL metadata,
free space, resolver, exact preflight, effective environment, PRoot command,
X11 PID/listener, and the consent result. If the Android device-log dialog is
shown, capture its text and use only a targeted one-time grant; otherwise record
`log_access_consent=not-shown`.

Capture fresh updater, SteamUI, webhelper, X11, process, listener, and screenshot
evidence before teardown. A black X11 canvas is not a Steam frame.

Classify in order:

1. Wrong endpoint/hash/device/UID, stale state, auth exposure, helper drift,
   or undeclared variable: `invalid`.
2. Stable payload is verified and the old `vgui2_s` fatal remains:
   `stable-client-loader-boundary-remains-open`.
3. `vgui2_s` is absent and native SteamUI/webhelper starts:
   record the native milestone, then classify Vulkan, `/dev/shm`, D-Bus, X11,
   and visible presentation independently.
4. Do not advance to a second prerequisite in the same run.

The experiment is successful only if the launched hashes match the official
stable gate. Endpoint provenance alone is not a launch result.

## Prior-art boundary

The audited sibling revision is
`8d14c10195b34fe2714ba59df1680df27a852532`. Its public README reports native
ARM64 Steam UI and games on Snapdragon/Adreno, while its launcher uses a
patched PRoot for robust-list/seccomp, SysV semaphore, Pressure Vessel/shared
temporary paths, private D-Bus/Mesa, software CEF, and Android network/audio
contracts. R38 intentionally imports none of those broader changes. See the
[sibling README](https://github.com/huntergdavis/steamclienttermux) and its
[launcher](https://github.com/huntergdavis/steamclienttermux/blob/c0ada6ea2f56a96872af2190f69f4b5385c68ee2/bin/steam-arm).

The [Termux:X11 upstream PRoot contract](https://github.com/termux/termux-x11#using-with-proot-environment)
requires `--shared-tmp` or an equivalent matching `TMPDIR`. R38 retains Nova's
existing short app-owned temporary path and direct TCP X11 so that contract is
not confounded with the client-payload question.

## Cleanup and authentication boundary

After evidence capture, terminate only the verified R38 X11 PID, force-stop
only Nova/Termux:X11/Termux sessions started by R38, restore Termux properties,
remove only the three exact R38 scopes, verify no Steam/PRoot/webhelper/X11
process or 6077 listener remains, and verify both rooted rollback paths.

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, authenticated Steam home, or `steam.token` contents may be read, copied,
backed up, committed, or exported.
