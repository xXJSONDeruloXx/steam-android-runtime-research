# Nova rootless R13b — closure idempotence predeclaration — 2026-08-11

Run ID: `nova-rootless-r13b-closure-idempotence-20260811T093615Z`
Sub-run: `R13b-rootless-guest-closure-symlink-aware-replay`
Status: predeclared after R13 exposed that the package closure passed but the
existing-destination shortcut rejected valid absolute GTK2 symlinks.

## Controlled change

R13b repeats the R13 archive extraction and package-closure procedure with the
same pinned inputs, using only the helper fix from `cd1cc7a`: the existing
candidate check now accepts each required GTK2 path when it is either a
resolvable file or a valid symlink (`-e || -L`). After the first pass, invoke
the same helper again against the activated destination and require:

```text
nova_rootless_guest_rootfs=already-staged rootfs=files/r13b/guest-rootfs-closure
```

No archive, package, Steam client, PRoot, display, network, or authentication
variable changes.

## Device and artifacts

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Code state: commit `cd1cc7a` (`fix: accept symlinked rootless closure
  markers`).
- APK: `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `5b27f2c6b38fb3ecebda6d4efe028b6e3086a32775874da48ea08ad8e257a682`.
- Bootstrap manifest: 18 payload entries, SHA-256
  `8d9befcdbaa1cb4aa918677d021f0cfe63185accc1f85d5c9e59a7ea8008dab6`.
- Holo archive: 384971555 bytes, SHA-256
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Holo package manifest: 161 entries, SHA-256
  `f3f46d90ab246dd799cb22d75cbb219ff3c5d8e62f1ce6f53c3847c74238d83f`.
- Debian external manifest: two entries, SHA-256
  `00c06ef768b5c86f67a9e46bbd4f661b2e8e8344d81457af6986d5f9a8ee7354`.
- Steam client input: 51 files, approximately 330120 KiB; key Steam,
  SteamUI, and SteamWebHelper hashes remain those recorded in R13.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.

## Exact mutable scope

```text
/data/local/tmp/nova-rootless-r13b-closure-idempotence-20260811T093615Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r13b/
/data/data/com.termux/files/home/.nova-rootless/
```

Preserve the rooted rollback paths and retain the static launcher asset cache.

## Procedure and acceptance

1. Reread the lifecycle contract and verify clean R13b scopes/process/listener,
   free space, 19-file bootstrap asset state, and rollback state.
2. Install/hash-verify the pinned APK, start rootless X11, and repeat the
   unchanged archive extraction and 161-plus-two package installation into
   `files/r13b/guest-rootfs-closure`.
3. Require the package marker, `gtk2_and_ui_audio_closure=pass`,
   `rooted_runtime_modified=0`, and all required symlinked library paths.
   Invoke the same helper a second time and require the `already-staged` line
   without a new staging directory or package transaction.
4. Stop X11, remove only the R13b runtime/Termux scopes, and verify exact
   cleanup, rollback preservation, and free space. Do not start Steam.

## Interpretation

A pass closes the idempotent app-owned guest-rootfs stage. A repeat failure is
a helper marker/symlink result; do not change the package closure or start
Steam in the same run. After a pass, the next experiment is supervisor
preflight against this activated closure.
