# Nova rootless R12b — helper asset retry result — 2026-08-11

Run ID: `nova-rootless-r12b-helper-assets-20260811T085212Z`
Sub-run: `R12b-rootless-apk-materialized-bsdtar-and-extractor`
Status: helper materialization passed for the declared scripts and most
bootstrap files, but the app-owned bootstrap was missing `libc.so.6`; dynamic
`bsdtar` startup failed before archive extraction. The exact run was cleaned.

## Result

R12b fixed the R12 packaging failure: the APK materialized the rootless
extractor, supervisor, profile, manifests, and `nova-zstd`. The fresh app UID
could reach the APK-owned helper path, and the pinned archive/PRoot inputs were
verified. The extraction then failed at the bootstrap dynamic-loader boundary:

```text
nova_rootless_rootfs_archive=extract archive=files/r12b/system.rootfs.zst stage=files/r12b/.guest-rootfs.archive-staging.448
/usr/bin/bsdtar: error while loading shared libraries: libarchive.so.13: cannot open shared object file: No such file or directory
nova_rootless_rootfs_archive=fail reason=proot_bsdtar_extract
```

Post-run inspection of the retained APK asset cache showed the specific cause:
`libarchive.so.13` was present and hash-correct, but `libc.so.6` was absent from
the copied bootstrap library set. The bootstrap generator included libc; the
Java `REQUIRED_ASSETS` list omitted it. The failure is therefore an APK asset
list defect, not an Holo archive, PRoot, network, Steam, or Gamescope result.

No Steam process, Steam data, authentication state, Proton, network transfer,
or compositor path was touched.

## Gate evidence

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Run code state: commit `c7bdf70` (`docs: predeclare rootless R12b helper
  retry`); the APK implementation under test was `83d07dd`.
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `c90a8a2566f80076956d8c95ddbe9ae19cdf83446fb782ee072d15f0304d16a2`.
- Bootstrap manifest: 17 generated files, SHA-256
  `704b488c54d41c02744f5e81e44fcf90b7142b6a7ffdab007014e24487df09fa`.
- Present bootstrap `libarchive.so.13` SHA-256:
  `7dbc40ba18eec470195458940fb277144487fcd90f035d3e8007023b78561079`.
- Missing app-owned path: `files/launcher/nova-bsdtar-bootstrap/lib/libc.so.6`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.
- Fresh X11 transport passed on `127.0.0.1:6077`; no Steam command was run.
- The preserved rooted rollback image was not used as a bootstrap and was not
  modified.
- No Steam authentication data was read, copied, exported, or backed up.

## Exact cleanup verification

Only these R12b run scopes were removed:

```text
/data/local/tmp/nova-rootless-r12b-helper-assets-20260811T085212Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r12b/
/data/data/com.termux/files/home/.nova-rootless/
```

The static APK asset cache under `files/launcher/` was retained for inspection.
After cleanup:

```text
no matching Gamescope/PRoot/Steam/SteamUI/Termux:X11 process
no :77 listener
remote_scope=absent
app_scope=absent
termux_scope=absent
rollback_rootfs=present
active_marker=present
free_space=86010516 KiB
```

## Decision and next boundary

Add the missing `nova-bsdtar-bootstrap/lib/libc.so.6` entry to the APK asset
list, rebuild/hash the APK, and predeclare R12c with no other change. Do not
alter the bootstrap generator or archive helper until the complete 17-file
closure is actually present and the same extraction command passes.
