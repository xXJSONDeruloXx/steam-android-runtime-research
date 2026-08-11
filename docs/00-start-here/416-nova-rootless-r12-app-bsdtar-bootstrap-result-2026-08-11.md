# Nova rootless R12 — app-owned `bsdtar` bootstrap result — 2026-08-11

Run ID: `nova-rootless-r12-app-bsdtar-bootstrap-20260811T084551Z`
Sub-run: `R12-rootless-apk-materialized-bsdtar-archive-extraction`
Status: the bootstrap asset gate passed, but the APK did not materialize the
declared rootless extraction helper; no archive extraction was attempted.
The exact run was cleaned completely.

## Result

The new APK was installed and its rootless X11 startup path successfully
materialized the complete 17-file app-owned `bsdtar` bootstrap. The manifest
and binary hashes matched the build inputs:

```text
bootstrap_manifest_sha256=704b488c54d41c02744f5e81e44fcf90b7142b6a7ffdab007014e24487df09fa
bsdtar_sha256=0cf2ec3c3ec5c23c59eb7b755fb6ca2e0393aa82f75aba6959cffeb32086d7d6
bootstrap_files=17
bootstrap_size=68498 KiB
```

The fresh APK also started Termux-owned X11 `:77`, and the app-UID TCP probe
passed. However, `prepareLauncherAssets()` only copied the rooted/device
launcher asset list; it did not copy the rootless extraction helper that is
also bundled in the APK asset table. The declared product path therefore
failed before reading the Holo archive:

```text
sh: files/launcher/nova-rootless-extract-rootfs.sh: inaccessible or not found
exit_status=127
```

This is an APK packaging/lifecycle gap, not evidence against the new `bsdtar`
bootstrap or against Holo archive extraction. No Steam process, updater,
Steam data, authentication state, Proton, or compositor path was touched.

## Gate evidence

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Run code state: commit `de7e9b3` (`docs: predeclare rootless R12 archive
  bootstrap test`).
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `dcee573d6781fe36107356b6f61346a4df10e1cd805502d3cc45d9aa2c3cc960`.
- Holo archive staged and verified in the fresh app scope: 384971555 bytes,
  SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.
- Fresh X11 transport: `127.0.0.1:6077`, app UID `10128`, loopback probe
  passed.
- The preserved rooted rollback image was not used as a bootstrap and was not
  modified.
- No Steam authentication data was read, copied, exported, or backed up.

## Exact cleanup verification

Only these R12 run scopes were removed:

```text
/data/local/tmp/nova-rootless-r12-app-bsdtar-bootstrap-20260811T084551Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r12/
/data/data/com.termux/files/home/.nova-rootless/
```

The static APK materialization under
`/data/user/0/com.xjsonderulo.steamandroid.novalab/files/launcher/` was retained
for inspection because it is product asset state, not R12 runtime state. After
cleanup:

```text
no matching Gamescope/PRoot/Steam/SteamUI/Termux:X11 process
no :77 listener
remote_scope=absent
app_scope=absent
termux_scope=absent
rollback_rootfs=present
active_marker=present
free_space=85986272 KiB
```

## Decision and next boundary

The bootstrap generation and APK copy implementation are valid. The next
small fix is to include the rootless extraction/supervisor/profile helpers (and
their required `nova-zstd` artifact) in the launcher asset materialization
list. Then predeclare R12b with the same archive, PRoot, X11, and bootstrap
inputs, changing only the helper-asset list; do not add Steam or networking
variables until app-owned extraction passes.
