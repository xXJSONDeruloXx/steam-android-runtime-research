# Nova rootless R13b — closure idempotence result — 2026-08-11

Run ID: `nova-rootless-r13b-closure-idempotence-20260811T093615Z`
Sub-run: `R13b-rootless-guest-closure-symlink-aware-replay`
Status: package closure and symlink-aware idempotence replay passed; the exact
run was cleaned.

## Result

R13b repeated the R13 package transaction with the `-e || -L` marker fix and
then invoked the same helper a second time. The initial candidate passed:

```text
source_rootfs=files/r13b/guest-rootfs
holo_manifest=files/launcher/nova-rootless-steamui-holo-packages.tsv
external_manifest=files/launcher/nova-rootless-steamui-external-assets.tsv
gtk2_source=debian-bookworm
rooted_runtime_modified=0
steamui_patch=0
gtk2_and_ui_audio_closure=pass
package_count=163
pacman_local_count=301
```

The replay then returned exactly:

```text
nova_rootless_guest_rootfs=already-staged rootfs=files/r13b/guest-rootfs-closure
```

It did not create a new staging directory or repeat the package transaction.
The valid absolute GTK2 symlinks are now accepted by the existing-destination
gate. This closes the idempotent app-owned Holo package-closure stage.

No Steam process, SteamUI, Proton, network, input, audio, or authentication
claim is made by this run.

## Gate evidence

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33,
  `arm64-v8a`.
- Predeclaration: `429-nova-rootless-r13b-closure-idempotence-
  predeclaration`.
- Code under test: commit `cd1cc7a` (`fix: accept symlinked rootless closure
  markers`); predeclaration commit `31b97fe`.
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
- Steam client input: 51 files, approximately 330120 KiB; the R13 key hashes
  were unchanged.
- PRoot SHA-256:
  `6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a`.
- PRoot loader SHA-256:
  `44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04`.
- Fresh app-UID Termux:X11 transport passed on `127.0.0.1:6077`.
- The rooted rollback image was not used or modified. No Steam authentication
  data was read, copied, exported, or backed up.

## Exact cleanup verification

Only these R13b run scopes were removed:

```text
/data/local/tmp/nova-rootless-r13b-closure-idempotence-20260811T093615Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r13b/
/data/data/com.termux/files/home/.nova-rootless/
```

The static APK launcher assets were retained. After cleanup:

```text
no matching Gamescope/PRoot/Steam/SteamUI/Termux:X11 process
no :77 listener
remote_r13b=absent
app_r13b=absent
termux_rootless=absent
rollback_rootfs=present
active_marker=present
free_space=86121576 KiB
```

## Decision and next boundary

The app-owned rootless runtime can now be extracted, populated, activated,
and replayed idempotently without touching the rooted rollback. Predeclare the
next separate experiment for supervisor preflight against the activated
closure, keeping the package inputs and display transport fixed. Do not start
Steam until that preflight and its cleanup are recorded.
