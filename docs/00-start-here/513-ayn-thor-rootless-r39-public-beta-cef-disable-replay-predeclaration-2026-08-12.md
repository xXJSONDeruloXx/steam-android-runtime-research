# AYN Thor rootless R39 current public-beta CEF-disable replay — predeclaration — 2026-08-12

Run identity: `thor-rootless-r39-public-beta-cef-disable-20260812T014243Z`.
Sub-run: `R39-current-public-beta-cef-disable-gpu`.

Status: predeclared as the single next device experiment after R38. R38 did
not reach a native Steam boundary because stable-client staging and updater
state failed first. R39 returns to the current public-beta fixture that
already crossed `vgui2_s` and enumerated Turnip under rootless, then tests one
rooted/sister-repo UI difference.

This is not a `/dev/shm`, D-Bus, shared-`/tmp`, Runtime 4, Proton, Gamescope,
AHardwareBuffer, input/audio, APK, or SteamUI-patch experiment.

## Question and one changed variable

The same Thor rooted comparator reached OOBE and QR with:

- the current public-beta client;
- `-cef-disable-gpu`;
- software-GL controls; and
- rooted `/dev/shm`, D-Bus, mounts, preloads, and lifecycle helpers.

Rootless R33 used the current public-beta client, the pinned `VK_DRIVER_FILES`
provider selector, and otherwise fixed rootless transport. It loaded Turnip,
enumerated `Turnip Adreno (TM) 740`, reached `vkCreateDevice`, and then
crashed before SteamUI/webhelper. SteamClientTermux also uses
`-cef-disable-gpu` for its HTML interface while keeping a separate Turnip
path for games.

The hypothesis is deliberately limited:

> Adding only `-cef-disable-gpu` may avoid the CEF/UI GPU path implicated by
> the rooted comparator and sister-repo prior art, allowing rootless Steam to
> survive long enough to reach native SteamUI. If the crash remains, CEF is
> not sufficient evidence for the failure, which remains in the Vulkan
> device-use/Turnip/PRoot or another unmeasured boundary.

Relative to R33, the only launch-variable change is:

```text
add Steam flag: -cef-disable-gpu
```

Do not add software-GL variables in R39. Keeping Turnip selected is necessary
to distinguish CEF UI compositing from the game/provider path.

## Host fixture gate

Before touching the Thor, recover or recreate a fresh credential-free
current-public-beta fixture. The exact historical full archive is preferred:

```text
archive_bytes=3457525760
archive_sha256=9a3507ce029c0aebe28ebd54ae03f79b56b1899e6ad4e530c88e9d33cbd0e7bb
tar_entries=21513
steamrtarm64/steam=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
steamrtarm64/steamwebhelper=7a65e4f7c89dd2eeb0668f85ea0a06cf737507b7f3324407e5fc9a9a488c31d0
package/beta=steamdeck_publicbeta
installed_manifest=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
```

If the historical archive cannot be recovered, a newly reconstructed
credential-free tree may be used only with a clearly recorded selected-tree
equivalence gate matching doc 490. Do not call it byte-identical merely
because the selected native files match. If neither gate is available, stop
as invalid before device staging; do not substitute the stable R38 client.

The sanitization boundary remains the existing public-tree policy. Never read,
copy, search, or archive Steam userdata, cookies, tokens, QR/session state,
machine-auth files, `steam.token`, or an authenticated Steam HOME.

## App-owned staging contract

R38 exposed a preparation defect that must be corrected before R39, but this
is infrastructure, not the R39 experimental variable. The client must be
constructed so that the real app UID owns its mutable paths without a root
repair after extraction:

```text
outer_uid=10138
client_regular_files=created/readable by UID 10138
native executable files=0755
client directories=searchable by UID 10138
home/.steam=0700, owner 10138:10138
home/.steam/steam=symlink created by UID 10138 -> ../.local/share/Steam
archive ownership=ignored/normalized during app-UID extraction
root-side chown/chmod repair after staging=forbidden
```

The staging gate must prove those facts with `ls -ln`, `readlink`, and an
app-UID write/create/unlink smoke test before launch. A mode or ownership
mismatch invalidates the run; it must not be repaired and then treated as a
valid R39 result.

## Device and freshness contract

```text
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
app_selinux=u:r:runas_app:s0:c138,c256,c512,c768
```

Use fresh run scopes:

```text
/data/local/tmp/thor-rootless-r39-public-beta-cef-disable-20260812T014243Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r39/
/data/data/com.termux/files/home/.nova-rootless-r39/
```

Recreate Steam HOME, mutable Steam state, logs, resolver, temporary paths,
X11 process/listener, screenshots, and readiness baselines. Preserve and
verify untouched:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

Run `android/nova-lab/test-rootless-profile.sh` before device work and require
`rootless_profile_static=pass`. If Android shows the all-device-log consent
dialog, capture its text, scroll it if needed, and use only a targeted
one-time ADB acceptance. Do not select persistent access. If it is absent,
record `log_access_consent=not-shown`.

## Fixed immutable inputs

```text
holo_system.rootfs.zst_bytes=384971555
holo_system.rootfs.zst_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
holo_ui_audio_closure=161 packages plus 2 Debian GTK2 assets
proot_sha256=6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a
proot_loader_sha256=44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04
libtalloc.so.2.4.3_sha256=3c9b207c0a6ea2896b7523e03f55d9ab0d9e88baa115d4c32b84058ff4246fbb
libandroid-shmem.so_sha256=84475798e07c8174dbbfaec70a827fdb02f19ffa69a589380c13e7507fd0e731
libvulkan_freedreno.so_sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
freedreno-kgsl.icd.json_sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
```

Keep the pinned provider at:

```text
/opt/nova-kgsl-driver/libvulkan_freedreno.so
/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
```

## Exact rootless launch contract

Keep the R33 environment and flags exactly, then add only the declared Steam
flag:

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
VK_DRIVER_FILES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
VK_LOADER_DEBUG=all
unset VK_ICD_FILENAMES LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_LAYER_PATH
cd /opt/nova-steam/home/.local/share/Steam
exec /opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -cef-disable-gpu -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui
```

Use app-UID PRoot `-0`, direct TCP Termux:X11 on port 6077, inherited Android
networking, the fresh resolver, `/dev` and `/proc` bindings, and the existing
short app-owned temporary paths. Do not add `--shared-tmp` in R39; that is a
separate later experiment suggested by upstream Termux:X11 and
SteamClientTermux.

Keep explicitly absent:

```text
LIBGL_ALWAYS_SOFTWARE
MESA_LOADER_DRIVER_OVERRIDE
GALLIUM_DRIVER
LIBGL_DRIVERS_PATH
TU_DEBUG
MESA_VK_WSI_PRESENT_MODE
LD_PRELOAD
/dev/shm binding
machine-id
system/session D-Bus
Runtime 4
Proton/FEX/DXVK
Gamescope/AHardwareBuffer
input/audio bridge
SteamUI/client patch
root/su launch
```

## Evidence and classification

Capture before teardown:

- exact public-beta fixture and selected hashes;
- rootfs, PRoot, provider, and helper hashes;
- outer UID/SELinux identity and inner PRoot identity separately;
- staging modes/owners/symlink targets and app-UID smoke test;
- free space, resolver, exact environment, exact command, and PRoot command;
- fresh X11 PID/listener/handshake and consent result;
- Steam bootstrap, SteamUI, webhelper, Vulkan-loader, and native console logs;
- read-only `/dev/kgsl*` metadata and any correlated denial evidence;
- fresh screenshot provenance and process/listener state.

Classify in this order:

1. Any fixture, hash, mode/owner, device, UID, scope, environment, consent,
   or freshness mismatch is invalid.
2. If the old `vgui2_s` fatal returns, classify a client/runtime-loader
   regression and stop before Vulkan conclusions.
3. If `vgui2_s` remains absent and the post-device-use crash disappears,
   record native SteamUI/webhelper progress separately from Vulkan presentation.
4. If the crash remains unchanged, CEF-disable did not close that boundary;
   do not add software GL, `/dev/shm`, D-Bus, or sister-repo variables in the
   same run.

Do not claim OOBE, QR, or visible Steam presentation from a black X11 canvas.

## Prior-art boundary and cleanup

The sibling checkout remains pinned at
`8d14c10195b34fe2714ba59df1680df27a852532`; use its
[ARM launcher](https://github.com/huntergdavis/steamclienttermux/blob/c0ada6ea2f56a96872af2190f69f4b5385c68ee2/bin/steam-arm)
for comparison only. The upstream [Termux:X11 PRoot
contract](https://github.com/termux/termux-x11#using-with-proot-environment)
and [Termux execution-environment guidance](https://github.com/termux/termux-packages/wiki/Termux-execution-environment)
justify the later shared-temporary and app-executable investigations, not
additional R39 variables.

After evidence capture, terminate only the verified R39 Steam/PRoot and X11
processes, restore Termux properties byte-for-byte if changed, remove only
the three R39 scopes, verify port 6077 and matching processes are absent, and
verify both rooted rollback paths remain present. No broad process kill,
package-data clear, rooted-runtime deletion, or authentication-state access is
permitted.

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, authenticated Steam home, or `steam.token` contents may be read, copied,
backed up, committed, or exported.
