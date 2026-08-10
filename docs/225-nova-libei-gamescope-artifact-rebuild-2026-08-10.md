# Nova libei-enabled Gamescope artifact rebuild — 2026-08-10

Status: predeclared; no device session has been launched under this run.

## Question

Can the checked-in Gamescope patch stack be rebuilt reproducibly with
`-Dinput_emulation=enabled`, without the build wrapper rejecting its own already
patched source on a second invocation? The previous [run 223 result](224-nova-gamescope-ahb-product-promotion-baseline-result-2026-08-10.md)
was blocked because both the host and device binaries were built with libei disabled.

This run changes only build provenance. It does not alter the Android APK or launch
the device until the new binary has a positive libei marker and a recorded SHA-256.

## Fixed build identity

- Source tree: `/Users/kurt/Developer/gamescope-valve`.
- Source commit: `fb9f84ee247a1f02b1a132da60e94585db84bf61`.
- Clean patched source directory:
  `android/nova-lab/build/gamescope-headless-libei-source-v2`.
- Build directory: `android/nova-lab/build/gamescope-headless-libei-build-v2`.
- Configure flag: `NOVA_GAMESCOPE_INPUT_EMULATION=enabled`, which maps to
  Meson `-Dinput_emulation=enabled` and links `libeis-1.0`.
- Host: ARM64 Debian trixie Docker build using the checked-in
  `android/nova-lab/build-gamescope-headless.sh`.

The wrapper now fingerprints the checked-in patch set and writes an ignored stamp in
the patched source tree. That keeps a second invocation idempotent while forcing a
new patch pass if any patch changes.

## Acceptance gates

The build is accepted only if:

1. the source clone is clean before patching and the patch stamp is fresh;
2. `ninja -C ... src/gamescope` succeeds;
3. `strings` reports the positive libei initialization marker and does not report
   `built without libei`; and
4. the binary SHA-256, source status/diff hashes, configure mode, and patch
   fingerprint are recorded before device deployment.

The subsequent device run must push this exact binary rather than reuse the rootfs
copy. A successful build alone does not prove touch, controller navigation, Steam UI,
or Android presentation.

## Planned command

```sh
GAMESCOPE_SOURCE=/Users/kurt/Developer/gamescope-valve \
GAMESCOPE_HEADLESS_SOURCE=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/gamescope-headless-libei-source-v2 \
GAMESCOPE_HEADLESS_BUILD=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/gamescope-headless-libei-build-v2 \
NOVA_GAMESCOPE_INPUT_EMULATION=enabled \
  android/nova-lab/build-gamescope-headless.sh
```
