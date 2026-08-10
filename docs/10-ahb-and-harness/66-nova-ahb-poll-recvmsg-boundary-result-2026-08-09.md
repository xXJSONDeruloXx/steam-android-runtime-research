# Nova AHardwareBuffer poll/recvmsg boundary result — 2026-08-09

Status: valid bounded device result; the timed-poll experiment completed and
the guarded teardown passed.

## Run identity and provenance

- Run: `manual-20260809T013314Z-ahbpoll5`
- Profile: `manual-stream-ack-poll`
- Android PID: `25831`; ACK thread TID: `26220`
- Gamescope PID at the boundary: `26258`
- Presentation: fullscreen 1280x960, GPU composition disabled, libei-enabled
  Gamescope, Android keyevent input bridge, original `SOCK_STREAM` transport,
  three AHardwareBuffers.
- ACK poll property: `NOVA_AHB_ACK_POLL_TIMEOUT_MS=15000`, recorded as
  `debug.nova.ahb_ack_poll_timeout_ms` in the APK log.
- Gamescope binary SHA-256:
  `9b9c0966e99566b1b45fe25f7083643cf62476c46cc1bcf5f77cee0c38d15d3e`
- APK SHA-256:
  `7803ab05bf3d8df70bdbbe2cfab8b8030d4cc7bc258078efe55452a668ff8f58`
- Gamescope source commit: `fb9f84ee247a1f02b1a132da60e94585db84bf61`
- Pulled Gamescope report SHA-256:
  `96d68c9e84816eefde6c4dd2f82d04ed78e06be5a5c48699b7f000c8faf01eac`

The complete artifact directory is
`android/nova-lab/build/runs/manual-20260809T013314Z-ahbpoll5/`.

## Evidence gate

All three same-run evidence phases passed. The CDP route changed from
`/routes/oobe/1/language` at baseline to `/routes/oobe/1/timezone` after
Android keyevent 96 (A). Focus remained the Nova `MainActivity`; the dynamic
X11 manifest held window `0x1a0003b` for baseline, after-A, and final. The
outer manual-session log records both `BTN_SOUTH` press/release events.

The final Android screenshot shows the timezone selection screen while the
CDP route is timezone. The language capture also visibly retains the known
missing-glyph rectangles in several language names; that remains a separate
font issue, not this transport experiment.

## Timed receive result

The three accepted-client timeout records all read back successfully:

```text
set_result=0 set_errno=0 get_result=0 get_errno=0
effective_sec=15 effective_usec=0 ack_poll_timeout_ms=15000
```

The timed poll returned readable (`result=1 revents=0x1`) for the ACK waits
through frame 108. Those accepted messages were complete 103-byte ACKs with
one aligned `SCM_RIGHTS` descriptor and the expected Linux import/GPU/image/
acquire-fence/loop markers. No `MSG_CTRUNC` or `MSG_TRUNC` record appeared.

At frame 109/buffer 1, Android recorded:

```text
ack_wait_begin fd=99 inode=10466244 type=1 generation=1 cookie=84490
ack_wait_probe result=0 revents=0x0
ack_wait_timed result=0 revents=0x0 errno=0
ack_wait_timeout result=0 errno=0
  recv_timeout_queue_bytes=0 queue_errno=0 poll_timeout_ms=15000
```

No `recvmsg()` was called after the timed poll returned zero, so there is no
`ack_wait_end`, payload, or ancillary result for frame 109. The caller then
failed closed with `bytes=-1`, as intended by this diagnostic. The zero queue
count is therefore measured at the finite poll boundary; it is not the old
“FIONREAD after a negative blocking recv” ambiguity.

## Endpoint identity and downstream effect

The endpoint pairs remained stable at connection generation 1 and `SOCK_STREAM`
(`type=1`):

| Buffer | Android endpoint | Gamescope endpoint | Peer PIDs |
|---|---|---|---|
| 0 | fd 108, inode 10467450, cookie 90762 | fd 15, inode 10467653, cookie 84489 | Android 25831 ↔ Gamescope 26258 |
| 1 | fd 99, inode 10466244, cookie 84490 | fd 16, inode 10466245, cookie 90763 | Android 25831 ↔ Gamescope 26258 |
| 2 | fd 100, inode 10467654, cookie 90764 | fd 17, inode 10467655, cookie 84491 | Android 25831 ↔ Gamescope 26258 |

Gamescope completed `ack_sent` for frame 108. At frame 109 it was waiting for
and received the already-queued Android release record for buffer 1, then
completed that release fence. Android had already failed closed at its 15-second
ACK poll, so Gamescope's subsequent frame-109 `sendmsg()` returned `-1` with
`errno=32` (`EPIPE`) rather than a full ACK. This is the expected downstream
effect of the diagnostic timeout; it is not evidence that Gamescope successfully
sent frame 109's ACK and Android dropped it.

The run therefore proves a precise finite-boundary fact—no ACK bytes were
readable on the intended Android buffer-1 socket at the timeout—but does not by
itself reproduce the stronger original pair “full sender ACK for N and blocked
receiver `recvmsg()` for N.” The earlier blocking stream runs remain the
evidence for that topology. This run also demonstrates why the next baseline
must preserve the blocking receiver while correlating the sender's exact
`sendmsg()` record.

## Harness observation and repair

The boundary helper initially reported `blocked_ack_window` for frame 79 even
though subsequent ACKs were received. It retained the first blocked frame
without clearing it after a positive ACK. That result is invalid as a boundary
marker, although the raw PID-filtered log is valid. The helper now clears and
replaces blocked state and recognizes the explicit `ack_wait_timeout` event;
the repair is included before the next experiment.

## Decision

Do not change socket type, ring size, SurfaceControl pacing, or fence
generation based on this run. The next atomic run is the unchanged blocking
stream baseline in
[`docs/10-ahb-and-harness/67-nova-ahb-blocking-stream-correlation-experiment-2026-08-09.md`](67-nova-ahb-blocking-stream-correlation-experiment-2026-08-09.md).
