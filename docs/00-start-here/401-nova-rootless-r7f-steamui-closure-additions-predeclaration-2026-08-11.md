# Nova rootless R7f — SteamUI Holo closure additions predeclaration — 2026-08-11

Run ID: `nova-rootless-r7f-steamui-closure-additions-20260811T062902Z`
Sub-run: `R7f-steamui-closure-additions`
Status: predeclared; the R7e diagnostic tree was removed before launch.

## Controlled change

R7e identified exactly seven missing `steamui.so` sonames and mapped them to
two already-pinned Holo ARM64 artifacts:

```text
libSDL3.so.0       -> sdl3-3.2.26-1-aarch64.pkg.tar.zst
libavcodec.so.62   -> ffmpeg-2:8.0-3-aarch64.pkg.tar.zst
libavformat.so.62  -> ffmpeg-2:8.0-3-aarch64.pkg.tar.zst
libswresample.so.6 -> ffmpeg-2:8.0-3-aarch64.pkg.tar.zst
libavutil.so.60    -> ffmpeg-2:8.0-3-aarch64.pkg.tar.zst
libswscale.so.9    -> ffmpeg-2:8.0-3-aarch64.pkg.tar.zst
libavfilter.so.11  -> ffmpeg-2:8.0-3-aarch64.pkg.tar.zst
```

R7f changes only the rootless Holo package manifest/profile and packaged
asset copy to add those two artifacts. No SteamUI patch, loader workaround,
Debian asset, display, network, audio, input, rooted-runtime, or
authentication change is allowed.

## Device, branch, and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `dfd99d9` (`docs: record rootless R7e SteamUI ldd result`).
- APK SHA-256 before this manifest rebuild:
  `625be387f085876f2c518cd2ea5ff8bb395f9f454ecf9517115b91d50135c39c`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Existing rootless Holo closure: 103 entries, SHA-256
  `ffb4a35f5acdc3ce1a24b070fe9ecc08cde495f737ef5e73409eda4fc23a8f92`.
- Addition `sdl3`: 1820623 bytes, SHA-256
  `575ba9be1c53fb7551fe559bd259323d1b3cc27f2ed231114a4fa66e1ed10ad4`.
- Addition `ffmpeg`: 18743812 bytes, SHA-256
  `9be2ecaa588c389bf3847d4275d3f7435f6365a9b23b8aed32276717e871c615`.
- Expected new closure count: 105 entries.

## Host/source scope

```text
android/nova-lab/rootless/nova-rootless-steamui-holo-packages.tsv
android/nova-lab/rootless/nova-rootless-profile.tsv
android/nova-lab/build/apk-assets/nova-rootless-steamui-holo-packages.tsv
android/nova-lab/build/apk-assets/nova-rootless-profile.tsv
```

The two package artifacts remain outside Git in the existing Holo package
cache and will be hash-verified during staging. No Steam home or
authentication data is involved.

## Run sequence and acceptance

1. Add only the two exact Holo manifest entries and update the profile count
   and manifest hash. Run `android/nova-lab/test-rootless-profile.sh` and
   rebuild the APK/assets; record the resulting APK hash.
2. Verify the R7e app/remote cleanup, free space, app UID, and rooted rollback
   paths. Stage a new app-owned R7f scope with the same public seed, mode
   normalization, PRoot absolute paths, soname links, and 105 package files.
3. Run the unchanged archive extractor and require an atomic candidate.
4. Run the unchanged guest closure with the real public seed bound at
   `/opt/nova-steam`. Require all 105 packages, Debian GTK2/audio paths, the
   guest marker, and a clean `steamui.so` `ldd` result with no `not found`.
5. Stop at closure pass. Do not start `steam`, supervisor, Termux:X11, or
   any UI/input/audio/network session in this sub-run.
6. Document, commit, and push the result before the next supervisor boundary.

## Cleanup

After pulling bounded closure output and hashes, remove only the named R7f
app-private and remote trees. Verify no matching PRoot/pacman/bsdtar/Steam/
Termux:X11 process or staging directory remains, and confirm rooted rollback
paths are unchanged.

## Follow-up

If the truthful seed-bound closure passes, predeclare the supervisor
`steam --version` run. If it fails, classify the next exact missing provider
without speculative patching. SteamRT3C and Runtime 4/Proton 11 remain later
independent boundaries.
