# Nova clean-device APK OOBE run — 2026-08-10

Status: in progress. This record covers the destructive clean-device reset,
fresh APK provisioning, and the first Steam client bootstrap. The next bounded
continuation must relaunch the already activated runtime and continue through
Steam BPM OOBE to the QR login screen.

## Scope and identity

- Device: Retroid Pocket Nova, Android 13, serial `675a2365`.
- APK: `android/nova-lab/build/nova-lab-debug.apk`, 3,361,472 bytes,
  SHA-256 `99973b7bd6516598df3de021ec414e5ab8775cf72a34494f036c3af3f7f79340`.
- Termux:X11 was preserved in place. Its installed APK SHA-256 was
  `6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705`.
- No Steam authentication data was exported, backed up, or copied off-device.

## Clean reset

The guarded scrub run `20260810T200643Z-retry` removed the Nova APK, the
previous logged-in runtime, all top-level `/data/local/tmp/nova*` artifacts,
the two explicitly identified non-prefixed project artifacts, and the exact
Nova rootfs mount views. It preserved Termux:X11 and left Android system
paths intact. The measured filesystem usage dropped from 29,532,788 KiB to
13,344,324 KiB, reclaiming 16,188,464 KiB (about 15.4 GiB).

The scrub initially stopped safely at mounted `/system` and APEX views inside
the old rootfs. The exact-scope force-detach hardening was committed and
pushed as `ef7b5bc` and `da1ff4a`; the successful scrub used the latter.

## Fresh provisioning result

The APK was installed after the scrub and started with
`run_steam_session=true`. Magisk required its post-install setup and reboot;
after reboot, the Nova package was explicitly enabled on Magisk's Superuser
page. The actual clean provisioning run then passed:

- root preflight: UID 0;
- free space: 92,426,588 KiB; free inodes: 13,483,305;
- runtime: `nova-holo-direct-x11-20260810-v4`;
- Holo rootfs: 384,971,555 bytes,
  SHA-256 `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf`;
- exact package closure: 59 packages, verified and installed;
- Steam ARM64 seed: 109,767,888 bytes,
  SHA-256 `b2de13c267e101679750445c9c449fbfb58dbb7c9851729e95ac69637b9df563`;
- Steam client manifest: SHA-256
  `b81089d01988870f565fbc9f35b8de89b7f3658c4c5555bbe850ff742e3aef6f`;
- SteamRT3C ARM64: 52,343,604 bytes,
  SHA-256 `f59e9541fb08f36097610f8cab07a0ed8f5f13e4a642b6fead87505aff979ab0`;
- atomic activation: `/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs`.

The direct profile reached `nova_launcher_ready=pass` with display `:0`,
geometry `1280x960`, hardware acceleration enabled, gamepad relay pass,
audio bridge port 29100, and the SteamOS host-update compatibility shim
disabled. The X11 preferences helper temporarily reported 1280x800 stretch;
the launcher readiness geometry remained 1280x960.

## Steam bootstrap boundary

The seeded client displayed Steam's real self-update screen and downloaded
657,758 KB. `bootstrap_log.txt` recorded download completion, extraction,
installation, cleanup, `Update complete, launching...`, and `Shutdown`.
The one-click wrapper then recorded `nova_launcher_client_exit=0`, attempted
cleanup, and exited with `nova_launcher_stop=fail status=1`. The Android APK
screen returned and showed `Nova Virtual Xbox Controller disconnected`.

This is an observed launcher lifecycle boundary, not a Steam content or
authentication failure: the client update completed, but the wrapper treated
the normal updater handoff as the end of the session before the new client
reached BPM OOBE. No OOBE page or QR code has yet been accepted in this clean
run. The next continuation should reuse the active runtime and updated Steam
data without another scrub or download, then establish a fresh process/log
baseline before relaunching.

Local ignored evidence captures and logcat are under
`android/nova-lab/build/`, including the provisioning log, update screenshots,
and the post-update screen. They contain no exported Steam credentials.
