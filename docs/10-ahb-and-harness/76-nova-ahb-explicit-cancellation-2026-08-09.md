# Nova AHB bridge explicit cancellation (2026-08-09)

Status: device-validated on the Retroid Pocket Nova. The Android receiver now
has an explicit cancellation path for the blocking AHardwareBuffer bridge, and
the Activity requests cancellation when it stops. This closes the continuous
receiver teardown gap identified in [doc 75](75-nova-continuous-ahb-quiet-scene-fix-2026-08-09.md).
It does not yet prove Steam login, hardware CEF, audio, or end-user packaging.

## Question and diagnosis

The continuous receiver correctly stopped treating a quiet Gamescope scene as
a 15-second failure after doc 75, but its native worker could still remain in
`accept()` or a blocking ACK receive until the session was killed. Java
`ExecutorService.shutdownNow()` cannot interrupt a native thread blocked in a
socket syscall. That made a normal Activity teardown indistinguishable from a
transport failure and left the final report with an expected, but unexplained,
receive failure.

The first fresh manual attempt confirmed the lifecycle gap: an Android Back
request did not produce an Activity lifecycle marker, and the continuous bridge
continued past frame 243. The run was then stopped through the required cleanup
helper. The implementation was extended with an explicit Activity Back finish
hook and an `onStop()` cancellation hook; the accepted trigger below is the
device's Home/Activity-stop transition, which was delivered reliably by the
immersive fullscreen session.

## Implementation

`android/nova-lab/src/main/cpp/ahbbridge.c` now:

- creates a per-run cancellation pipe and publishes it through a mutex-protected
  JNI stop function;
- polls the cancellation pipe alongside each AHB server socket while waiting
  for the Gamescope clients to connect;
- polls the cancellation pipe alongside the client socket while waiting for an
  ACK, including continuous blocking mode;
- records the cancellation phase and emits a final
  `ahb_double_buffer_cancelled=pass` report marker; and
- unregisters and closes the pipe on every bridge exit path.

`MainActivity.java` now requests native cancellation from `onStop()` and
`onDestroy()`, logs the lifecycle transition, explicitly finishes on the
legacy Back callback, and waits up to two seconds for the worker executor to
terminate during destruction.

## Bounded regression

Run identity:

```text
ahb-only-20260809T090000Z-cancel-poll-regression
profile=ahb-only-cancel-poll-regression
frame_count=240
size=1280x960
fullscreen_presentation=1
libei=enabled
ahb_trace=1 socket_trace=1 scheduler_trace=0 ack_poll_timeout_ms=0
```

Result: `headless_gamescope_ahb=pass`. All 240 frames completed; the app
report records `ahb_double_buffer_ack_wait_mode=bounded_15s`, and the socket
trace records an `ack_wait_timed` poll for each frame. The exact post-stop
verifier passed with no residual processes, app files, traces, scheduler
property, or ACK-poll override.

```text
Gamescope SHA-256=489fbee87d7251fde6d0d6952e59f6d9d7b68bd2a55c401a33671b40f851d522
APK SHA-256=970f31559a3f12878be27fd93f2be49d7a6e98ff4e4af122b5e9a93f6fe611a4
app report SHA-256=fb4900f7f3ad1e33a4fcaac245dd1b77f966ea4605fb2105b72d2ca4011c2276
Gamescope report SHA-256=7e76ba41d19fd5e82bc02788b4ed0c25affb84be0be23e58bbe77615a4cefaf1
post-stop verifier SHA-256=6132c77cf4414f3aa5a75faa91ba0f09ad27885aad9091920eff7998f6328be8
```

The complete artifact directory is:

`android/nova-lab/build/manual-runs/ahb-only-20260809T090000Z-cancel-poll-regression/`

## Fresh Activity-stop validation

Run identity:

```text
manual-20260809T100000Z-cancel-bridge-lifecycle-v2
profile=manual-cancel-bridge-lifecycle-v2
started=2026-08-09T06:58:11Z
frame_count=-1
size=1280x960
fullscreen_presentation=1
libei=enabled
android_input=keyevent
ahb_trace=1 socket_trace=1 scheduler_trace=1 ack_poll_timeout_ms=0
software CEF=swrast/softpipe
```

The run used the same Gamescope artifact and source provenance as the bounded
regression. The deployed APK SHA-256 was
`fdd7702c4ab82ff7542e3e04fc1a0a28805ee47c269a7e32c23cf9e17f1099b5`.

After the session reached `controller_ui_manual_session=ready`, Android Home
caused the Activity to stop while the native worker was blocked waiting for an
ACK. The fresh logcat sequence was:

```text
activity_on_stop
ahb_double_buffer_cancel_request=pass errno=0
ahb_double_buffer_cancelled phase=ack_wait frame=112 buffer=1
```

The app report then recorded:

```text
ahb_double_buffer_cancelled=pass phase=ack_wait
ahb_double_buffer_frames=112 releases=111
ahb_double_buffer_cancelled=pass
ahb_double_buffer=fail
```

The final `ahb_double_buffer=fail` is expected here: the experiment
intentionally interrupted the normal frame loop, so it did not satisfy the
full-frame success predicate. The independent cancellation markers prove that
the worker exited through the requested control path rather than a 15-second
ACK timeout. The run was then stopped with the mandatory manual-session helper,
and the explicit post-stop verifier passed.

```text
metadata SHA-256=f6b3ed809196d7a7b501f1b95d354c80f35548897c36a02bcf8bbdfcc9332354
app report SHA-256=19b18c98d75dd8ac95f96626681988313fbb7491390cbb4a704f287748f597fa
Gamescope report SHA-256=be80cb25cb1657c63666b2b621b8365a8268bf8b3eac0bf615b5370203e4c888
post-stop verifier SHA-256=8646d0a12a2b4346135062b23aa58f9ce4a8fe3834b2606102c3a517acc54208
```

The complete artifact directory is:

`android/nova-lab/build/manual-runs/manual-20260809T100000Z-cancel-bridge-lifecycle-v2/`

## What this resolves

- A continuous AHB session can now be interrupted while blocked in either
  client acceptance or ACK receive without waiting for the bounded timeout.
- Activity stop requests native cancellation before the session cleanup helper
  kills the rootfs/Gamescope tree.
- Bounded acceptance mode retains its 15-second dead-host detection contract.
- The run's final failure marker is now distinguishable from cancellation by
  the explicit `cancelled=pass` evidence.
- Exact cleanup and post-stop verification passed for both the bounded and
  manual runs.

## What remains open

- The `adb shell input keyevent 4` request was not independently observed as an
  Activity Back callback in the immersive session; the accepted lifecycle
  trigger was Home/Activity stop. Verify the end-user navigation path when the
  standalone launcher is built.
- Frame identity is not yet correlated end to end between a Gamescope commit,
  an AHB buffer, an Android SurfaceControl capture, and the same-run X11 image.
- The manual OOBE path remains accepted only through the timezone boundary. The
  login screen, touchscreen acceptance through login, and gamepad navigation at
  login remain open.
- Hardware-accelerated `steamwebhelper`/CEF, Linux audio output, and the
  independently launching end-user application remain unaccepted.

## Proposed next experiments

1. Add a per-present frame/commit identity and visual checksum to the Gamescope
   ACK/report, then correlate it with Android and X11 captures before making a
   login-screen claim.
2. Repeat the OOBE boundary with one input variable at a time—touch, D-pad, and
   A-button—using the new cancellation path and the frame-correlation gate.
3. Investigate the Linux audio server/device contract and the exact Mesa
   `msm`/freedreno CEF failure independently of the accepted software baseline.
4. Package root/session ownership, lifecycle shutdown, and fullscreen Gamescope
   startup into the standalone end-user app only after the login, networking,
   sound, graphics, and input gates pass.
