# Nova rootless R7f — package dependency closure result — 2026-08-11

Run ID: `nova-rootless-r7f-steamui-closure-additions-20260811T062902Z`
Sub-run: `R7f-steamui-closure-additions`
Status: archive extraction passed; pacman withheld the seed-bound closure
because the two added Holo packages require additional package artifacts.

## Result

The rebuilt R7f inputs were staged and verified:

```text
rootfs_archive=384971555
rootfs_archive_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
holo_package_count=105
steamui_holo_manifest_sha256=cde330b4c2af6425828378ca24a3df8844fb22d40ab05a76cc359763c8e5294c
sdl3_sha256=575ba9be1c53fb7551fe559bd259323d1b3cc27f2ed231114a4fa66e1ed10ad4
ffmpeg_sha256=9be2ecaa588c389bf3847d4275d3f7435f6365a9b23b8aed32276717e871c615
```

The unchanged archive extractor passed atomically:

```text
nova_rootless_rootfs_archive=pass rootfs=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/rootless-r7f-steamui-closure-additions-20260811T062902Z/guest-rootfs
```

The unchanged guest closure then rejected the pacman transaction. `sdl3`
needs `hidapi`; `ffmpeg` needs a broad multimedia dependency set including
`aom`, `glslang`, `gsm`, `libass`, `libavc1394`, `libbluray`, `libbs2b`,
`libdvdnav`, `libdvdread`, `libiec61883`, `libmodplug`, `libopenmpt`,
`libplacebo`, `libraw1394`, `libsoxr`, `libssh`, `libtheora`, `libva`,
`libvdpau`, `libvpx`, `libxv`, `ocl-icd`, `opencore-amr`, `openjpeg2`,
`rav1e`, `rubberband`, `sdl2`, `snappy`, `speex`, `srt`, `svt-av1`,
`v4l-utils`, `vapoursynth`, `vid.stab`, `vmaf`, `x264`, `x265`, `xvidcore`,
`zeromq`, `zimg`, and additional SONAME providers. The transaction ended
with:

```text
error: failed to prepare transaction (could not satisfy dependencies)
nova_rootless_guest_rootfs=fail reason=guest_install
```

No `guest-rootfs-closure/` candidate was activated. No Steam executable,
supervisor, Termux:X11, display, network, audio, controller, login, or game
path was started. The rooted runtime was not modified.

## Classification

This is a package-manager closure boundary. The two missing direct soname
providers were correctly identified, but adding only their package files is
not a valid installable closure. The Holo package cache already contains the
needed dependency artifacts, so the next run may expand the manifest only
from that pinned cache and must retain per-file hashes. Do not use
`--nodeps`, skip pacman dependencies, or patch SteamUI.

## Scope and provenance

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `771b2ef` (`fix: complete rootless SteamUI dependency closure`).
- Rebuilt APK SHA-256:
  `b2c86d1155126084a8b090954f81b31740565a1b7fd3f87db07f4cd9b223ffa6`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Attempted Holo manifest: 105 entries, SHA-256
  `cde330b4c2af6425828378ca24a3df8844fb22d40ab05a76cc359763c8e5294c`.
- Added packages: `sdl3-3.2.26-1-aarch64` and `ffmpeg-2:8.0-3-aarch64`.

No Steam authentication data was exported, copied, or staged.

## Cleanup and next boundary

Remove only the exact R7f app-private and remote trees after this result is
pushed. The next predeclared run must either derive the complete installable
Holo dependency closure from the pinned package cache or explicitly stop at
this boundary. It must not broaden the set by guesswork.

Rooted rollback paths remain outside scope:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```
