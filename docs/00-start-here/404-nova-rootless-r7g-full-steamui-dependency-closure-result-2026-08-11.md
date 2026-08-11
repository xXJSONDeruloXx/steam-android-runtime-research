# Nova rootless R7g — full SteamUI dependency closure result — 2026-08-11

Run ID: `nova-rootless-r7g-full-steamui-dependency-closure-20260811T063431Z`
Sub-run: `R7g-full-steamui-dependency-closure`
Status: pass at the truthful app-owned archive, Holo package-closure, and
public SteamUI dependency boundary; Steam and the display session were not
started.

## Result

The R7g app-private staging tree accepted the pinned Holo archive and the
complete installable Holo closure. The unchanged extractor produced an atomic
guest rootfs, and the guest preparation step installed all 161 manifest
entries with pacman. The public ARM64 Steam seed was bound at
`/opt/nova-steam`; its `steamui.so` dependency check completed without a
`not found` entry.

The authoritative markers were:

```text
nova_rootless_rootfs_archive=pass rootfs=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r7g-full-steamui-dependency-closure-20260811T063431Z/guest-rootfs
nova_rootless_guest_rootfs=pass rootfs=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r7g-full-steamui-dependency-closure-20260811T063431Z/guest-rootfs-closure
source_rootfs=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r7g-full-steamui-dependency-closure-20260811T063431Z/guest-rootfs
holo_manifest=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r7g-full-steamui-dependency-closure-20260811T063431Z/scripts/nova-rootless-steamui-holo-packages.tsv
external_manifest=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r7g-full-steamui-dependency-closure-20260811T063431Z/scripts/nova-rootless-steamui-external-assets.tsv
gtk2_source=debian-bookworm
rooted_runtime_modified=0
steamui_patch=0
gtk2_and_ui_audio_closure=pass
app_du_kib=4353803
package_files=161
closure_candidate=present
```

This closes the R7f pacman boundary. R7f added only `sdl3` and `ffmpeg`,
which correctly exposed their transitive providers but did not form an
installable transaction. R7g derives the additional 56 artifacts from the
pinned Holo package metadata and base package database, retains exact hashes,
and installs them without `--nodeps`.

## Artifacts and provenance

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `019d603` (`fix: complete rootless SteamUI transitive closure`).
- Rebuilt APK artifact SHA-256:
  `1c246f292053b0e7463874ff376c4c75c5f180e61d0e767c78297481db302507`.
- The rebuilt APK was not installed during this manual closure run; its
  current rootless helper/assets were staged under the app UID from the
  build output.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Holo SteamUI manifest: 161 entries, SHA-256
  `f3f46d90ab246dd799cb22d75cbb219ff3c5d8e62f1ce6f53c3847c74238d83f`.
- Public ARM64 Steam seed: 109767361 bytes, SHA-256
  `1c1dd74e63db8d2d64445c7d6156f02e3b2719141e569b52e91b883d39592e82`.
- App-owned candidate size: `4353803 KiB` (approximately 4.15 GiB).

The rooted runtime and its rollback copies were not modified:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

No Steam authentication data was exported, copied, or staged.

## Classification

R7g is a rootless provisioning and dependency-closure pass, not a Steam
launch or rendering result. It proves that the app-owned Holo guest can be
extracted, made readable by the app UID, populated with the exact 161-package
Holo closure, and paired with the public ARM64 seed far enough for
`steamui.so`'s dependency check. It does not yet prove the Steam executable,
SteamUI process, X11 transport, network session, audio, input, login, or game
path.

The next bounded experiment is a fresh supervisor-only run using the same
closure and public seed. It will run `preflight` and then
`/opt/nova-steam/steamrtarm64/steam --version`, with no Termux:X11 or UI
session. That isolates supervisor/runtime startup before adding display
variables.

## Cleanup contract

Before the next run, remove only these R7g trees:

```text
/data/local/tmp/nova-rootless-r7g-full-steamui-dependency-closure-20260811T063431Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r7g-full-steamui-dependency-closure-20260811T063431Z/
```

Verify that no exact-scope PRoot, pacman, `bsdtar`, Steam, or Termux:X11
process remains, then confirm the rooted rollback paths above still exist.

