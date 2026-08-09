# Nova AHB continuous-repaint fix — 2026-08-09

Status: behavioral hypothesis implemented and cross-compiled; device
verification is pending.

## Causal hypothesis

The clock-correlated run in [doc 70](70-nova-ahb-clock-correlated-socket-trace-result-2026-08-09.md)
showed Android waiting with an empty ACK socket while Gamescope had not yet
entered the frame's `wait_release` path. The Gamescope source explains a
possible direct cause: `steamcompmgr` calls the headless connector only when
`bShouldPaint` is true, and the normal path requires `vblank && hasRepaint`.
An unchanged Steam/X11 scene can therefore stop calling `Present()` even
though the Android AHB consumer is synchronously waiting for the next ACK.

This is a scheduling starvation hypothesis, not evidence of a lost ACK or a
SurfaceControl release-fence failure.

## Behavioral change

When `NOVA_AHB_OUTPUT_SOCKET` is enabled, the compositor now sets
`hasRepaint` on each vblank before the normal paint decision. This makes the
AHB output act like a continuously refreshed display and keeps the existing
three-buffer ACK/release ring moving across idle or low-damage UI periods.

The change deliberately leaves these parts untouched:

- original `SOCK_STREAM` transport and blocking `recvmsg()`;
- three per-buffer sockets and modulo-3 ownership mapping;
- SurfaceControl transactions and release-fence handling;
- Gamescope's per-slot release wait and acquire-fence ACK handoff.

## Validation

- The updated patch applies after the existing headless, transport, clock,
  and input patches.
- The ARM64 Gamescope build completed successfully from source commit
  `fb9f84ee247a1f02b1a132da60e94585db84bf61`.
- Built binary SHA-256:
  `94c248a2b64afe6388da87a78dd697bd685cc845c87ca851eb024b81050d4397`.
- No Nova ADB device was attached when this checkpoint was built, so the
  change is not yet accepted as a fix.

## Device acceptance gate

Repeat the guarded original stream run with this Gamescope binary and the
existing APK. The first pass condition is that the Android trace continues
past the previous frame-149 boundary while Gamescope emits corresponding
ACKs and consumes release fences. Then verify a live X11/Steam UI transition
and retain the normal provenance and teardown evidence. If the stall moves
into `wait_android_release()`, the repaint-starvation hypothesis is
disproved and the next change must address explicit per-slot ownership.
