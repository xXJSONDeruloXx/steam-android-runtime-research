# Nova AHB ancillary-data parser fix and 240-frame result

Date: 2026-08-09

## Result

The Android AHardwareBuffer producer now completes the previously failing
frame-188 boundary. A fresh 240-frame device run passed all ACK, acquire-fence,
SurfaceControl presentation, release-fence, target-frame, and cleanup gates.

This fixes a concrete transport-parser failure. It does not close the separate
stale Android-versus-X11 presentation-state gate or prove Steam login.

## Reproducer that motivated the fix

Run `manual-20260809T062500Z-scheduler-trace-libei` used a fresh process/log
baseline with the no-global-repaint source and `NOVA_AHB_SCHEDULER_TRACE=1`.
Gamescope advanced its focus commits, entered `Present()`, and sent the ACK for
frame 188. The Android producer stopped after logging
`frame=188 buffer=2 phase=wait_ack`; Gamescope then repeatedly waited for the
release of buffer 1 and timed out. A same-run debuggerd snapshot placed the
producer thread at:

```text
pool-2-thread-1 -> libnovabridge.so -> __cmsg_nxthdr
  -> nativeRunDmaBufDoubleBufferBridge+3376
```

The old receive loops used `CMSG_NXTHDR` after an invalid control header. On
this device that could repeatedly revisit a zero/invalid trailing header instead
of returning, so a successful host `sendmsg()` did not result in the producer
advancing to the next SurfaceControl transaction.

## Implementation

`android/nova-lab/src/main/cpp/ahbbridge.c` now uses a bounded control-message
iterator that:

- checks the control-buffer bounds, minimum header size, message length, and
  alignment before advancing;
- treats a zeroed trailing control header as the end of the received ancillary
  data; and
- guarantees forward progress without calling `CMSG_NXTHDR` on an invalid
  header.

The same parser is used by the ACK receive path, socket-trace summaries and
rights counts, and the single-buffer bridge ACK path.

## Fresh device validation

Run: `ahb-only-20260809T-cmsg-parser-v2`

Profile and flags:

```text
NOVA_AHB_FRAME_COUNT=240
NOVA_AHB_WIDTH=1280
NOVA_AHB_HEIGHT=960
NOVA_FULLSCREEN_PRESENTATION=1
NOVA_AHB_TRACE=1
NOVA_AHB_SOCKET_TRACE=1
NOVA_AHB_SCHEDULER_TRACE=0
gamescope_libei_build=enabled
```

Artifact provenance from the run manifest:

```text
Gamescope: /Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/gamescope-headless-source-repaintfix-no-vblank/gamescope-headless-build-scheduler-trace-libei/src/gamescope
Gamescope SHA-256: 489fbee87d7251fde6d0d6952e59f6d9d7b68bd2a55c401a33671b40f851d522
Gamescope source: /Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/gamescope-headless-source-repaintfix-no-vblank/gamescope-headless-source-scheduler-trace
Gamescope source commit: fb9f84ee247a1f02b1a132da60e94585db84bf61
Gamescope source status SHA-256: d8554a591ad45ff80921c48b581bb32857b4e365c978e1b963002ab242c306d3
Gamescope source diff SHA-256: c8c00989cb0b913470208b17a234d290966e2f02b0018ff491c4217f847858a9
Gamescope source submodules SHA-256: ffb0e5c788894ee2a5498ccffe0fcabd659805200bc9bed025ce78e02cc0f8b0
APK: /Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/nova-lab-debug.apk
APK SHA-256: 9d3b78fc23e18483ef4bf5d5ae42049d412c223af0cf8ad5abd9a076eb7bd35b
```

The run directory is:

`android/nova-lab/build/manual-runs/ahb-only-20260809T-cmsg-parser-v2/`

The key evidence is:

- `device-gamescope-headless-ahb-app-report.txt` records ACK, present, and
  release success for frames 188 and 189, the final frame 239, and
  `ahb_double_buffer=pass`.
- `device-gamescope-headless-ahb-logcat.txt` records Android ACK receives and
  release sends for frames 188, 189, and 190 with `msg_controllen=24`, one
  aligned `SCM_RIGHTS` control message, and a received fence FD.
- `post-stop-verification.txt` records no residual runtime processes, clean app
  files, and all AHB trace properties/files reset to zero.

## Next step

Repeat the manual Steam UI run with this APK/parser and the same no-hunk
Gamescope artifact. Capture Android and X11 images immediately around one
controlled OOBE transition. If the stale divergence remains while ACK/release
traces stay continuous, move the investigation from socket transport to
SurfaceControl frame identity/lifetime and add an explicit frame marker or
commit-to-buffer correlation before attempting the login gate again.
