# Nova rootless R6d — complete Holo closure result — 2026-08-11

Run ID: `nova-rootless-r6d-20260811T055439Z`
Sub-run: `R6d-complete-holo-closure`
Status: complete 103-package pacman transaction reached; closure validation
stopped on guest-environment and symlink-validation issues.

## Result

R6d extracted the archive with the known-good Holo `bsdtar`/PRoot path and
passed the app-readability gate. The first closure invocation stopped on a
staging omission—the two declared Debian GTK2 `.deb` assets were not copied
alongside the 103 Holo archives. Adding those exact two files and rerunning
the unchanged closure gate reached pacman.

Pacman resolved and processed all 103 Holo packages without dependency
resolution failure:

```text
Packages (103) ...
:: Processing package changes...
installing adwaita-fonts...
...
installing xorg-xwayland...
```

The closure helper then returned failure during its post-install validation:

```text
/usr/share/libalpm/scripts/systemd-hook: line 60: touch: command not found
/usr/share/libalpm/scripts/40-fontconfig-config: line 6: ln: command not found
/usr/share/libalpm/scripts/gtk-update-icon-cache: line 5: gtk-update-icon-cache: command not found
nova_rootless_guest_rootfs=fail reason=missing_file:.../.guest-rootfs-closure.staging.26649/usr/lib/libgtk-x11-2.0.so.0
```

The helper launched the guest shell without the supervisor's guest PATH, so
package hooks could not find ordinary `/usr/bin` utilities. The Debian
package extraction itself ran inside PRoot, and the guest-side checks accepted
the GTK2 library symlinks; the subsequent host-side `test -f` checks rejected
those absolute symlinks because they resolve under the PRoot guest root, not
the Android host filesystem. The atomic closure trap removed the partial
candidate.

## Classification

The complete 103-package Holo input is now dependency-complete enough for the
guest pacman transaction. This closes the R6c “missing package set” boundary.
The remaining failure is helper correctness: export the guest PATH for
package hooks and validate guest-absolute library symlinks from inside PRoot
or accept a symlink after the guest-side marker has proven its target.

No Steam, Termux:X11, network, audio, controller, Proton, or game result was
produced in R6d. The rooted Holo bootstrap tree and rooted Steam state were
not modified, and no authentication data was exported or copied.

## Scope and provenance

- Device: Retroid Pocket Nova, serial `675a2365`, Android API 33, arm64-v8a.
- Branch: `feat/rootless-steamclienttermux-profile`.
- Starting commit: `8b50a44` (`docs: predeclare rootless R6d complete closure`).
- APK SHA-256:
  `ba5133f7f053fa6607fffb1cc7d9bc8c126786955e8be9888e5eb70337eb04a1`.
- Holo archive size: `384971555` bytes.
- Holo archive SHA-256:
  `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`.
- Combined Holo manifest: 103 entries, SHA-256
  `ffb4a35f5acdc3ce1a24b070fe9ecc08cde495f737ef5e73409eda4fc23a8f92`.
- Execution UID: app UID `u0_a128`; no `su`, `chroot`, or `mount` was used.

## Cleanup

The R6d candidate, package staging, and remote push tree remain inside the
declared R6d scope until this result is pushed, then must be removed. Verify
no PRoot/pacman/bsdtar process or temporary stage remains. Rooted rollback
paths remain outside scope:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Next bounded change

Predeclare a fresh helper retry that changes only the package-install
environment and post-transaction validation: export
`PATH=/usr/bin:/bin:/usr/sbin:/sbin` inside the guest script, and validate the
GTK2/audio closure from within PRoot before using a symlink-aware host marker.

