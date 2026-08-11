# Nova rootless R12f — bootstrap asset replacement predeclaration — 2026-08-11

Run ID: `nova-rootless-r12f-bootstrap-asset-replacement-20260811T092231Z`
Sub-run: `R12f-rootless-bootstrap-asset-cache-idempotence`
Status: predeclared after R12e passed extraction but showed obsolete `/lib`
bootstrap files retained beside the new `/usr/lib` closure.

## Controlled change

R12f changes only APK asset preparation. Before copying the current required
assets, `LauncherActivity.prepareLauncherAssets()` deletes and recreates the
exact app-owned subtree:

```text
files/launcher/nova-bsdtar-bootstrap/
```

No other app-owned files, Steam data, authentication state, rooted runtime,
Holo archive, PRoot/loader/lib inputs, extraction command, display transport,
or network behavior changes. The purpose is to make the bootstrap asset cache
idempotent across APK upgrades while preserving the R12e `/usr/lib` layout.

## Device and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Code state: commit `561158e` (`fix: replace stale rootless bootstrap
  assets`).
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `5d178365526fa7e18272ed75bcf73f463d62edd8437a646c4b7d0b78a4819313`.
- Bootstrap manifest: 18 payload entries, SHA-256
  `8d9befcdbaa1cb4aa918677d021f0cfe63185accc1f85d5c9e59a7ea8008dab6`.
- Bootstrap `/usr/bin/env` SHA-256:
  `3c093be867d02571a468c5108607b74592b3f2417597971c79845723d103b222`.
- Bootstrap `/usr/lib/libc.so.6` SHA-256:
  `ed2e29411d8f82e2860458d0e1f281333a98509f5d47234c9cb5d6e3f925a18e`.
- Bootstrap `/usr/lib/libarchive.so.13` SHA-256:
  `7dbc40ba18eec470195458940fb277144487fcd90f035d3e8007023b78561079`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r12f-bootstrap-asset-replacement-20260811T092231Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r12f/
/data/data/com.termux/files/home/.nova-rootless/
```

The exact bootstrap asset subtree is intentionally inspected and replaced by
the APK as part of this run. Preserve and verify the rooted rollback paths:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Procedure and acceptance

1. Reread the lifecycle contract and verify clean R12f runtime/Termux scopes,
   process/listener state, free space, and rollback state. Record the
   pre-install bootstrap asset count as historical context.
2. Install/hash-verify the pinned APK and start rootless X11 through the APK.
   After `prepareLauncherAssets()` runs, require exactly 19 regular files in
   `files/launcher/nova-bsdtar-bootstrap/`: 18 current payload entries plus
   `manifest.tsv`. Require the new `/usr/lib` hashes, retain the interpreter
   at `/lib/ld-linux-aarch64.so.1`, and verify that obsolete regular-library
   paths such as `lib/libarchive.so.13` are absent. Require the app-UID X11
   transport pass.
3. Push/copy only the same pinned Holo archive and PRoot/loader/lib closure
   into fresh R12f state. Run the unchanged R12e extraction gate and require
   the archive marker, required glibc/pacman paths, and
   `rooted_runtime_modified=0`.
4. Stop X11 through the APK, remove only the R12f runtime/Termux scopes, and
   verify no process/listener residue, rollback preservation, and free space.
   Do not launch Steam.

## Interpretation

A pass establishes that APK upgrades no longer retain obsolete bootstrap
layouts and that the replacement does not regress archive extraction. A count
or stale-path failure is an APK cache hygiene result; do not alter Holo,
PRoot, or archive variables in the same run.
