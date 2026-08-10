# Nova libei-enabled Gamescope artifact rebuild result — 2026-08-10

Status: build and repeatability gates passed; device deployment is the next run.

This is the result for the predeclared [run 225](225-nova-libei-gamescope-artifact-rebuild-2026-08-10.md).

## Build provenance

- Source tree: `/Users/kurt/Developer/gamescope-valve`.
- Source commit: `fb9f84ee247a1f02b1a132da60e94585db84bf61`.
- Patched source: `android/nova-lab/build/gamescope-headless-libei-source-v2`.
- Build output: `android/nova-lab/build/gamescope-headless-libei-build-v2/src/gamescope`.
- Binary SHA-256:
  `cb79e7ff366009f816b69f86c11e19c4984589a3337d633f996aff0b0319fdca`.
- Patch-set fingerprint/stamp:
  `8a1910134102887ad5a5e114adbdb11ef7735e876d3112db95ffe4cb8f15c24d`.
- Patched source diff SHA-256:
  `a42cbbdbfcf24bbd08a7bfe8689ebbc8306f3b384c0b3fe7f252d2ce88a46af9`.
- Meson mode: `-Dinput_emulation=enabled`.
- `libeis-1.0`: found, version `1.3.901`.

## Positive artifact evidence

The built binary contains the positive feature marker and no disabled-build marker:

```text
libeis.so.1
Successfully initialized libei for input emulation!
Initializing libei failed, XTEST will not be available!
```

The first line is the linked runtime dependency; the second is the positive build
path. The third is the runtime fallback string and is retained in the binary for
normal error handling; it is not evidence that this build is disabled.

## Repeatability evidence

The exact build command was run twice against the same source and output directories.
The second invocation skipped patch application through the fingerprinted stamp and
completed with:

```text
ninja: Entering directory `/out`
ninja: no work to do.
```

This closes the specific wrapper regression seen in [run 224](224-nova-gamescope-ahb-product-promotion-baseline-result-2026-08-10.md):
already-applied later patches no longer make a repeat invocation fail at an earlier
patch's context check.

## Decision

This artifact is eligible for device deployment. The next device run must pass
`NOVA_GAMESCOPE_HEADLESS` explicitly to this binary, verify the same SHA-256 after
the push, and require the positive libei marker before evaluating the 1280×960 AHB,
touch, and controller gates. The old rootfs binary remains a separate disabled-build
artifact and must not be reused for acceptance.
