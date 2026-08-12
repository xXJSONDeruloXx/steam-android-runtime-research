# AYN Thor rootless R38 libtalloc soname retry — result — 2026-08-12

Run identity: `thor-rootless-r38-stable-payload-replay-retry2-20260812T004450Z`.
Sub-run: `R38-stable-payload-replay-retry2-libtalloc-soname`.

Status: **invalid for the declared native-client A/B; useful staging and
updater-boundary evidence captured**. The retry fixed the predeclared PRoot
`libtalloc` soname defect and reached a live Steam updater process, but the
client tree required an additional root-side ownership repair that was not in
the app-owned staging contract. After that repair Steam remained at
`Client version: 0` and never started SteamUI or `steamwebhelper`.

This result does not establish a stable-client `vgui2_s` failure, a Vulkan
failure, or an app-UID KGSL denial.

## Decision

R38 exposed two concrete rootless preparation problems before the intended
root-versus-rootless comparison boundary:

1. The streamed Steam tree did not retain executable modes. The first launch
   stopped with permission denied for the native `steam` entry point.
2. The archive preserved the source tree's `.steam` ownership (`501:root`).
   The app UID could not create Steam's global-instance state there, producing
   a `steam.token` permission message and a named-pipe assertion. The fresh
   scope was repaired with a root-side `chown`, which makes the subsequent
   launch useful diagnostically but invalid as the predeclared app-owned run.

After the repair, the official stable ARM64 client stayed alive in its X11
updater path for more than ten minutes. Fresh logs contained only:

```text
[2026-08-12 01:12:28] Startup - Steam Client launched with: '/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam' '-gamepadui' '-steamos3' '-steampal' '-steamdeck' '-no-cef-sandbox' '-skipinitialbootstrap' '-no-child-update-ui'
[2026-08-12 01:12:28] Opted in to client beta 'steamdeck_stable' via beta file
[2026-08-12 01:12:28] Client version: 0
[2026-08-12 01:12:28] Using update UI: xwin
```

No `steamwebhelper`, SteamUI log, Vulkan topology log, visible Steam frame,
or OOBE transition appeared. The correct interpretation is
`stable-updater-stalled-after-undeclared-metadata-repair`, not
`rootless-vgui2-failure`.

The next experiment is predeclared in [doc
513](513-ayn-thor-rootless-r39-public-beta-cef-disable-replay-predeclaration-2026-08-12.md): return to the current public-beta tree that already crossed
`vgui2_s` and enumerated Turnip under rootless, then add only
`-cef-disable-gpu`, the UI-specific control used by the rooted comparator and
SteamClientTermux.

## Provenance and identity

```text
branch=feat/rootless-steamclienttermux-profile
start_head=ea37230bd5a4dcc27bb8f09b61713a75a3bb0766
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
app_selinux=u:r:runas_app:s0:c138,c256,c512,c768
root_identity=uid=0(root), context=u:r:magisk:s0
root_getenforce=Permissive
sibling=/Users/kurt/Developer/steamclienttermux
sibling_head=8d14c10195b34fe2714ba59df1680df27a852532
```

The repository and sibling checkout were clean at the start. The preserved
rooted paths were present before and after the run:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

The exact R38 scopes were:

```text
/data/local/tmp/thor-rootless-r38-stable-payload-replay-20260812T001312Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r38/
/data/data/com.termux/files/home/.nova-rootless/
```

The run was on the same Thor used by the rooted comparator in [doc
486](486-ayn-thor-rooted-known-good-oobe-comparison-result-2026-08-11.md).

## Immutable inputs

The host-only official stable payload gate passed before device staging:

```text
manifest_url=https://client-update.steamstatic.com/steam_client_linuxarm64
manifest_bytes=12579
manifest_sha256=a2ad912ef6f150d373504a80c79f95210f8ed4ddbc42071593d0a120eb96ca91
stable_version=1785799196
payload=bins_linuxarm64_linuxarm64.zip.vz.11771d05f91515ca5337eeb9baf835098df71d3a_60815678
payload_bytes=60815678
payload_sha256=38dad8316435b1aea099f16c4eefb5da1fd57faa59fafe659945879ad5ae5148
decoded_zip_bytes=337453898
decoded_zip_sha256=aed451902b2239cbf8a16e1a2004e016cea803d562849a4969b01a93c9cb4821
decoded_entries=55
```

The final selected client files in the fresh R38 scope matched that stable
gate:

```text
steamrtarm64/steam=72f48fb9c3f2c19cf64f8f7bbf4c7b7af65a73571ae0eeaab05bffd1633f4126
steamrtarm64/steamui.so=25ad66cfc78590b1745301ae7b86b70db64f5be0cd142d33134796e203fc8b76
steamrtarm64/vgui2_s.so=705f45328bb03c42509d28b748b0b499938f5e0caf2db618e8c929f0c3044186
steamrtarm64/steamwebhelper=3176d90436e49f7d34524ca2686cd324e2583806ba78841852b189fbcee0b83c
```

The Holo and rootless helper gates also matched:

```text
holo_system.rootfs.zst_bytes=384971555
holo_system.rootfs.zst_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
holo_ui_audio_closure=161 packages plus 2 Debian GTK2 assets
proot_sha256=6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a
proot_loader_sha256=44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04
libtalloc.so.2.4.3_sha256=3c9b207c0a6ea2896b7523e03f55d9ab0d9e88baa115d4c32b84058ff4246fbb
bsdtar_manifest_sha256=8d9befcdbaa1cb4aa918677d021f0cfe63185accc1f85d5c9e59a7ea8008dab6
bsdtar_sha256=0cf2ec3c3ec5c23c59eb7b755fb6ca2e0393aa82f75aba6959cffeb32086d7d6
```

The two soname links from doc 511 were visible to UID 10138 and allowed the
app-owned PRoot binary to start:

```text
libtalloc.so.2 -> libtalloc.so.2.4.3
libtalloc.so -> libtalloc.so.2.4.3
```

The rootfs archive extraction and 161-package guest closure both passed. The
rootless preflight reported:

```text
nova_rootless_preflight=pass uid=10138
nova_rootless_free_kib=13671112  # first launch-era reading; varied during run
nova_rootless_proot_tmp_dir=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r38/state/proot-tmp
nova_rootless_guest_tmp_dir=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r38/state/tmp
nova_rootless_resolv_conf=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r38/state/resolv.conf
```

## Display and Android boundary evidence

Termux:X11 was started fresh as PID `19457` on `DISPLAY=127.0.0.1:77` with
TCP listener port `6077`. The app-UID X11 handshake succeeded. The server
log showed a live X connection and Android's controller inventory, including
an Xbox Wireless Controller; it also showed the existing EGL legacy-drawing
fallback messages. No Steam frame was produced.

Read-only root-side metadata showed:

```text
/dev/kgsl-3d0=crw-rw-rw- system:system u:object_r:gpu_device:s0 487,0
```

This is pathname/DAC metadata only. R38 never reached a Vulkan call, and no
app-UID KGSL ioctl or SELinux denial was attributed. The device being rooted
and permissive explains why the rooted comparator can supply additional
services; it does not prove that the rootless app UID has the same effective
GPU contract.

The five live screenshots were 1920x1080 black Termux:X11 canvases with the
Android status/key bars and cursor, not Steam frames:

```text
steam-replay-live-01.png sha256=79e9aa2bf1e51f8f501b6c028704edeca21d0b94429e4c449fac6d6da1bea2cb
steam-replay-live-02.png sha256=733914121bf2f96098ff62e3c202082df4021c3de27c89537ad8f073ca783124
steam-replay-live-03.png sha256=422ca0b34866e7a8d5ea8a4fd94ed594ff18a6179d1a5e14f7e82c3f5e772f0d
steam-replay-live-04.png sha256=30bff166cf8c89468f258eb208163da60cb1012522ae22c77203b95a45dc21d7
steam-replay-live-05.png sha256=6fe18f77a0e6e8d078e29d3408cfaebf4b10d5d8491091ff07eb31df81927459
```

## Rootless versus rooted comparison

The rooted control in doc 486 used the same Thor and the same selected
public-beta native client bytes, then reached Steam OOBE and QR sign-in. It
was deliberately a manual comparator rather than a one-variable A/B. Its
extra contracts included:

| Contract | Rootless R38 | Rooted comparator |
| --- | --- | --- |
| Native client | official stable payload; updater stalled at version 0 | public-beta client; updater completed and restarted Steam |
| File metadata | streamed modes were initially wrong; `.steam` ownership needed root repair | rooted staging owns and normalizes the tree |
| PRoot identity | app UID 10138 outside, PRoot `-0` inside | root-side private launch and Linux UID/GID setup |
| `/dev/shm` | absent by contract | fresh private tmpfs present |
| D-Bus/machine identity | absent by contract | private session/system services present |
| CEF/GL | no `-cef-disable-gpu`, no software-GL override | CEF GPU disabled and software GL controls enabled |
| devices/mounts | app-owned bindings only | root-side `/dev`/`/proc`, mounts, helpers, relays |
| result | no SteamUI/webhelper process | OOBE and QR screen |

The older valid rootless current-public-beta runs are the important control
against an overly broad conclusion: doc 490 crossed `vgui2_s`, initialized
native SteamUI, started `steamwebhelper`, and reached Turnip physical-device
enumeration under the app UID. Therefore rootless is not generally blind to
SteamUI. R38 is a stable-channel/updater and staging result.

## Sister-repo and upstream findings

The clean sibling checkout was inspected at revision
`8d14c10195b34fe2714ba59df1680df27a852532`. Its launcher uses a compound
contract: private D-Bus, `proot-distro --shared-tmp`, private Mesa/Turnip
selection, `/proc/net` route compatibility, PulseAudio TCP, software CEF,
bounded logs, and a patched PRoot. The relevant source is the
[SteamClientTermux ARM launcher](https://github.com/huntergdavis/steamclienttermux/blob/c0ada6ea2f56a96872af2190f69f4b5385c68ee2/bin/steam-arm).

That prior art is useful in three narrow ways:

- `-cef-disable-gpu` is a plausible next UI-specific variable because both
  the rooted comparator and the sister launcher use it while retaining a
  separate Turnip path for games;
- `--shared-tmp`/equivalent temporary-path mapping is a plausible later
  webhelper/PRoot variable; and
- a private session bus is a plausible later Steam service prerequisite.

It is not evidence that those variables caused R38's updater stall, and they
must not be imported as a bundle. The upstream [Termux:X11 PRoot
guidance](https://github.com/termux/termux-x11#using-with-proot-environment)
requires shared temporary storage or a matching guest-visible `TMPDIR`; the
current Nova rootless profile's short app-owned `/tmp` is an explicit
equivalent hypothesis that has not yet been isolated. The
[Termux execution-environment guidance](https://github.com/termux/termux-packages/wiki/Termux-execution-environment)
also explains why executable placement and Android app-data execution rules
must be treated as a first-class staging contract.

## Cleanup and authentication boundary

Before cleanup, the exact logs, selected hashes, process state, X11 metadata,
screenshots, and profile were captured outside the repository under:

```text
/tmp/thor-rootless-r38-stable-payload-replay-20260812T001312Z-evidence/
```

The final non-sensitive log hashes included:

```text
bootstrap_log.txt bytes=769 sha256=138e02a23e7bfdbae0580aeee73fee70b54e0c509f922a4729ec652370c48e32
updateui_child.txt bytes=180 sha256=1533a0cf0b4a627b68601ddeeb91757648c678ee626c384dda318b528559713c
rootless-supervisor-final.log bytes=4976 sha256=d265a9a8be7f502625ade22f56b0283bc0ab442373dbcd6a72ac284e880c8d26
termux-x11-77.log sha256=043efc6ffe427743f701fa6aca402982d36e1beaeab6812df13f6c232bef3b44
```

Termux properties were restored byte-for-byte:

```text
sha256=89094537f49531dc9b380a0dec3a441b2fb92577e0a4f1db505790eb8b7025b0
```

Only these exact scopes were removed:

```text
/data/local/tmp/thor-rootless-r38-stable-payload-replay-20260812T001312Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r38/
/data/data/com.termux/files/home/.nova-rootless/
```

Post-cleanup checks reported no matching Steam/PRoot/webhelper/X11 process,
no listener on 6077, and `21958732 KiB` free on the reported device
filesystem. Both rooted rollback paths remained present.

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, authenticated Steam home, or `steam.token` contents were read, copied,
backed up, committed, or exported.
