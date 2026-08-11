# Nova rootless R12e — `/usr/lib` bootstrap layout result — 2026-08-11

Run ID: `nova-rootless-r12e-usr-lib-layout-20260811T091511Z`
Sub-run: `R12e-rootless-apk-materialized-usr-lib-bootstrap`
Status: archive extraction passed; the exact run was cleaned.

## Result

R12e passed the app-owned Holo archive extraction boundary after moving the
regular bootstrap libraries into `/usr/lib` while retaining the interpreter
at `/lib/ld-linux-aarch64.so.1`:

```text
archive=files/r12e/system.rootfs.zst
archive_size=384971555
archive_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
rooted_runtime_modified=0
rootless_archive_extract=1
```

The destination contained the archive marker, `usr/bin/sh`, `usr/bin/pacman`,
`usr/lib/ld-linux-aarch64.so.1`, and `var/lib/pacman/local`. The extracted
guest rootfs contained 37,705 regular files. This closes the bootstrap archive
layout failure identified by R12c/R12d. It does not yet prove guest package
installation, Steam startup, SteamUI, Proton, network, input, audio, or
authentication.

One packaging hygiene issue was visible during the gate. Because the APK was
installed over prior diagnostic versions and `prepareLauncherAssets()` copies
additively, the retained static
`files/launcher/nova-bsdtar-bootstrap/` cache contained 34 regular files:
the new 18-file payload plus manifest and the 15 obsolete regular-library
paths from the old `/lib` layout. The required new `/usr/lib` files were
present and hash-correct, and the stale files did not affect extraction, but a
fresh-install/idempotence path should prune or replace this versioned asset
subtree before claiming a clean package state.

## Gate evidence

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Predeclaration: `423-nova-rootless-r12e-usr-lib-layout-predeclaration`.
- Code under test: commit `3a3e251` (`fix: stage rootless bootstrap libraries
  in usr lib`); predeclaration commit `c8215fb`.
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `f02c9eb4ebe2bd0213939732e4b1af7d89ef482d981511d5c9aaabfd563641b6`.
- Generated bootstrap manifest: 18 payload entries, SHA-256
  `8d9befcdbaa1cb4aa918677d021f0cfe63185accc1f85d5c9e59a7ea8008dab6`.
- App-owned `/usr/bin/env` SHA-256:
  `3c093be867d02571a468c5108607b74592b3f2417597971c79845723d103b222`.
- App-owned `/usr/lib/libc.so.6` SHA-256:
  `ed2e29411d8f82e2860458d0e1f281333a98509f5d47234c9cb5d6e3f925a18e`.
- App-owned `/usr/lib/libarchive.so.13` SHA-256:
  `7dbc40ba18eec470195458940fb277144487fcd90f035d3e8007023b78561079`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.
- Fresh app-UID Termux:X11 transport passed on `127.0.0.1:6077`.
- No Steam command or Steam authentication data was touched. The rooted
  rollback image was not used or modified.

## Exact cleanup verification

Only these R12e run scopes were removed:

```text
/data/local/tmp/nova-rootless-r12e-usr-lib-layout-20260811T091511Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r12e/
/data/data/com.termux/files/home/.nova-rootless/
```

The static APK asset cache under `files/launcher/` was retained for the
packaging observation. After cleanup:

```text
no matching Gamescope/PRoot/Steam/SteamUI/Termux:X11 process
no :77 listener
remote_r12e=absent
app_r12e=absent
termux_rootless=absent
rollback_rootfs=present
active_marker=present
free_space=86041612 KiB
```

## Decision and next boundary

Keep the `/usr/lib` bootstrap layout and advance to the next rootless gate:
make the APK asset subtree replacement/idempotence behavior explicit, then
prepare the app-owned guest-rootfs package-closure step. Do not change the
archive, PRoot inputs, display transport, or Steam data while closing the
stale asset-cache issue.
