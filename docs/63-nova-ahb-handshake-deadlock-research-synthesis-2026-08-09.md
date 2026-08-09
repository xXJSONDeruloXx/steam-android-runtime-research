# Nova AHardwareBuffer handshake-deadlock research synthesis — 2026-08-09

Status: incorporated from the user-supplied deep research report; no new
device run is represented by this document.

The source attachment was reviewed in full. Its SHA-256 is
`653e0ec4e4b631051e6d67ed432e534366ae35b788cf862c63c2173deb961857`.
This document preserves the conclusions that affect the repository's next
implementation and experiment decisions without making the attachment itself
a runtime dependency.

## Causal conclusion

The current evidence places the first reproducible divergence on the
Gamescope-to-Android ACK path:

1. Android enters `wait_ack` for frame N and buffer i.
2. Gamescope records a complete `ack_sent` for that frame and can advance on
   the other ring slots.
3. Android records no matching `ack_received` and therefore does not present
   frame N or produce the later SurfaceFlinger release for the slot Gamescope
   will eventually reuse.
4. Gamescope wraps the three-buffer ring, waits for that release, and times out
   in its release-message poll.

The release-message timeout is consequently a downstream deadlock symptom in
these traces, not proof that the release fence initiated the stall. Steam,
CEF/X11, and the upstream Gamescope composition path can continue advancing
while the Android layer remains visually stale.

The report's strongest stream example was Android frame 245/buffer 2 at
`wait_ack`, followed by Gamescope `ack_sent` for frames 245 and 246 and a
frame-247 release wait timeout. The repository's latest bounded stream run
reproduced the same topology at frame 273/buffer 0; see
[`docs/60-nova-ahb-receive-timeout-observability-result-2026-08-09.md`](60-nova-ahb-receive-timeout-observability-result-2026-08-09.md).

The earlier `SOCK_SEQPACKET` run moved the failure to approximately frame 166
instead of removing it. That makes ordinary stream record coalescing or
splitting an insufficient primary explanation, while leaving endpoint
lifecycle, competing readers, syscall semantics, and ancillary-FD handling in
scope. See [`docs/45-nova-ahb-seqpacket-result-2026-08-08.md`](45-nova-ahb-seqpacket-result-2026-08-08.md).

## Evidence already incorporated

- [`docs/49-nova-ahb-socket-trace-result-2026-08-08.md`](49-nova-ahb-socket-trace-result-2026-08-08.md)
  established complete stream ACK sends/receives before the later blocked
  boundary.
- [`docs/54-nova-ahb-transport-observability-result-2026-08-09.md`](54-nova-ahb-transport-observability-result-2026-08-09.md)
  established stable endpoint identities, peer credentials, connection
  generations, and complete ACK/SCM_RIGHTS sends at the reproduced boundary.
- The Android transport code now records `sendmsg`/`recvmsg` results,
  conditional errno, message flags, control length, cmsg summaries, and
  SCM_RIGHTS count, rejects `MSG_CTRUNC`/`MSG_TRUNC` and malformed control
  headers, and receives SCM_RIGHTS with `MSG_CMSG_CLOEXEC`.
- [`docs/58-nova-ahb-read-queue-result-2026-08-09.md`](58-nova-ahb-read-queue-result-2026-08-09.md)
  showed that the old `FIONREAD` probe was unreachable because the blocking
  `recvmsg()` had not returned.
- [`docs/60-nova-ahb-receive-timeout-observability-result-2026-08-09.md`](60-nova-ahb-receive-timeout-observability-result-2026-08-09.md)
  proved that Android successfully set and read back a 15-second
  `SO_RCVTIMEO`, but the receive still remained blocked through the observed
  window.
- [`docs/61-parent-session-process-audit-followup-2026-08-09.md`](61-parent-session-process-audit-followup-2026-08-09.md)
  and [`docs/62-nova-harness-audit-repairs-2026-08-09.md`](62-nova-harness-audit-repairs-2026-08-09.md)
  keep the next observation run tied to a fresh PID, dynamic X11 window
  identity, sequential capture status, and fail-closed teardown.

## Hypothesis priority

The report's ordering is now the repository's working decision order:

1. Wrong, replaced, or stale AF_UNIX connection; an integer FD alone is not a
   stable endpoint identity.
2. Another Android thread or process consumes the ACK before the traced
   receiver.
3. Gamescope's `sendmsg()` did not fully enqueue the expected record, despite
   the higher-level `ack_sent` line.
4. Ancillary truncation, malformed SCM_RIGHTS state, FD lifecycle, or a stale
   descriptor integer.
5. Only after the transport boundary is disproved: SurfaceControl latch and
   callback timing, release identity, modulo ring accounting, or device-specific
   compositor behavior.

The next evidence must answer these questions in order:

```text
Did Gamescope send the complete ACK record?
  no  -> sender/socket failure
  yes
    Are Gamescope and Android the intended live endpoint pair?
      no  -> connection lifecycle/routing bug
      yes
        Did any other thread/process consume the bytes?
          yes -> wrong reader
          no
            Did the intended recvmsg return a valid ACK and one fence FD?
              no  -> receive/framing/ancillary failure
              yes -> investigate SurfaceControl and release identity
```

For Gamescope `poll()` diagnostics, a return value of zero means timeout;
`errno` is meaningful only when the return value is negative. A stale
`EAGAIN` value printed beside `poll=0` must not be treated as the poll result.

## Independent correctness items

The report also identifies two fixes that are valid independently of the
initiating missing-ACK trace:

- Keep the defensive ancillary validation and `MSG_CMSG_CLOEXEC` behavior in
  the transport path.
- Treat `ASurfaceTransactionStats_getPreviousReleaseFenceFd()` returning `-1`
  as “the previous buffer is already released,” not automatically as a
  missing-release failure. The current modulo-based release path still records
  this as `ahb_double_buffer_release_N=missing`; that is a separate known bug
  and is deliberately not mixed into the next transport-boundary experiment.

Longer term, explicit sequence numbers independent of `frame % 3`, explicit
AHardwareBuffer identity/generation, and an API-36 per-buffer release callback
remain the preferred lifecycle design. They are not prerequisites for the
next diagnostic.

## Next experiment

The next one-variable run is predeclared in
[`docs/64-nova-ahb-poll-recvmsg-boundary-experiment-2026-08-09.md`](64-nova-ahb-poll-recvmsg-boundary-experiment-2026-08-09.md).
It adds a property-gated finite `poll()` immediately before `recvmsg()` so a
known deadline can record `FIONREAD` without waiting for the device's
`SO_RCVTIMEO` behavior. It leaves socket type, ring size, fences,
SurfaceControl pacing, and Steam input unchanged.
