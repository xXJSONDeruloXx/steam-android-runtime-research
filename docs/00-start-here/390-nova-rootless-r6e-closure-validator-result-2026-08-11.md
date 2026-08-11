# Nova rootless R6e — closure validator result — 2026-08-11

Run ID: `nova-rootless-r6e-20260811T060037Z`
Sub-run: `R6e-closure-validator`
Status: app-owned Holo archive and complete package closure passed.

## Result

R6e repeated the extraction and complete 103-package closure with the guest
PATH and symlink-aware validation fixes. The archive gate passed with no PRoot
temporary-directory warning. The closure gate then completed pacman, ran the
GTK2/audio Debian extraction, and atomically activated the app-owned closure:

```text
gtk2_and_ui_audio_closure=pass
nova_rootless_guest_rootfs=pass rootfs=files/rootless-r6e-20260811T060037Z/guest-rootfs-closure
```

The durable marker recorded:

```text
gtk2_source=debian-bookworm
rooted_runtime_modified=0
steamui_patch=0
```

The complete Holo transaction processed all 103 packages. The previous
missing `ln`, `touch`, and `gtk-update-icon-cache` hook errors disappeared
after exporting the guest PATH. Systemd hooks correctly reported that the
PRoot guest is not booted and skipped their host-service actions; this is
expected for the app-owned runtime. The closure is approximately 1.7 GiB and
has app-UID ownership with no partial staging directory.

## Classification

This closes the rootless archive-plus-package provisioning boundary. The
app-owned candidate now contains the direct Termux:X11 Holo closure, the
SteamUI/audio overlay, and Debian GTK2 compatibility assets without modifying
the rooted runtime or patching SteamUI. It is ready for a separately
predeclared Steam-client seed and supervisor/display run.

No Steam client was seeded or launched in R6e. There is therefore no display,
network, audio, controller, Proton, login, or game result yet. No Steam
authentication data was exported or copied.

## Scope and provenance

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `a0fa632` (`docs: predeclare rootless R6e closure validator`).
- APK SHA-256:
  `625be387f085876f2c518cd2ea5ff8bb395f9f454ecf9517115b91d50135c39c`.
- Holo archive size: `384971555` bytes.
- Holo archive SHA-256:
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Combined Holo manifest: 103 entries, SHA-256
  `ffb4a35f5acdc3ce1a24b070fe9ecc08cde495f737ef5e73409eda4fc23a8f92`.
- Closure candidate size: approximately 1.7 GiB.
- Execution UID: app UID `u0_a128`; no `su`, `chroot`, or `mount` was used.

## Cleanup

The R6e app-private and remote trees must be removed after this result is
pushed. Verify no PRoot/pacman/bsdtar process or staging directory remains.
Rooted rollback paths remain outside scope:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Next bounded change

Predeclare a fresh client-seeding run that keeps this known-good closure and
changes only the Steam ARM64 seed/client input. Require the pinned seed hash,
app-owned client tree, supervisor preflight, and a fresh guest process/log
baseline before attempting Termux:X11 or Steam UI.

