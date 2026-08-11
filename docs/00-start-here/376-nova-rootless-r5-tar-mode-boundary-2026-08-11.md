# Nova rootless R5 — toybox tar mode boundary — 2026-08-11

Run: `nova-rootless-r5-20260811T051530Z`
Sub-run: `R5a-archive-extract`
Status: archive verification passed; extraction failed closed before candidate
activation.

## Result

The app UID verified the Holo archive in app-private storage:

```text
archive_size=384971555
archive_sha=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
package_count=44
deb_count=2
```

The extractor then failed inside the fresh app-owned staging directory with
Android toybox tar errors such as:

```text
tar: ./etc/ca-certificates/extracted/cadir/OISTE_Server_Root_ECC_G1.pem: Permission denied
tar: can't link './etc/ca-certificates/extracted/cadir/1ae85e5e.0' -> 'Trustwave_Global_ECC_P256_Certification_Authority.pem': Permission denied
tar: had errors
nova_rootless_rootfs_archive=fail reason=archive_extract
```

The archive staging directory was removed by the helper trap and no
`.nova-rootless-rootfs-archive` marker or `guest-rootfs/` candidate was
activated. No package installation, PRoot launch, Termux:X11 `:78` start, or
Steam process occurred.

## Classification

The failure is caused by the Android API 33 toybox tar extraction behavior on
this device: archived directory modes can make a just-created directory
non-writable before later regular-file and hardlink entries are processed.
The failure is not caused by archive corruption, free space, the rooted Holo
tree, or the package closure. The app-private archive itself remained readable
and hash-correct.

The exact command help exposed the relevant portability boundary: this build
has toybox tar with `-T` include-file support and metadata flags, but its
observed extraction still preserved a directory mode that blocked subsequent
entries. A later toybox version or a different tar implementation must not be
assumed on Nova without a fresh probe.

## Scope and provenance

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch baseline: `d4f6e2a` (`docs: predeclare rootless R5 archive run`).
- APK SHA-256:
  `a6a98a0011c0cef31befa7f09dfc987d4e9d8fd093e35a9d19279988c035fbc1`.
- Rootfs archive SHA-256:
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Rooted rollback paths were not read or modified beyond the predeclared
  presence check. No Steam authentication data was exported or copied.

## Next bounded change

Keep the archive and app-UID verifier unchanged. Adjust only extraction: list
the archive entries, pass a newline-safe-for-this-pinned-image non-directory
file list to toybox tar `-T`, and validate the required empty/runtime
directories after extraction. This lets tar create parent directories with
app-writable defaults instead of applying rootfs directory modes first. If
that remains insufficient, use a bundled extraction helper with explicit
metadata normalization; do not fall back to copying the root-owned extracted
tree.
