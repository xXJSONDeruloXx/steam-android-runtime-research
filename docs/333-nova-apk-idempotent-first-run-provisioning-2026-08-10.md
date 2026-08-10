# Nova APK idempotent first-run provisioning

Date: 2026-08-10
Status: implementation staged and exercised on the rooted Retroid Pocket Nova; clean-runtime OOBE entry is proven, signed-in acceptance remains open

## Objective

Make the Nova APK own one repeatable first-run flow instead of requiring the
operator to assemble the Holo rootfs, Steam seed, SteamRT, driver, and helper
files with several independent scripts. The flow must be safe to retry and
must not turn authentication state into a backup artifact.

The product path is the direct Holo ARM64 glibc runtime through Termux:X11.
Gamescope and AHardwareBuffer remain optional experiments and are not required
to provision or start this profile.

## Authoritative inputs

The implementation is split by input type, but has one APK entry point:

| Input | Repository path |
| --- | --- |
| APK build and asset packaging | `android/nova-lab/build-one-click-apk.sh`, `android/nova-lab/build.sh` |
| Runtime pins | `android/nova-lab/provisioning/nova-runtime-manifest.tsv` |
| Exact Holo package closure | `android/nova-lab/provisioning/holo-direct-termux-x11.packages.tsv` |
| Rooted provisioner | `android/nova-lab/src/main/assets/nova-provision-runtime.sh` |
| One-click lifecycle | `android/nova-lab/src/main/assets/nova-one-click-root-launcher.sh` |
| Android progress UI | `LauncherActivity.java`, `LauncherService.java` |
| Termux:X11 Steam profile | `android/nova-lab/device/nova-termux-x11-steam-client.sh` |

The APK includes the provisioner, package installer, zstd decoder, ZIP-prefix
repair helper, driver/ICD, APK helper copies, and Proton 11 ARM64 wrapper
assets. It still requires the separately installed Termux:X11 APK because the
Android package is a controller/launcher, not a redistributable X server.

## Provisioning contract

On **Start Steam**, the foreground service runs the provisioner as root and
does not start Termux:X11 until it exits:

1. Verify root, ARM64, writable `/data/local/tmp`, free space, and free inodes.
2. Preserve `/data/local/tmp/nova-holo-rootfs` as the legacy rollback root.
3. Download into hidden versioned staging, using the manifest size/SHA-256
   gates and a `.part` file for every artifact.
4. Extract the pinned Holo rootfs, install exactly 59 packages, install Valve's
   ARM64 Steam seed, extract SteamRT3C, repair only required SONAME links, and
   validate the complete tree.
5. Install the KGSL Turnip driver/ICD and helper assets with explicit modes and
   ownership. Do not copy Steam authentication files from the legacy root.
6. Write `provisioning/complete`, validate the staged candidate, atomically
   rename it to the version directory, then replace the active marker.

Failed staging is removed by the trap before activation. A successful
activation records the previous marker in
`/data/local/tmp/nova-runtimes/previous-active-runtime`.

The APK translates the provisioner's weighted
`nova_provision_progress=<percent> phase=<phase>` lines into a determinate
progress bar and phase text. Cached/idempotent runs still show the phase until
the provisioner has finished; the launcher never races a partially staged
runtime.

## Pinned artifacts

The current manifest version is `nova-holo-direct-x11-20260810-v4`.

| Artifact | Size | SHA-256 |
| --- | ---: | --- |
| Holo `system.rootfs.zst` | 384,971,555 | `7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf` |
| Valve ARM64 seed | 109,767,888 | `b2de13c267e101679750445c9c449fbfb58dbb7c9851729e95ac69637b9df563` |
| SteamRT3C `3c.0.20260714.251839` | 52,343,604 | `f59e9541fb08f36097610f8cab07a0ed8f5f13e4a642b6fead87505aff979ab0` |
| KGSL `libvulkan_freedreno.so` | 12,364,688 | `a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810` |
| `freedreno-kgsl.icd.json` | — | `337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70` |
| 59-package closure manifest | — | `dbcf8284bac5877ff2c168bbaf55ad20d4a41910c7240cecbf70b16379aba515` |

The APK built for the latest device run was:

```text
android/nova-lab/build/nova-lab-debug.apk
sha256=869b17f5c1a87a93a529157e16c87b06ef92ae1a74c137641fee9b08049cdfd7
```

The attached Termux:X11 APK was verified as:

```text
/data/app/~~EaHbYh5LSrJyPyjYrj44Wg==/com.termux.x11-Yy3Sfe-6FUYa5hx2OcDldw==/base.apk
sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
```

## Device layout and data boundary

The latest provisioned device has:

```text
/data/local/tmp/nova-holo-rootfs
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/provisioning
/data/local/tmp/nova-active-runtime
/data/local/tmp/nova-runtimes/previous-active-runtime
```

The legacy root and versioned runtime are root-owned (`0:0`). The Steam home
parent is `1000:1000`, Steam's data root is `501:20`, the Turnip shared object
is mode `755`, and the ICD is mode `644`. The provisioner records the artifact
hashes outside the rootfs under the version directory so runtime cleanup does
not erase provenance.

The v4 device used a fresh Steam data tree and the normal QR-login path. No
Steam authentication secret was exported or backed up (`auth_secrets_exported=0`).
The generated v4 policy value
`legacy-preserved-qr-login-on-new-runtime` means that the legacy root remained
available for rollback; it does not mean that Steam data or credentials were
copied into v4.

## Device evidence

The v4 staging run completed with root/free-space checks, all pinned hashes,
ZIP prefix repair, 59-package installation, SteamRT extraction, validation,
and atomic activation. At the time of the run `/data/local/tmp` reported
approximately 57,020,876 KiB free and 13,070,572 free inodes.

The clean direct-X11 launch used the known-good display profile and reached the
real Steam language picker at `1280x960` with the host-update shim disabled.
The final English OOBE capture is retained at:

```text
android/nova-lab/build/nova-v4-no-shim-after-english.png
sha256=d6461f51d683aa5f57e6860e9341e73f39e0a659ed1b8c31b04c285ac0b42cd0
```

Some language glyphs are still rendered as squares. This is a font-coverage
issue, not evidence of a failed X11 surface or updater handoff. A prior v3
capture showed more complete glyph coverage after the Adwaita package was
added, but that runtime was contaminated by the then-present OOBE view patch
and is historical only.

The following remain intentionally unclaimed for this clean v4 acceptance:

- QR/OOBE completion and signed-in Big Picture after the new provisioning run;
- game first frame, audio device enumeration, and full controller mapping;
- Gamescope/AHardwareBuffer presentation.

Earlier historical successes must not be merged with this run's readiness.

## Cleanup and rollback

Stop a manual session with the exact active-root path and then verify both
processes and the X11 socket:

```sh
adb shell am force-stop com.xjsonderulo.steamandroid.novalab
adb shell am force-stop com.termux.x11
adb shell "su -mm 0 -c '/system/bin/sh /data/user/0/com.xjsonderulo.steamandroid.novalab/files/launcher/nova-one-click-root-launcher.sh stop /data/local/tmp/nova-active-runtime /data/local/tmp/nova-android-launcher /data/app/~~EaHbYh5LSrJyPyjYrj44Wg==/com.termux.x11-Yy3Sfe-6FUYa5hx2OcDldw==/base.apk /data/user/0/com.xjsonderulo.steamandroid.novalab/files/launcher'"
adb shell "ps -A -o PID,ARGS | grep -E 'nova|steam|Xwayland|termux.x11|uinput|libei' | grep -v grep || true"
```

Rollback is marker-based: inspect `previous-active-runtime`, replace the
active marker with the recorded previous root only after stopping all matching
processes, and leave `/data/local/tmp/nova-holo-rootfs` untouched. Do not
delete the legacy root or active version as a storage shortcut without first
choosing the rollback target and recording the resulting loss of evidence.

## Next steps

1. Keep the host-update shim disabled by default; the isolated result is in
   [the updater boundary record](334-nova-steamos-update-compat-isolation-2026-08-10.md).
2. Finish a clean v4 OOBE/login run without the removed OOBE rewrites.
3. Fix font coverage only after confirming which exact glyph package is
   missing, then rerun the same display gate.
4. Continue with official Proton/runtime and first-frame work only after the
   direct-X11 baseline is reproducible. Keep Gamescope/AHardwareBuffer out of
   the first-run critical path.
