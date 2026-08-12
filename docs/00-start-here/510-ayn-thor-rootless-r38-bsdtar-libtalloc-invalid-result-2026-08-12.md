# AYN Thor rootless R38 bsdtar retry — libtalloc loader invalid result — 2026-08-12

Run identity: `thor-rootless-r38-stable-payload-replay-retry-20260812T003713Z`;
sub-run: `R38-stable-payload-replay-retry-bsdtar-extraction`.

Status: **invalid-preparation**. The pinned Holo `bsdtar` bootstrap was staged
and verified under app UID 10138, but the Android dynamic linker could not
start the app-owned PRoot binary because its required `libtalloc.so.2` soname
was not present. The retry stopped before Holo extraction, package closure,
X11, or Steam. This is not a stable-client or rootless Steam result.

## Fixed gates

The R38 stable payload and client tree remained unchanged from doc 508. The
bootstrap and PRoot checks passed:

```text
bootstrap_manifest_sha256=8d9befcdbaa1cb4aa918677d021f0cfe63185accc1f85d5c9e59a7ea8008dab6
usr/bin/bsdtar_sha256=0cf2ec3c3ec5c23c59eb7b755fb6ca2e0393aa82f75aba6959cffeb32086d7d6
proot_sha256=6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a
proot_loader_sha256=44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04
serial=d234a848
app_uid=10138
app_selinux=u:r:runas_app:s0:c138,c256,c512,c768
```

## Failure boundary

The app-owned PRoot library directory contained the pinned
`libtalloc.so.2.4.3`, but no loader-visible `libtalloc.so.2` link. The exact
read-only startup probe reported:

```text
CANNOT LINK EXECUTABLE "/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r38/input/proot/proot": library "libtalloc.so.2" not found: needed by main executable
```

The archive helper consequently reported:

```text
nova_rootless_rootfs_archive=extract archive=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r38/input/system.rootfs.zst stage=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r38/.rootfs-base.archive-staging.12380
nova_rootless_rootfs_archive=fail reason=proot_bsdtar_extract
```

Fresh evidence remains outside the repository:

```text
/tmp/thor-rootless-r38-stable-payload-replay-20260812T001312Z-evidence/proot-libtalloc-failure.log
sha256=e6308dfbf0e04a946e191341f2a0fbef7b892b6fd38d26815d0ecc1b6b3885c0
/tmp/thor-rootless-r38-stable-payload-replay-20260812T001312Z-evidence/rootfs-extract-retry.log
sha256=906c49f47c86e5eaca1b8f3815825ffc05fe019139a056f8955a60fe917c22f2
/tmp/thor-rootless-r38-stable-payload-replay-20260812T001312Z-evidence/bootstrap-hashes.txt
sha256=9c16b8d1cf446435fa768f2fe504d160836b844b3d690d5e5153ca62c11a4d15
```

This is the same PRoot soname boundary previously isolated in the Nova
rootless R7b/R7c records. It is an infrastructure prerequisite, not evidence
that the stable Steam payload or rootless GPU access is failing.

## Cleanup and authentication boundary

Only the exact retry scopes were removed:

```text
/data/local/tmp/thor-rootless-r38-stable-payload-replay-20260812T001312Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r38/
```

The scopes were verified absent. No Steam, PRoot, bsdtar, webhelper, or
Termux:X11 session remained; port 6077 was absent. Both rooted rollback paths
remained present. Termux properties were not changed.

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, authenticated Steam home, or `steam.token` contents were read, copied,
backed up, committed, or exported.

## Next boundary

Doc 511 predeclares only the two app-owned compatibility links:

```text
libtalloc.so.2 -> libtalloc.so.2.4.3
libtalloc.so   -> libtalloc.so.2.4.3
```

Everything else remains fixed until the app-UID Holo extraction gate passes.
