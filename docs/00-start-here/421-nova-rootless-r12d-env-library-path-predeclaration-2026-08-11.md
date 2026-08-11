# Nova rootless R12d — explicit guest library path predeclaration — 2026-08-11

Run ID: `nova-rootless-r12d-env-library-path-20260811T090916Z`
Sub-run: `R12d-rootless-apk-materialized-env-library-path`
Status: predeclared after R12c showed that the complete generated bootstrap
was present but direct `bsdtar` startup could not resolve `libarchive.so.13`.

## Controlled change

R12d adds one bootstrap invocation change: package pinned Holo
`/usr/bin/env` and invoke it as:

```text
/usr/bin/env LD_LIBRARY_PATH=/lib:/usr/lib /usr/bin/bsdtar ...
```

The Holo archive, PRoot/loader/lib inputs, generated dependency libraries,
destination layout, app-owned state, display transport, Steam data, and all
network behavior remain unchanged. The purpose is to distinguish an absent
library from a loader search-path/layout failure. No Steam command is part of
this run.

## Device and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Code state: commit `2beb437` (`fix: set guest library path for rootless
  bootstrap`).
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `c6994eab79331e72c488b52ad3abdedd03a39e13187107caeba6e627ff310395`.
- Bootstrap manifest: 18 payload entries, SHA-256
  `4c84781a5be01d92d41ab5b002746f6cbde39586501b11775e4956f563cb9806`.
- Bootstrap `/usr/bin/env` SHA-256:
  `3c093be867d02571a468c5108607b74592b3f2417597971c79845723d103b222`.
- Bootstrap `libarchive.so.13` SHA-256:
  `7dbc40ba18eec470195458940fb277144487fcd90f035d3e8007023b78561079`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r12d-env-library-path-20260811T090916Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r12d/
/data/data/com.termux/files/home/.nova-rootless/
```

Retain the APK's static `files/launcher` asset cache for inspection. Preserve
and verify the rooted rollback paths:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Procedure and acceptance

1. Reread the lifecycle contract and verify clean R12d scopes/process/listener,
   free space, and rollback state.
2. Install/hash-verify the pinned APK. Start rootless X11 through the APK so
   `prepareLauncherAssets()` copies the 18-file bootstrap payload plus its
   manifest and rootless helpers. Verify `/usr/bin/env` and its hash, and
   require the app-UID X11 transport pass.
3. Push/copy only the pinned Holo archive and PRoot/loader/lib closure into
   fresh R12d state. Run the APK-materialized extractor with the same
   environment contract as R12c, requiring:

   ```text
   nova_rootless_rootfs_archive=pass
   rooted_runtime_modified=0
   archive marker with the pinned SHA-256
   required glibc/pacman paths
   ```

   The rooted rollback path must not appear as a bootstrap input.
4. Stop X11 through the APK, remove only the R12d runtime/Termux scopes, and
   verify no process/listener residue, rollback preservation, and free space.
   Do not launch Steam.

## Interpretation

A pass establishes that the R12c failure was a guest loader search-path
problem and advances to app-owned Holo rootfs extraction. A failure saying
`libc.so.6` is missing after `/usr/bin/env` starts would instead show that the
bootstrap libraries must be staged in the loader's default `/usr/lib` layout.
Any later failure remains an extraction-stage result; do not start Steam or
change the network/profile variables in the same run.
