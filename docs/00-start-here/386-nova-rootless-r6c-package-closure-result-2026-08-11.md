# Nova rootless R6c — package closure result — 2026-08-11

Run ID: `nova-rootless-r6c-20260811T054707Z`
Sub-run: `R6c-owner-access-normalization`
Status: archive extraction and app-readability passed; the 44-file Holo
package closure was rejected by the guest solver.

## Result

R6c produced an app-owned, atomically activated Holo candidate. The formerly
unreadable `dbus-daemon-launch-helper` became owner-readable and executable
after the explicit staging normalization. The archive marker, required
glibc/pacman paths, artifact hashes, and no-partial-stage check passed.

The package-closure helper then copied the candidate and invoked the guest
Holo `pacman --noconfirm --needed -U` transaction. The transaction did not
install packages because the 44-file manifest is not dependency-complete
against the extracted archive:

```text
warning: database file for 'core' does not exist (use '-Sy' to download)
warning: database file for 'extra' does not exist (use '-Sy' to download)
:: The following packages cannot be upgraded due to unresolvable dependencies:
      at-spi2-core gdk-pixbuf2 glycin gsettings-desktop-schemas gtk-update-icon-cache
      libjxl libpulse librsvg libxcursor libxinerama xorg-xprop
:: unable to satisfy dependency 'libx11' required by at-spi2-core
:: unable to satisfy dependency 'cairo' required by glycin
:: unable to satisfy dependency 'adwaita-fonts' required by gsettings-desktop-schemas
:: unable to satisfy dependency 'libxcb' required by libpulse
nova_rootless_guest_rootfs=fail reason=guest_install
```

Read-only checks of the source candidate confirmed representative missing
files including `libX11.so.6`, `libXi.so.6`, `libXtst.so.6`, `libxcb.so.1`,
`libcairo.so.2`, `libfontconfig.so.1`, `libpng16.so.16`, `libharfbuzz.so.0`,
`libpango-1.0.so.0`, and the Adwaita font directory. The package helper's
trap removed the partial closure stage; no package transaction or SteamUI
marker was activated.

## Classification

The rootless archive and owner-access path are now proven through the first
package boundary. The current 44-file manifest is an incremental overlay, not
a complete package closure for the pinned `system.rootfs.zst`, despite its
comment saying the direct-X11 closure is already present. We cannot use the
rooted v4 tree to hide that gap: it is a separate rooted input and remains
rollback-only.

This result does not justify switching to `--nodeps`; missing files are real,
not merely absent pacman database records. The next rootless experiment must
stage and verify the complete direct-Termux:X11 Holo package closure, or
explicitly prove that every omitted dependency is supplied by the selected
archive. No Steam, Termux:X11, network, audio, controller, Proton, or game
result was produced in R6c, and no authentication data was exported.

## Scope and provenance

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `1a2c656` (`docs: predeclare rootless R6c owner access`).
- APK SHA-256:
  `f499d43a66492262e4002b33f8185f434e56af334024e48ee97b9cf3aa1fc9d1`.
- Holo archive size: `384971555` bytes.
- Holo archive SHA-256:
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Execution UID: app UID `u0_a128`; no `su`, `chroot`, or `mount` was used.

## Cleanup

The named R6c app-private and remote trees must be removed after this result
is pushed. Verify no PRoot/bsdtar process or temporary staging directory
remains. Rooted rollback paths stay outside scope:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Next bounded change

Predeclare a fresh package-closure experiment that changes only the package
input set. Reconcile the full direct-X11 package manifest against the pinned
archive, verify every artifact hash, and require pacman to complete before
testing the GTK2/audio closure or any Steam process.

