# AYN Thor rootless current-tree loader-debug fixture gate — result — 2026-08-11

Run identity: `thor-rootless-current-tree-vk-loader-debug-20260811T204834Z`;
sub-run: `R32-current-tree-loader-debug`.

Status: **invalid before launch; no R32 device experiment was performed**.

## Decision

The predeclared R32 selector/debug run could not start because its pinned
current-tree staging fingerprint is no longer reproducible. The fresh
sanitized archive generated from the preserved rooted public tree was:

```text
expected_archive_bytes=3457524736
expected_archive_sha256=3b54ebe8dd92ebbe304376335d59da28ebd88b1467999d39fee1c07ec98cee9a
observed_archive_bytes=3457525760
observed_archive_sha256=9a3507ce029c0aebe28ebd54ae03f79b56b1899e6ad4e530c88e9d33cbd0e7bb
tar_entries=21513
forbidden_filename_scan=empty
```

The observed archive is the same current-tree fixture recorded by [doc
490](490-ayn-thor-rootless-public-beta-equivalence-replay-result-2026-08-11.md).
Its selected public client hashes still match the known-good values:

```text
steamrtarm64/steam=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
steamrtarm64/steamwebhelper=7a65e4f7c89dd2eeb0668f85ea0a06cf737507b7f3324407e5fc9a9a488c31d0
package/beta=ef339938036ee25c4f533210a35791d5faf9f69dcbc72cce173263005500f9e4
```

Selected-file equivalence is useful, but doc 493 explicitly requires the
current-tree fixture pinned by doc 491. Because that full staging fingerprint
does not match, this is a provenance/fixture result, not evidence about
`VK_LOADER_DEBUG`, Vulkan, KGSL, PRoot, SteamUI, or rootless OOBE.

## Scope and safety

Only host-side archive generation and read-only device inventory occurred. No
R32 app/device/helper scope, Steam process, Termux:X11 process, or port-6077
listener was created. The preserved rooted paths were not modified:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

The sanitized archive was made from the documented rooted public-tree source
with these exclusions:

```text
appcache/ config/ logs/ steamapps/ userdata/ .crash local.vdf
update_hosts_cached.vdf ssfn* loginusers.vdf steam.token user*.vdf
localconfig.vdf sharedconfig.vdf
```

The retained candidate artifact is outside the repository at:

```text
/tmp/thor-rootless-current-tree-vk-loader-debug-20260811T204834Z-evidence.bFNAxR/current-tree.tar
```

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, authenticated Steam home, or `steam.token` contents were read, copied,
backed up, committed, or exported. The next predeclared run uses the observed
current-tree hash and remains a loader-debug-only experiment.
