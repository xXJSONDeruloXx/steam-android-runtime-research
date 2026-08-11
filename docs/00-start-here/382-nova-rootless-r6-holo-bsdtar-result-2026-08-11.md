# Nova rootless R6 — Holo `bsdtar` result — 2026-08-11

Run ID: `nova-rootless-r6-20260811T053311Z`
Sub-run: `R6-holo-bsdtar-bootstrap`
Status: archive extraction passed; SteamUI closure stopped on preserved
rootfs permissions before package installation.

## Result

The verified Holo ARM64 `bsdtar` successfully extracted the app-private
archive into an atomic candidate after the staged PRoot library directory
preserved the required `libtalloc.so` and `libtalloc.so.2` symlinks. The
candidate had the expected marker, required glibc/pacman paths, app-UID
ownership, and no partial staging directory.

The next closure gate failed while copying the candidate into its second
app-private staging tree:

```text
nova_rootless_guest_rootfs=copy source=files/rootless-r6-20260811T053311Z/guest-rootfs stage=files/rootless-r6-20260811T053311Z/.guest-rootfs-closure.staging.24785
cp: files/rootless-r6-20260811T053311Z/.guest-rootfs-closure.staging.24785//./usr/lib/dbus-daemon-launch-helper: Permission denied
```

The source file had mode `---s--x---`, so the app UID could not read it. The
archive helper passed `--no-same-permissions` but also passed `-p` in `-xpf`,
which asks `bsdtar` to preserve archive permissions. That combination is not
rootless-safe for this image. No package was installed and no closure
candidate was activated.

The first setup invocation also exposed two staging details that are now
part of the R6 evidence: the atomic extractor correctly rejects a
pre-created empty destination, and PRoot needs the `libtalloc` soname
symlinks rather than only `libtalloc.so.2.4.3`. The successful extraction
also emitted warnings because `PROOT_TMP_DIR` was named but not created; the
next retry will create it before launching PRoot.

## Classification

This closes the R6 archive-engine hypothesis as partially successful. Holo
`bsdtar` is a viable lossless archive reader through app-UID PRoot, while the
current `-xpf` invocation is not a viable app-private runtime extractor.
The failure is a narrow extraction-mode issue, not evidence against the
rootless archive source or SteamUI package closure.

The rooted Holo bootstrap tree and rooted Steam state were not modified. No
Steam authentication data was exported or copied. No Steam, Termux:X11,
network, audio, controller, Proton, or game result was produced in R6.

## Scope and provenance

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `59dc8fa` (`docs: refine rootless R6 staging contract`).
- APK SHA-256:
  `2eb2b4bd0f61c293b60f3ae581dfbf31a80d1ee5416530769d2229cb6f45527f`.
- Holo archive size: `384971555` bytes.
- Holo archive SHA-256:
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- App-private extracted candidate: approximately 1.2 GiB.
- PRoot execution UID: app UID `u0_a128`; no `su`, `chroot`, or `mount` was
  used by the helper.

## Cleanup

The extractor failure trap removed its partial closure staging directory.
The R6 app-private tree and `/data/local/tmp/nova-rootless-r6-20260811T053311Z`
must be removed after this record is pushed. The rooted rollback paths remain
outside cleanup scope:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Next bounded change

Predeclare a fresh retry that changes only the Holo extraction invocation:
use `bsdtar -xf` with `--no-same-owner --no-same-permissions`, create the
named PRoot temporary directory before launch, and repeat the archive and
app-ownership gates. Do not start package installation or Steam until that
retry passes.

