# AYN Thor rootless exact public-beta recovery gate — result — 2026-08-11

Run identity: `thor-rootless-exact-public-beta-replay-20260811T185704Z`;
sub-run: `Thor-rootless-exact-public-beta-client-baseline`.

Status: **the exact R35 replay was not launched**. The preserved rooted Thor
runtime supplied the expected selected public-beta files and metadata, but a
freshly recreated sanitized archive did not match the historical R28 archive
hash/size gate. This is a provenance failure, not a rootless Steam result.

## Decision

Do not call the attempted artifact the exact R35 client. Do not infer
anything about rootless `vgui2_s`, Vulkan, X11, `/dev/shm`, D-Bus, or OOBE
from this gate. The next run must use the separately predeclared current-tree
equivalence fixture in [doc 489](489-ayn-thor-rootless-public-beta-equivalence-replay-predeclaration-2026-08-11.md),
or recover the original historical archive before resuming the exact gate.

This outcome narrows the root-versus-rootless comparison rather than reversing
it: the rooted comparator and rootless R28 both agree on the three native
client hashes below, while the full-tree container used by R28 is no longer
available on the host or device.

## Provenance

```text
branch=feat/rootless-steamclienttermux-profile
start_head=8b46c0f456c9eea9a99bf1936cd7db3854ad6bed
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
root_identity=uid=0(root), context=u:r:magisk:s0
getenforce=Permission denied (read-only query)
sibling=/Users/kurt/Developer/steamclienttermux
sibling_head=8d14c10195b34fe2714ba59df1680df27a852532
```

The repository and sibling checkout were clean at the start. The preserved
rooted paths were checked before and after the gate:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

No Steam process, PRoot session, Termux:X11 process, or port-6077 listener
was started by this gate.

## Source and sanitization

The source was the public client tree under the preserved rooted runtime:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs/opt/nova-steam/home/.local/share/Steam
```

The archive was generated with Holo `bsdtar 3.8.2`, invoked through its
read-only Holo loader as the tree's existing UID `501:20`. No mode or
ownership change was made to the preserved runtime. The same documented
exclusions were applied:

```text
appcache/
config/
logs/
steamapps/
userdata/
.crash
local.vdf
update_hosts_cached.vdf
ssfn*
loginusers.vdf
steam.token
user*.vdf
localconfig.vdf
sharedconfig.vdf
```

The resulting run-scoped host artifact was:

```text
path=/tmp/thor-rootless-exact-public-beta-replay-20260811T185704Z-evidence/public-beta.tar
bytes=3457525760
sha256=9a3507ce029c0aebe28ebd54ae03f79b56b1899e6ad4e530c88e9d33cbd0e7bb
tar_entries=21513
regular_files=19633
symlinks=369
directories=1511
forbidden_filename_scan=empty
excluded_top_level_scan=empty
```

The historical R28/R35 gate remains:

```text
archive_bytes=3447515136
archive_sha256=4c62a8e35144b653864c31d84e682814a82384c3746001293e019d98bde25288
sanitized_file_count=19557
```

The recreated artifact therefore fails the full-tree provenance gate by
`10010624` bytes and does not qualify as the historical archive. Matching
selected files alone is not sufficient to silently relabel it.

## What did match

The source metadata and selected native client files exactly matched the
known-good public-beta record:

```text
package/beta=ef339938036ee25c4f533210a35791d5faf9f69dcbc72cce173263005500f9e4
installed_manifest=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
installed_manifest_first_record=androidarm64/,-1;1786137466;0
steamrtarm64/steam=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
```

The pinned Holo and provider provenance remained unchanged:

```text
rootfs_bytes=384971555
rootfs_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
holo_ui_audio_closure=161 packages
libvulkan_freedreno.so_sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
freedreno-kgsl.icd.json_sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
```

## Cleanup

The exact temporary device scope was removed after the failed gate:

```text
/data/local/tmp/thor-rootless-exact-public-beta-replay-20260811T185704Z/
```

Verification returned `scope_after=absent`, no matching process or listener,
`rollback_root=present`, and `active_marker=present`. Post-cleanup device
free space was `21593292 KiB`. The selected rooted client hashes were
rechecked after cleanup and remained unchanged.

The host archive is retained only as the input for the separately named
equivalence predeclaration; it is not committed to the repository and must be
removed after that run's evidence is captured.

No Steam authentication secret, session token, cookie, QR state, or
authenticated Steam home was read, copied, backed up, committed, or exported.
