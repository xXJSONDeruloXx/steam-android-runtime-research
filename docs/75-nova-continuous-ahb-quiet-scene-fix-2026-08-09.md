# Nova continuous AHB quiet-scene ACK-wait fix (2026-08-09)

Status: device-validated on the Retroid Pocket Nova. This fixes the continuous
Android receiver's false failure when Gamescope has a quiet scene. It does not
yet prove Steam login, hardware CEF, audio, or a complete Android-app lifecycle.

## Question and diagnosis

The no-global-repaint Gamescope build is intentionally event-driven: when the
scene is unchanged, the scheduler reports `has_repaint=0` and
`should_paint=0`, so there is no new `Present()` or AHardwareBuffer ACK to
consume. That behavior is distinct from a broken compositor.

The Android native bridge nevertheless applied a 15-second `SO_RCVTIMEO` to
every AHardwareBuffer client socket, including the manual-session mode selected
by `NOVA_AHB_FRAME_COUNT=-1`. The previous fresh manual runs therefore treated
a quiet scene as a dead host:

- `manual-20260809T070000Z-cmsg-ui-correlation` stopped at frame 153 after the
  no-hunk scheduler entered a no-present interval.
- `manual-20260809T071500Z-continuous-shm-ui` stopped at frame 169 after
  `recvmsg` returned with `errno=11` at the 15-second boundary, while X11
  remained live.

The ancillary-data parser repair in doc 74 is retained. Its fresh 240-frame
pass showed that the frame-188 `__cmsg_nxthdr` crash was a separate producer
bug, not the remaining manual-session boundary.

## Implementation

`android/nova-lab/src/main/cpp/ahbbridge.c` now determines continuous mode
before creating the client sockets:

- `frame_count_argument < 0` uses a zero `SO_RCVTIMEO`, which means a blocking
  ACK receive for the live session. A quiet scene is no longer a failure.
- Positive bounded runs retain the 15-second receive timeout, preserving the
  fail-fast acceptance-test contract.
- The app report records either `continuous_blocking` or `bounded_15s` as
  `ahb_double_buffer_ack_wait_mode`.
- The diagnostic `debug.nova.ahb_ack_poll_timeout_ms` override remains
  independent; the validated runs used its default value of zero.

No Gamescope global repaint trigger was reintroduced. The change is limited to
the receiver lifetime policy.

## Bounded regression

Run identity:

```text
ahb-only-20260809T073000Z-ack-wait-regression
profile=ahb-only-ack-wait-regression
frame_count=240
size=1280x960
fullscreen_presentation=1
libei=enabled
ahb_trace=1 socket_trace=1 scheduler_trace=0 ack_poll_timeout_ms=0
```

Result: `headless_gamescope_ahb=pass`. All 240 frames completed; frame 239
received a valid ACK/fence, presented, and released the previous buffer. The
app report contains `ahb_double_buffer_ack_wait_mode=bounded_15s`, and the
socket trace read back `effective_sec=15` for all three client sockets.

The exact-stack Gamescope artifact was:

```text
android/nova-lab/build/gamescope-headless-source-repaintfix-no-vblank/gamescope-headless-build-scheduler-trace-libei/src/gamescope
sha256=489fbee87d7251fde6d0d6952e59f6d9d7b68bd2a55c401a33671b40f851d522
```

The bounded run used APK SHA-256
`c1d6f4f08ba69698346770e520780f8bd36bb197c632ea707269bd639e30c`, and its
post-stop verifier passed. The complete provenance is in the run metadata:
`android/nova-lab/build/manual-runs/ahb-only-20260809T073000Z-ack-wait-regression/device-gamescope-headless-ahb-metadata.txt`.

## Fresh manual validation

Run identity:

```text
manual-20260809T074500Z-continuous-ack-wait
profile=manual-continuous-ack-wait
started=2026-08-09T06:36:05Z
frame_count=-1
size=1280x960
fullscreen_presentation=1
libei=enabled
android_input=keyevent
ahb_trace=1 socket_trace=1 scheduler_trace=1 ack_poll_timeout_ms=0
software CEF=swrast/softpipe
```

The run used the same Gamescope binary and source provenance as the bounded
regression. The deployed APK SHA-256 was
`db7c707e35c03e4ccb69646d03abdfa7d572b0db9f08d7c5c779d319de897d6f`.

The three Android socket setup records all read back `requested_sec=0` and
`effective_sec=0`. After a 25-second quiet hold, the app was still alive and
the live log contained no timeout or `ahb_double_buffer=fail`. The first
controlled Android `KEYCODE_BUTTON_A` was forwarded; the UI settled from the
language page to the timezone page, with the Android and same-run X11 captures
showing the same Steam state and Pacific Standard Time focus. Later frames
162–178 continued to receive valid ACKs/present/release results while the
manual session remained alive.

The second A event did not advance past the selected timezone. That is an
input/OOBE-semantic issue, not evidence against the receiver-lifetime fix. The
run was then stopped through the required manual-session cleanup path. Because
Gamescope is killed during teardown while the app is blocked waiting for its
next ACK, the completed app report ends with frame 179 missing its fence and
`ahb_double_buffer=fail`. This is an expected shutdown artifact for the
continuous mode; the live evidence before teardown is the valid frame 178 and
the absence of a 15-second receive timeout. Exact cleanup and the explicit
post-stop verifier both passed.

Selected artifacts:

```text
run metadata sha256    c1909bc978095c69b1347795f0619502fba0c8e185c77314673dfe4ce0532de6
app report sha256      f6192d8399defbc7aedffb379b889088a7fd8ba467367ea4545044229c9565e5
final Gamescope report c6bd420448708b4eff4168ba533492f12c0d06a06b6caac605b88e683442af3f
final logcat sha256    f3a9b3dd5751b4894434517272a4f45ce120228617b538d0bf6e7a91629fd043
post-stop verifier     b082fedb8585813f7dac0b39213ea806887adb66b046280f82110183f7b4484a
Android final PNG      87b4711a27e62471ffaaeee448f80a709dd74a3221b204e0a51a17afac08bb0d
X11 final PNG          a921e6901d6e0f4d8d388f9e56cae1e6be06b57479b1630c83fdb8a46e5151ee
```

All files are under:

`android/nova-lab/build/manual-runs/manual-20260809T074500Z-continuous-ack-wait/`

## What this resolves

- A live manual session no longer exits merely because Gamescope has not
  produced an ACK for 15 seconds.
- The bounded acceptance profile still detects a dead host within 15 seconds.
- The prior frame-153/frame-169 boundary is now separated from the ancillary
  parser crash and from Gamescope's deliberate no-repaint behavior.

## What remained open at the time of this run

- The native continuous loop still lacked an explicit cancellation API at the
  time of this run. This is resolved by [doc 76](76-nova-ahb-explicit-cancellation-2026-08-09.md),
  which adds the cancellation pipe and Activity-stop teardown validation.
- Frame identity is not yet correlated end to end between a Gamescope commit,
  an AHB buffer, an Android SurfaceControl capture, and the same-run X11 image.
  Add that observability before claiming a login screen from a stale or
  mismatched capture.
- The manual OOBE path is only accepted through the timezone page here. The
  second A-button activation, login, networking after OOBE, touchscreen
  acceptance through login, and gamepad navigation at login remain open.
- Hardware-accelerated `steamwebhelper`/CEF, Android audio output, and the
  standalone end-user launcher remain unaccepted. The current manual run still
  uses software CEF for a deterministic presentation baseline.

## Proposed next experiments

1. Commit this receiver-lifetime fix and keep the exact bounded and manual run
   artifacts as the regression pair.
2. Add a per-present frame/commit identity to the Gamescope ACK/report and
   correlate it with Android and X11 captures. Preserve the no-global-repaint
   scheduler behavior.
3. Add explicit native cancellation and socket close/unblock handling, then
   make `MainActivity.onDestroy()` wait for the bridge worker to exit cleanly.
4. Repeat the OOBE boundary with one input variable at a time—touch, D-pad,
   and A-button—and do not advance the login claim until Android and X11
   state/frame identity agree in the same run.
5. Return to audio and hardware CEF as independent seams: first establish the
   required Linux audio server/device contract, then investigate the exact
   Mesa/`msm`/freedreno GLX failure without changing the accepted software
   baseline.
6. Only after those seams pass, package the root/session ownership and
   fullscreen Gamescope startup into the standalone end-user app path.
