# Nova rootless R5b — tar listing normalization boundary — 2026-08-11

Run: `nova-rootless-r5b-20260811T052136Z`
Sub-run: `R5b-tar-parent-normalization`
Status: the directory-mode failure was bypassed; extraction failed closed on
toybox’s symlink display form before candidate activation.

## Result

R5b reverified the same archive and package set, then extracted through the
large rootfs tree using a non-directory `tar -T` list. The earlier permission
storm did not recur. At the final validation pass, toybox reported:

```text
tar: './var/run -> ../run' not in archive
tar: './var/lock -> ../run/lock' not in archive
tar: had errors
nova_rootless_rootfs_archive=fail reason=archive_extract
```

The app-owned staging directory was removed by the failure trap. No rootfs
marker or `guest-rootfs/` activation occurred, and the closure helper, PRoot,
Termux:X11 `:78`, and Steam were not started.

## Classification

This is a tar listing round-trip boundary. Android toybox’s default `tar -t`
output annotates symlink entries with ` -> target`; that human-readable suffix
is not part of the archive member name, so feeding the raw listing back via
`-T` asks tar to extract names that do not exist. R5b therefore confirms that
excluding directory entries is viable, while showing that the list must also
normalize symlink/hardlink display suffixes.

The archive size and SHA-256, app-private source access, free-space gate, and
rootless process identity all passed. The rooted extracted image and rooted
Steam state were not used or modified.

## Scope and provenance

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch baseline: `33e05e7` (`docs: predeclare rootless R5b retry`).
- APK SHA-256:
  `3ca6536a2ee1cff57b48ff3f114ff673ccde5fdc6ba36e734c7c6a9b321f73aa`.
- Holo archive SHA-256:
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.

No authentication secret was exported, copied, or backed up.

## Next bounded change

Normalize each `tar -t` line by removing the display-only ` -> target` suffix
before filtering directory entries. Keep the same archive, file-list, and
atomic activation gates. If the normalized list passes, proceed to the Holo
package closure; do not alter the rooted source or fall back to root-assisted
copying.
