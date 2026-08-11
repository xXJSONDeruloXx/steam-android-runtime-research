# Nova rootless R12c — complete bootstrap closure result — 2026-08-11

Run ID: `nova-rootless-r12c-libc-bootstrap-20260811T085929Z`
Sub-run: `R12c-rootless-apk-materialized-complete-bsdtar-closure`
Status: failed at the bootstrap dynamic-loader/library-search boundary; the
run was cleaned exactly.

## Result

R12c fixed the R12b APK omission at the asset-copy level: the fresh app UID
materialized the complete generated `bsdtar` bootstrap, including
`libc.so.6`. The pinned Holo archive and PRoot inputs also passed their size
and hash checks. Extraction still failed before reading the archive:

```text
nova_rootless_rootfs_archive=extract archive=files/r12c/system.rootfs.zst stage=files/r12c/.guest-rootfs.archive-staging.1837
/usr/bin/bsdtar: error while loading shared libraries: libarchive.so.13: cannot open shared object file: No such file or directory
nova_rootless_rootfs_archive=fail reason=proot_bsdtar_extract
```

The app-owned bootstrap contained both the manifest and the file named in the
loader error. Therefore this is no longer evidence that `libc.so.6` was
omitted from the APK. It is a bootstrap runtime layout or guest-library-search
boundary: the raw PRoot command enters the app-owned root, but invoking
`/usr/bin/bsdtar` directly does not cause the loader to search the staged
`/lib` directory for `libarchive.so.13`. No Holo archive contents were
extracted, and no Steam, network, Proton, display, or authentication path was
touched.

## Gate evidence

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Predeclaration: `419-nova-rootless-r12c-libc-bootstrap-predeclaration`.
- Code under test: commit `71718b7` (`fix: include libc in rootless bootstrap
  assets`); the pushed predeclaration was `04e2fee`.
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `b5bc9a9f4a8b2fd4e4ce1bc4c16f8f07bc696660ae057b30ac30404bd5b009d6`.
- Generated bootstrap manifest: 17 payload entries, SHA-256
  `704b488c54d41c02744f5e81e44fcf90b7142b6a7ffdab007014e24487df09fa`.
- App-owned `libarchive.so.13` SHA-256:
  `7dbc40ba18eec470195458940fb277144487fcd90f035d3e8007023b78561079`.
- App-owned `libc.so.6` SHA-256:
  `ed2e29411d8f82e2860458d0e1f281333a98509f5d47234c9cb5d6e3f925a18e`.
- App-owned extractor SHA-256:
  `06a2020d9c89e1aaca3cab63fbf149012cdfb41013c4cf049bc650ba1a00a445`.
- App-owned `nova-zstd` SHA-256:
  `a9a743377cbf0580f4ed02dc363e77a1cd275987283c1bc655e1ab17ca6629a4`.
- The APK asset cache contained 18 regular files: the 17 manifest payload
  entries plus `manifest.tsv`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.
- Fresh app-UID Termux:X11 transport passed on `127.0.0.1:6077`.
- The rooted rollback image was not used or modified. No Steam
  authentication data was read, copied, exported, or backed up.

## Exact cleanup verification

Only these R12c run scopes were removed:

```text
/data/local/tmp/nova-rootless-r12c-libc-bootstrap-20260811T085929Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r12c/
/data/data/com.termux/files/home/.nova-rootless/
```

The static APK asset cache under `files/launcher/` was retained for inspection.
After cleanup:

```text
no matching Gamescope/PRoot/Steam/SteamUI/Termux:X11 process
no :77 listener
remote_r12c=absent
app_r12c=absent
termux_rootless=absent
rollback_rootfs=present
active_marker=present
free_space=86122960 KiB
```

## Decision and next boundary

The complete-closure hypothesis is disproved as a sufficient fix. Keep the
archive, PRoot, and generated library payload unchanged for the next
experiment. Add one explicit guest-side library-path mechanism to the
bootstrap invocation—preferably a pinned Holo `/usr/bin/env` with
`LD_LIBRARY_PATH=/lib:/usr/lib`—and predeclare that as R12d. If that reaches
`bsdtar`, continue the extraction gate; if it reports a missing `libc.so.6`,
the next result will establish that the loader also requires the libraries in
`/usr/lib` rather than only `/lib`.
