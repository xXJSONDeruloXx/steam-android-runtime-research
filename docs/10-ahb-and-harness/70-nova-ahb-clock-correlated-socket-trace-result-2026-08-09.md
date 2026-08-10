# Nova clock-correlated AHB socket trace result — 2026-08-09

Status: valid bounded device result; the clock fields correlate the Android
and Gamescope processes, and the guarded teardown passed.

This is the result of the diagnostic-only experiment declared in
[`docs/10-ahb-and-harness/69-nova-ahb-clock-correlated-socket-trace-experiment-2026-08-09.md`](69-nova-ahb-clock-correlated-socket-trace-experiment-2026-08-09.md).
It incorporates the attached Gamescope → Android AHardwareBuffer handshake
research through the synthesis in
[`docs/10-ahb-and-harness/63-nova-ahb-handshake-deadlock-research-synthesis-2026-08-09.md`](63-nova-ahb-handshake-deadlock-research-synthesis-2026-08-09.md).

## Run identity and provenance

- Run: `manual-20260809T022100Z-clocktrace`
- Profile: `manual-stream-clock-correlation`
- Started: `2026-08-09T02:18:28Z`
- Android PID: `6220`; AHB thread TID: `6580`
- Gamescope PID: `6602`; AHB thread TID: `6611`
- Presentation: fullscreen `1280x960`, GPU composition disabled, original
  `SOCK_STREAM` transport, three AHardwareBuffers, libei-enabled Gamescope,
  Android keyevent input bridge
- ACK receive mode: blocking `recvmsg(MSG_CMSG_CLOEXEC)` with
  `NOVA_AHB_ACK_POLL_TIMEOUT_MS=0`
- Trace flags: `NOVA_AHB_TRACE=1`, `NOVA_AHB_SOCKET_TRACE=1`
- Gamescope binary SHA-256:
  `fd86ba1d81f502d7ef05b17ef150193926e91008538185cccfe9473557aa7325`
- APK SHA-256:
  `bf7859a1e49388fbf86b44cdf36960b2b5b2c3140d2fb471a4937a682c313299`
- Gamescope source commit:
  `fb9f84ee247a1f02b1a132da60e94585db84bf61`
- Gamescope source status SHA-256:
  `e2ee88158467e2b5255510f5829a20e36a98b57d9b57b6f280865ae954016ed4`
- Gamescope source diff SHA-256:
  `a6617c062c8987b34d797ab20536aff30c72a1ee62b838f9f8cf3a18f376aada`
- Gamescope source submodules SHA-256:
  `ffb0e5c788894ee2a5498ccffe0fcabd659805200bc9bed025ce78e02cc0f8b0`
- Pulled Gamescope report SHA-256:
  `bb9a1ca264e6f0fff140f6c0d0794982809fa93d497f295b9cfdfe7e4a713333`
- Final Android capture SHA-256:
  `3f0b8518d7dd260e14a3ea73ced1c8a9380935c2b9263fa35706e1fb53b892c4`
- Final X11 capture SHA-256:
  `330f95429252aa38c898b9d01ff41147a28f77f825ee16f96e97370524d252ee`
- PID-filtered logcat SHA-256:
  `2ce71e3b22ec5d0966d1f614176d620a0c49689891df1c92e569147b1c588120`

The complete artifact directory is
`android/nova-lab/build/manual-runs/manual-20260809T022100Z-clocktrace/`.
The report pulled during teardown is retained as
`report-pulled-on-stop.txt` in that directory.

## Evidence gate

The valid foreground run used a fresh CDP forward on port `18091`, a fresh
Gamescope/Android process set, and the exact cleanup wrapper. The CDP route
changed from the language screen to the timezone screen after Android
`KEYCODE_BUTTON_A` (`input keyevent 96`), and the final Android capture was a
valid 1280x960 timezone screen. The capture shows the device's 4:3 aspect
ratio rather than a stretched 16:9 presentation. The X11 capture was taken
from the same run.

The first two detached host-launch attempts exited before a device session
was established and were not treated as experiments. The evidence below is
only from the subsequent foreground run with the run identity above.

The post-stop verifier passed residual-process, application-file, trace-state,
ACK-timeout-property, and ADB-forward cleanup checks. The device was left
without the Nova runtime running.

## Clock-correlated endpoint identity

The three connections remained generation 1 and `SOCK_STREAM` (`type=1`).
The endpoint table at the boundary was:

| Buffer | Android endpoint | Gamescope endpoint | Peer PIDs |
|---|---|---|---|
| 0 | fd 108, inode 10613283, cookie 80112 | fd 15, inode 10612278, cookie 84920 | Android 6220 ↔ Gamescope 6602 |
| 1 | fd 99, inode 10611404, cookie 80113 | fd 16, inode 10612279, cookie 84921 | Android 6220 ↔ Gamescope 6602 |
| 2 | fd 100, inode 10611405, cookie 80114 | fd 17, inode 10612280, cookie 84922 | Android 6220 ↔ Gamescope 6602 |

The reciprocal peer PIDs, stable inodes/cookies, socket type, generation, and
buffer paths rule out an obvious stale integer-FD or replacement-endpoint
explanation in this run. They do not rule out a second reader because the
Nova image still lacks a syscall-wide `strace -ff` or AF_UNIX consumer trace.

## Healthy cross-process ACKs immediately before the stall

The new fields establish a shared `CLOCK_MONOTONIC` domain. For frame 147,
Gamescope's complete ACK `sendmsg()` returned at
`75266651005609`, and Android's matching `ack_wait_end` returned at
`75266651031859`, a gap of about 26 microseconds. For frame 148, the
corresponding values were `75266660533942` and `75266660598421`, about 64
microseconds apart. Both records contained 103 payload bytes and one aligned
`SCM_RIGHTS` descriptor; Android logged the matching `ack_received` event.

This proves that the original stream transport, endpoint mapping, ancillary
descriptor path, and clock correlation all work for adjacent frames in this
same run. It also demonstrates that the new timestamps are useful for causal
ordering rather than merely adding labels to independent logs.

## Frame 149 boundary

Android completed frame 148, sent the release for buffer 0, and entered the
frame 149 ACK wait:

```text
Android 6220/6580:
frame=148 buffer=0 phase=release_sent
monotonic_ns=75266662792067 op=ack_wait_begin
  frame=149 buffer=2 fd=100 inode=10611405 cookie=80114
  payload=blocking_recvmsg=begin
monotonic_ns=75266662799150 op=ack_wait_probe result=0 revents=0x0
```

There is no later Android `ack_wait_end`, `ack_recv`, or `ack_received` for
frame 149 before teardown. The non-consuming probe also saw no queued data at
the beginning of the wait. Android therefore did not reach
`SurfaceControl` for frame 149.

Gamescope did not enter its frame 149 reuse wait until
`75326641813606`, about 59.979 seconds after Android entered the ACK wait:

```text
Gamescope 6602/6611:
frame=149 index=2 phase=wait_release
op=release_wait result=1 revents=0x1
op=release_recv result=17 payload=release_buffer=2
frame=149 phase=release_complete
frame=149 phase=compose_begin
op=ack_send result=103 errno=0 rights=1 fence_fd=117
frame=149 phase=ack_sent
```

The complete frame-149 ACK `sendmsg()` returned at
`75326650936419`, about 59.988 seconds after Android's
`ack_wait_begin`. The release socket poll itself returned immediately once
Gamescope reached it, and the send was complete with one aligned rights
descriptor. This means the 60-second gap is before the logged frame-149
`wait_release` phase, not a 60-second `poll()` timeout on that release socket.

The `release_buffer=2` record is consistent with the ring's slot mapping:
Android frame 147 presented buffer 0 and released the older buffer 2; Gamescope
later reuses slot 2 as frame 149. The differing frame labels are producer
phase labels, not proof that the release record belongs to the same frame
number. The protocol still lacks an explicit cross-process sequence, so this
relationship should be made first-class rather than inferred from modulo-3
position.

Gamescope continued through frame 150 and then was stopped while entering the
next release wait. This run did **not** produce the older
`Android release message wait failed` timeout before teardown; that older
downstream timeout remains valid for the separate run in
[`docs/10-ahb-and-harness/68-nova-ahb-blocking-stream-correlation-result-2026-08-09.md`](68-nova-ahb-blocking-stream-correlation-result-2026-08-09.md).

## Interpretation

The attached report's ACK-first topology remains a valid description of the
earlier paired run, but it is not universal across frames in this clocked
run. The refined causal statement is:

1. Frames 147 and 148 demonstrate complete, correctly routed ACK delivery
   over the original stream transport.
2. Android then blocks before presenting frame 149, with no data queued at the
   initial probe.
3. Gamescope does not reach the frame-149 reuse/ACK code for roughly 60
   seconds, then immediately consumes the already-available release record
   and sends a valid ACK.

This is evidence of a circular or backpressure-sensitive ring boundary whose
first visible symptoms occur on both sides. It is not evidence that a full
frame-149 ACK was sent and lost in the kernel. The prior result in doc 68
still establishes that a different run can show the simpler ACK-sent-before-
Android-wait ordering; the clocked result prevents treating that ordering as
an invariant.

The remaining high-value unknowns are now narrower:

- What Gamescope thread or wait accounts for the 60-second interval before
  frame 149's `wait_release` trace line?
- Is the interval caused by Vulkan submission/completion, compositor scheduling,
  or a hidden state transition before the output loop re-enters the ring?
- Can any other thread or process consume the ACK socket during the wait?
- Are the release records and buffer generations being tracked only by slot,
  or is an explicit frame/buffer ownership invariant already available in the
  code?

No change to ring size, SurfaceControl pacing, fence generation, or socket
type is justified by this result alone.

## Next diagnostic boundary

Before another long device run, audit and instrument the Gamescope output loop
around the gap between `frame=148 phase=ack_sent` and
`frame=149 phase=wait_release`. The next diagnostic patch should add paired
timestamps around every potentially blocking operation in that interval,
including the Vulkan/compositor submission wait and the call that enters
`wait_android_release()`. On Android, retain the existing timestamps around
`ack_wait_begin`, `recvmsg`, `setBuffer`, `OnComplete`, and release send.

That experiment should preserve the original stream transport and three-buffer
ring. It should not combine a one-buffer fallback, a single control socket,
and a fence redesign in the same run.

## Limitations

- `strace` and `trace-cmd` were unavailable on the Nova image, and tracefs did
  not expose syscall or AF_UNIX consumer events. The run therefore cannot rule
  out an unexpected reader at the syscall level.
- The Gamescope trace does not yet bracket every wait between the frame phase
  lines, so the exact source of the 60-second gap is not identified.
- The initial Android baseline screenshot was black even though the capture
  command and CDP route succeeded. The final screenshot was valid; the black
  baseline is retained as a separate capture-timing observation and is not
  used as visual proof of the boundary.

## Teardown

The checked finish helper recorded:

```text
nova_teardown_status=pass
post_stop_forward_remove=pass port=18091
post_stop_adb_forward=pass port=18091
post_stop_residual_processes=pass
post_stop_app_files=pass
post_stop_trace_state=pass
post_stop_ack_poll_timeout_state=pass
post_stop_verification=pass
```

The device property `debug.nova.ahb_ack_poll_timeout_ms` was reset to `0`,
and no runtime process, bridge socket, temporary mount, or ADB forward from
this run remained active.
