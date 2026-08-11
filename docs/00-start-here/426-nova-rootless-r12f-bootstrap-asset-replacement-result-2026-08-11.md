# Nova rootless R12f — bootstrap asset replacement result — 2026-08-11

Run ID: `nova-rootless-r12f-bootstrap-asset-replacement-20260811T092231Z`
Sub-run: `R12f-rootless-bootstrap-asset-cache-idempotence`
Status: asset replacement and archive extraction passed; the exact run was
cleaned.

## Result

R12f established idempotent replacement of the versioned bootstrap subtree.
Before the APK launch, the retained app cache contained 34 regular files: the
current `/usr/lib` closure plus 15 obsolete regular-library files from the
prior `/lib` layout. After `prepareLauncherAssets()` ran, the subtree
contained exactly 19 regular files: 18 current payload entries plus
`manifest.tsv`.

The old paths were removed and the interpreter remained at its intended path:

```text
bootstrap_file_count=19
stale_libarchive=absent
stale_libc=absent
interpreter=present
```

The unchanged R12e extraction gate also passed:

```text
archive=files/r12f/system.rootfs.zst
archive_size=384971555
archive_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
rooted_runtime_modified=0
rootless_archive_extract=1
present:usr/bin/sh
present:usr/bin/pacman
present:usr/lib/ld-linux-aarch64.so.1
present:var/lib/pacman/local
```

This closes the stale bootstrap asset-cache issue without changing the Holo
archive extraction behavior. It does not yet prove package installation,
Steam startup, SteamUI, Proton, network, input, audio, or authentication.

## Gate evidence

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Predeclaration: `425-nova-rootless-r12f-bootstrap-asset-replacement-
  predeclaration`.
- Code under test: commit `561158e` (`fix: replace stale rootless bootstrap
  assets`); predeclaration commit `aa90241`.
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `5d178365526fa7e18272ed75bcf73f463d62edd8437a646c4b7d0b78a4819313`.
- Bootstrap manifest: 18 payload entries, SHA-256
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

Only these R12f run scopes were removed:

```text
/data/local/tmp/nova-rootless-r12f-bootstrap-asset-replacement-20260811T092231Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r12f/
/data/data/com.termux/files/home/.nova-rootless/
```

The cleaned bootstrap subtree was retained as the app's current static cache;
it contained 19 regular files after teardown. After cleanup:

```text
no matching Gamescope/PRoot/Steam/SteamUI/Termux:X11 process
no :77 listener
remote_r12f=absent
app_r12f=absent
termux_rootless=absent
rollback_rootfs=present
active_marker=present
free_space=86104976 KiB
```

## Decision and next boundary

The rootless bootstrap extraction path is now a credible, repeatable gate.
Advance to the app-owned guest-rootfs preparation/package-closure boundary
using the extracted `files/r12f/guest-rootfs` contract as the next input. Keep
the R12f archive, PRoot, `/usr/lib` layout, and asset replacement behavior
unchanged while testing package preparation; do not start Steam until that
guest-rootfs gate is documented and passes.
