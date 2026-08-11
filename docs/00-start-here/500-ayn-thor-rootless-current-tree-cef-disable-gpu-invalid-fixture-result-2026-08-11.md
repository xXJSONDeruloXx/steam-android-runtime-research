# AYN Thor rootless current-tree CEF GPU-disable diagnostic — invalid fixture result — 2026-08-11

Run identity: `thor-rootless-current-tree-cef-disable-gpu-20260811T221304Z`;
sub-run: `R34-current-tree-cef-disable-gpu`.

Status: **invalid before launch**. R34 did not start Termux:X11, PRoot, Steam,
or a Vulkan process. The predeclared `-cef-disable-gpu` A/B therefore has no
graphics, CEF, SteamUI, or rootless result.

## Decision

R34 required the exact sanitized current-tree fixture used by R33:

```text
expected_archive_bytes=3457525760
expected_archive_sha256=9a3507ce029c0aebe28ebd54ae03f79b56b1899e6ad4e530c88e9d33cbd0e7bb
```

The preserved rooted public tree was regenerated using the documented
authentication exclusions, but the resulting archive was:

```text
reconstructed_archive_bytes=3457524736
reconstructed_archive_sha256=3b54ebe8dd92ebbe304376335d59da28ebd88b1467999d39fee1c07ec98cee9a
tar_entries=21513
forbidden_filename_scan=empty
```

The selected Steam hashes may still match the known public-beta tree, but the
full archive fingerprint is a required fixture gate for this A/B. The exact
`9a3507…` archive was not available at its previously documented path; only
its checksum record remained. The stable seed was intentionally not used
because it contains excluded auth-bearing paths and is not the R33 fixture.

This is a **provenance/infrastructure invalidation**, not a negative result for
`-cef-disable-gpu`, Vulkan, Turnip, PRoot, app-UID access, SteamUI, or OOBE.
Do not infer that R34 passed or failed at any runtime boundary.

The next experiment is predeclared in [doc
501](501-ayn-thor-rootless-public-client-provenance-refresh-predeclaration-2026-08-11.md).
It refreshes only a fresh sanitized public client through the normal
credential-free updater so the exact R34 A/B can be rerun without changing two
variables at once.

## Provenance and identity

```text
branch=feat/rootless-steamclienttermux-profile
start_head=773761d42414a991746c40fa6920ead82d1777de
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
rootless_outer_uid=10138
sibling_head=8d14c10195b34fe2714ba59df1680df27a852532
```

The sibling `/Users/kurt/Developer/steamclienttermux` checkout was clean.
The preserved rooted rollback paths were verified present and were not
modified:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

R34 scopes were:

```text
/data/local/tmp/thor-rootless-current-tree-cef-disable-gpu-20260811T221304Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r34-current-tree/
/data/data/com.termux/files/home/.nova-rootless/
```

## Staged fixed inputs

The prelaunch staging inputs that did pass verification were:

```text
holo_rootfs_bytes=384971555
holo_rootfs_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
holo_ui_audio_closure=161 packages
holo_manifest_sha256=f3f46d90ab246dd799cb22d75cbb219ff3c5d8e62f1ce6f53c3847c74238d83f
external_manifest_sha256=00c06ef768b5c86f67a9e46bbd4f661b2e8e8344d81457af6986d5f9a8ee7354
libvulkan_freedreno.so_sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
freedreno-kgsl.icd.json_sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
proot_sha256=6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a
proot_loader_sha256=44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04a
libtalloc_sha256=3c9b207c0a6ea2896b7523e03f55d9ab0d9e88baa115d4c32b84058ff4246fbb
libandroid_shmem_sha256=84475798e07c8174dbbfaec70a827fdb02f19ffa69a589380c13e7507fd0e731
```

The exact R34 run was never allowed to consume these inputs as a Steam
fixture because the current-tree archive gate failed first.

## Prelaunch evidence

The R34 run scope was created only for staging. The following were true:

```text
fixture_gate=invalid_before_launch
steam_launch=not_started
termux_x11=not_started
auth_state=not_read
```

No `DISPLAY` session, port 6077 listener, PRoot process, Steam process,
webhelper, SteamUI log, screenshot, Vulkan loader trace, or KGSL test belonged
to R34. R33 evidence must not be reused as an R34 readiness result.

The non-sensitive gate record is retained at:

```text
/tmp/thor-rootless-current-tree-cef-disable-gpu-20260811T221304Z-evidence/r34-fixture-gate.txt
```

It is 715 bytes with SHA-256
`e3acb5f606da48679a5a75bd9fd34a8f62577aba8787dfc658d61782212375dd`.

## Cleanup and rollback

Cleanup removed only:

```text
/data/local/tmp/thor-rootless-current-tree-cef-disable-gpu-20260811T221304Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r34-current-tree/
```

The exact run scope and app scope are absent. No R34 Termux:X11 helper was
started. No matching Steam, PRoot, webhelper, Nova, or X11 process remained,
and port 6077 had no listener. Termux properties were unchanged and retained
their pre-run SHA-256:

```text
89094537f49531dc9b380a0dec3a441b2fb92577e0a4f1db505790eb8b7025b0
```

Post-cleanup device free space was `21931052 KiB`. The rooted rollback paths
remained present.

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, authenticated Steam home, or `steam.token` contents were read, copied,
backed up, committed, or exported.
