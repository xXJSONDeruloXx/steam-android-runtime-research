# Nova blocking-stream ACK correlation result — 2026-08-09

Status: valid bounded device result; the original blocking stream receiver
reproduced the paired ACK boundary and the guarded teardown passed.

## Run identity and provenance

- Run: `manual-20260809T014242Z-blockcorr`
- Profile: `manual-stream-blocking-correlation`
- Android PID: `30922`; ACK thread TID: `31280`
- Gamescope peer PID: `31318`
- Presentation: fullscreen 1280x960, GPU composition disabled, libei-enabled
  Gamescope, Android keyevent input bridge, original `SOCK_STREAM` transport,
  three AHardwareBuffers.
- ACK poll property: `NOVA_AHB_ACK_POLL_TIMEOUT_MS=0`; Android used the
  blocking `recvmsg(MSG_CMSG_CLOEXEC)` path.
- Gamescope binary SHA-256:
  `9b9c0966e99566b1b45fe25f7083643cf62476c46cc1bcf5f77cee0c38d15d3e`
- APK SHA-256:
  `d18267b10885320bf2fa56a5b1ac0b85eec3737626069ba6eb9a7f21c6547ff0`
- Gamescope source commit: `fb9f84ee247a1f02b1a132da60e94585db84bf61`
- Pulled Gamescope report SHA-256:
  `b695ab3d033b0d043ac03cff19e628526bf4bb789d610be0b800f0d6a71820fd`

The complete artifact directory is
`android/nova-lab/build/manual-runs/manual-20260809T014242Z-blockcorr/`.
The source report was also retained as
`report-pulled-on-stop.txt`; its post-stop hash is recorded above.

## Evidence gate

Baseline, after-A, and final captures all passed. The CDP route changed from
`/routes/oobe/1/language` at baseline to `/routes/oobe/1/timezone` after
Android keyevent 96 (A), and remained on timezone in the final capture. Focus
remained the Nova `MainActivity`; the dynamic X11 window ID stayed
`0x1a0003b`. The outer session log records the `BTN_SOUTH` press/release.

The final 1280x960 Android capture shows the timezone screen with Pacific
Standard Time selected. This confirms that the UI/input path advanced before
the later transport stall; it is not evidence that the full Steam session is
already stable.

## Paired ACK boundary

Immediately before the boundary, Android completed frame 123 and then entered
the blocking receive for frame 124/buffer 1:

```text
Android 30922/31280:
ahb_double_buffer_trace frame=124 buffer=1 phase=wait_ack bytes=-1 fence=0 status=0
ahb_socket_trace op=ack_wait_begin frame=124 buffer=1 fd=99
  inode=10526394 type=1 generation=1 cookie=90795 peer_pid=31318
  payload=blocking_recvmsg=begin
```

There is no later `ack_wait_end`, `ack_recv`, or positive
`ack_received` record for frame 124 in the run. Android therefore did not
reach `SurfaceControl` for that frame.

Gamescope, on the corresponding buffer-1 connection, completed the release
handoff and recorded a full ACK send:

```text
Gamescope 31318:
android_ahb_trace frame=124 index=1 submitted=1 phase=release_complete
android_ahb_socket_trace op=ack_send frame=124 index=1 fd=16
  inode=10526395 type=1 generation=1 cookie=79782 peer_pid=30922
  result=103 errno=0 msg_flags=0x0 msg_controllen=24
  cmsgs=1:1:20:aligned rights=1 fence_fd=107
  payload=linux_import=pass linux_gpu_write=pass
          linux_image_write=pass linux_acquire_fence=pass linux_loop=pass
android_ahb_trace frame=124 index=1 submitted=1 phase=ack_sent
```

The next two frames show the ring amplifier: Gamescope also sent frame 125,
then reached frame 126/buffer 0 and timed out waiting for the release record
that Android could not produce while stuck before presenting frame 124:

```text
android_ahb_trace frame=126 index=0 submitted=1 phase=wait_release
android_ahb_socket_poll op=release_wait frame=126 index=0
  result=0 revents=0x0 errno=0
Android release message wait failed buffer 0 poll=0 revents=0x0 errno=0
Android output release fence wait failed for buffer 0
```

This is the report's strongest causal topology reproduced on the Nova device:
the missing Android ACK is the initiating boundary, while the later release
timeout is the consequence of the three-buffer ring wrapping around.

## Endpoint identity

All three connection generations stayed at 1 and `SOCK_STREAM` (`type=1`).
The peer PID and socket path identify the expected Android/Gamescope pairs:

| Buffer | Android endpoint | Gamescope endpoint | Peer PIDs |
|---|---|---|---|
| 0 | fd 108, inode 10527700, cookie 79781 | fd 15, inode 10527997, cookie 90794 | Android 30922 ↔ Gamescope 31318 |
| 1 | fd 99, inode 10526394, cookie 90795 | fd 16, inode 10526395, cookie 79782 | Android 30922 ↔ Gamescope 31318 |
| 2 | fd 100, inode 10527998, cookie 79783 | fd 17, inode 10527999, cookie 90796 | Android 30922 ↔ Gamescope 31318 |

The opposite-end cookies and inodes are necessarily different, but the
reciprocal peer PIDs, generation, buffer path, and stable three-socket mapping
exclude a simple stale integer-FD or obvious replacement-endpoint explanation
for this run. This does not yet exclude an additional reader; no syscall-wide
`strace -ff` or kernel socket-consumer trace was run.

The sender-side syscall and ancillary evidence also rules out a short or
failed ACK send for this frame: Gamescope returned the complete 103-byte
record with one aligned rights descriptor. Because Android never returned
from `recvmsg()`, this frame does not implicate receiver-side cmsg parsing or
`MSG_CTRUNC` as the immediate event. They remain hardening requirements for
other paths.

## Interpretation and next action

This result upgrades the report's front-of-chain priorities:

1. Find whether another thread/process can consume the ACK socket, using
   syscall-wide `strace -ff` or an equivalent per-FD consumer trace.
2. Correlate the exact kernel socket queue and connection lifecycle at the
   sender's full `sendmsg()` and the receiver's blocked `recvmsg()`.
3. Audit the Gamescope/Android startup and socket ownership state for hidden
   readers or lifecycle races, even though the endpoint table is stable.
4. Keep the ring, SurfaceControl pacing, and fence-generation behavior
   unchanged until the consumer/queue question is answered.

The timed-poll run in
[`docs/10-ahb-and-harness/66-nova-ahb-poll-recvmsg-boundary-result-2026-08-09.md`](66-nova-ahb-poll-recvmsg-boundary-result-2026-08-09.md)
remains useful as a finite queue observation, but its fail-closed timeout
prevented the sender from completing the matching ACK. This blocking run is
the stronger correlation artifact and supersedes it for causal ordering.

## Teardown

The checked finish helper passed all cleanup gates:

```text
post_stop_adb_forward=pass port=18090
post_stop_residual_processes=pass
post_stop_app_files=pass
post_stop_trace_state=pass
post_stop_ack_poll_timeout_state=pass
post_stop_verification=pass
```

The intentional host-session stop returned 143, but the device cleanup and
post-stop verification both passed. The ACK poll property was reset to zero;
this run must not be reused as a readiness or process baseline.
