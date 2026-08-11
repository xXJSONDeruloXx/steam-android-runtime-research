# Nova rootless R12e — `/usr/lib` bootstrap layout predeclaration — 2026-08-11

Run ID: `nova-rootless-r12e-usr-lib-layout-20260811T091511Z`
Sub-run: `R12e-rootless-apk-materialized-usr-lib-bootstrap`
Status: predeclared after R12d showed that the explicit library path was
applied but the bootstrap loader could not start `env` with libraries staged
only in `/lib`.

## Controlled change

R12e changes only the bootstrap library layout. The interpreter remains at:

```text
/lib/ld-linux-aarch64.so.1
```

`libc.so.6` and the other regular libraries in the already verified Holo
closure are staged under:

```text
/usr/lib/
```

The existing `/usr/bin/env LD_LIBRARY_PATH=/lib:/usr/lib /usr/bin/bsdtar`
invocation remains in place. The Holo archive, PRoot/loader/lib inputs,
archive destination, app-owned state, display transport, Steam data, and
network behavior remain unchanged. No Steam command is part of this run.

## Device and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Code state: commit `3a3e251` (`fix: stage rootless bootstrap libraries in
  usr lib`).
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `f02c9eb4ebe2bd0213939732e4b1af7d89ef482d981511d5c9aaabfd563641b6`.
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
/data/local/tmp/nova-rootless-r12e-usr-lib-layout-20260811T091511Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r12e/
/data/data/com.termux/files/home/.nova-rootless/
```

Retain the APK's static `files/launcher` asset cache for inspection. Preserve
and verify the rooted rollback paths:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Procedure and acceptance

1. Reread the lifecycle contract and verify clean R12e scopes/process/listener,
   free space, and rollback state.
2. Install/hash-verify the pinned APK. Start rootless X11 through the APK so
   `prepareLauncherAssets()` copies the 18-file bootstrap payload plus its
   manifest and rootless helpers. Verify the `/usr/lib` paths and hashes, and
   require the app-UID X11 transport pass.
3. Push/copy only the pinned Holo archive and PRoot/loader/lib closure into
   fresh R12e state. Run the APK-materialized extractor with the same
   environment contract as R12c/R12d, requiring:

   ```text
   nova_rootless_rootfs_archive=pass
   rooted_runtime_modified=0
   archive marker with the pinned SHA-256
   required glibc/pacman paths
   ```

   The rooted rollback path must not appear as a bootstrap input.
4. Stop X11 through the APK, remove only the R12e runtime/Termux scopes, and
   verify no process/listener residue, rollback preservation, and free space.
   Do not launch Steam.

## Interpretation

A pass closes the app-owned archive-extraction bootstrap and permits the next
rootless guest-rootfs preparation gate. A failure at `env` or `bsdtar` remains
a loader/layout result. Do not alter the archive, PRoot, network, Steam data,
or display variables in this run.
