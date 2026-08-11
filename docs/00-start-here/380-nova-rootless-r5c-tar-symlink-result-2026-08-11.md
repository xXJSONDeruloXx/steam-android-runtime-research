# Nova rootless R5c — tar symlink/listing result — 2026-08-11

Run: `nova-rootless-r5c-20260811T052537Z`
Sub-run: `R5c-tar-symlink-normalization`
Status: archive verification passed; toybox `tar -T` extraction still failed
closed before candidate activation.

## Result

R5c used the same app-private archive and package inputs as R5b and stripped
toybox’s ` -> target` display suffix before passing the non-directory list to
`tar -T`. The original directory-mode permission errors did not return, but
the device reported:

```text
tar: './usr/lib64' bad symlink
tar: './usr/lib/icu/78.1/pkgdata.inc' bad symlink
tar: './usr/lib/systemd/system/system-systemd\\x2dcryptsetup.slice' not in archive
tar: './usr/lib/systemd/system/system-systemd\\x2dveritysetup.slice' not in archive
tar: had errors
nova_rootless_rootfs_archive=fail reason=archive_extract
```

The atomic staging trap removed the partial candidate. No archive marker,
closure install, PRoot Steam launch, Termux:X11 `:78`, or Steam process was
created.

## Classification

Toybox’s human-readable listing is not a lossless archive-member API for this
image: symlink ordering/path handling and escaped member names still make a
round-trip `tar -t | filter | tar -T` unreliable. Further string-specific
normalization would be brittle and is rejected.

The archive’s size and SHA-256, app-UID access, free-space gate, and R5c
process scope passed. The rooted extracted Holo tree and rooted Steam state
were not modified; no authentication data was exported or copied.

## Scope and provenance

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch baseline: `8203769` (`docs: predeclare rootless R5c retry`).
- APK SHA-256:
  `6d0f8368107ceda4ec38bc9f94601ba1ee13e1f00b27e21637bf1bc85ddc25e4`.
- Holo archive SHA-256:
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.

## Next bounded change

Stop using toybox’s listing as the extraction manifest. Test the Holo guest’s
own `bsdtar`/libarchive through the already-verified ARM64 PRoot loader,
extracting the app-private archive into an app-private staging directory with
`--no-same-owner --no-same-permissions`. If that bootstrap path is not
available on a clean device, make the needed extractor an explicit pinned
provisioning artifact rather than adding more filename rewrites.
