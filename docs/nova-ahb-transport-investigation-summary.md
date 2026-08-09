# Nova AHardwareBuffer transport investigation summary

Status: current synthesis through the clock-correlated result on 2026-08-09.
No device result is implied for the predeclared scheduler experiment in
[doc 72](72-nova-gamescope-present-cadence-experiment-2026-08-09.md).

## Current causal state

The strongest current result is [doc 70](70-nova-ahb-clock-correlated-socket-trace-result-2026-08-09.md):
frames 147 and 148 exchanged complete ACK records over the original
`SOCK_STREAM` transport, with reciprocal peer identities and one aligned
`SCM_RIGHTS` fence each. Android then entered the frame-149 ACK wait with no
queued data, while Gamescope did not reach its frame-149 reuse wait for about
60 seconds and sent the ACK immediately after consuming the available release.

This refines, rather than erases, the earlier ACK-first topology in [doc 68](68-nova-ahb-blocking-stream-correlation-result-2026-08-09.md), where a complete
Gamescope ACK was observed before Android's matching blocking receive returned.
The combined evidence points to a circular or backpressure-sensitive
three-buffer boundary. It does not prove a lost kernel packet, a SurfaceControl
release-fence fault, or a single universal ordering for every frame.

The continuous-repaint change in [doc 71](71-nova-ahb-continuous-repaint-fix-2026-08-09.md)
tests one plausible cause: an idle or low-damage scene may stop entering
Gamescope's `Present()` path while Android waits for the next ACK. The separate
[doc 72 scheduler experiment](72-nova-gamescope-present-cadence-experiment-2026-08-09.md)
adds trace-only evidence around `paint_all()`, repaint decisions, and
`Present()`; it must preserve the original transport and ring.

## What the investigation has ruled down

- The seqpacket comparison moved the boundary rather than removing it, so
  ordinary stream record coalescing is not a sufficient primary explanation
  ([doc 45](45-nova-ahb-seqpacket-result-2026-08-08.md)).
- The observability run found stable connection generations, peer credentials,
  endpoint identities, complete ACK sends, and valid ancillary state at the
  reproduced boundary ([doc 54](54-nova-ahb-transport-observability-result-2026-08-09.md)).
- Android successfully set and read back `SO_RCVTIMEO`; the blocking receive
  still did not return during the observed window ([doc 60](60-nova-ahb-receive-timeout-observability-result-2026-08-09.md)).
- A missing release message is a downstream symptom in the paired traces, not
  by itself proof that SurfaceControl initiated the stall.

The remaining high-value questions are which Gamescope wait accounts for the
clocked gap, whether an unexpected reader can consume an ACK, and whether
buffer ownership is being inferred too heavily from modulo-3 slots instead of
an explicit sequence/generation.

## Investigation timeline

| Stage | Experiment/result | Current meaning |
|---|---|---|
| Initial boundary | [39](39-nova-release-message-stall-2026-08-08.md), [42](42-nova-ahb-trace-stall-2026-08-08.md) | release wait and frame-level stall first observed |
| Socket shape | [44](44-nova-ahb-seqpacket-experiment-2026-08-08.md), [45](45-nova-ahb-seqpacket-result-2026-08-08.md) | seqpacket does not remove the boundary |
| Endpoint tracing | [47](47-nova-ahb-socket-trace-experiment-2026-08-08.md), [49](49-nova-ahb-socket-trace-result-2026-08-08.md) | valid stream ACK/FD exchange before the stall |
| Receive boundary | [51](51-nova-ahb-app-receive-wait-experiment-2026-08-08.md), [52](52-nova-ahb-app-receive-wait-result-2026-08-09.md) | Android's blocking wait is observable |
| Transport state | [53](53-nova-ahb-transport-observability-experiment-2026-08-09.md), [54](54-nova-ahb-transport-observability-result-2026-08-09.md) | peer and ancillary state remain valid |
| Queue/timeout | [57](57-nova-ahb-read-queue-experiment-2026-08-09.md), [58](58-nova-ahb-read-queue-result-2026-08-09.md), [59](59-nova-ahb-receive-timeout-observability-experiment-2026-08-09.md), [60](60-nova-ahb-receive-timeout-observability-result-2026-08-09.md) | timeout and queue probes do not explain the block |
| Timed poll | [64](64-nova-ahb-poll-recvmsg-boundary-experiment-2026-08-09.md), [66](66-nova-ahb-poll-recvmsg-boundary-result-2026-08-09.md) | finite polling is valid but not a transport fix |
| Paired blocking trace | [67](67-nova-ahb-blocking-stream-correlation-experiment-2026-08-09.md), [68](68-nova-ahb-blocking-stream-correlation-result-2026-08-09.md) | ACK-first ordering reproduced in one run |
| Shared-clock trace | [69](69-nova-ahb-clock-correlated-socket-trace-experiment-2026-08-09.md), [70](70-nova-ahb-clock-correlated-socket-trace-result-2026-08-09.md) | next run showed a 60-second pre-`wait_release` gap |
| Scheduler hypothesis | [71](71-nova-ahb-continuous-repaint-fix-2026-08-09.md), [72](72-nova-gamescope-present-cadence-experiment-2026-08-09.md) | source hypothesis implemented; device trace remains pending |

## Next decision gate

Run [doc 72](72-nova-gamescope-present-cadence-experiment-2026-08-09.md) only
after a fresh cleanup and immutable artifact build. Correlate the last healthy
frame-148 ACK with frame-149 `paint_all()`, repaint-decision, `Present()` entry,
and `wait_release` markers:

- no `paint_all()`/`Present()` means investigate repaint scheduling and vblank;
- `paint_all()` without `Present()` means investigate an early return;
- `Present()` before `wait_release` means bracket its blocking operation;
- prompt `wait_release` with no ACK means return to ring, socket, or reader ownership.

Do not combine this trace with a socket-type change, ring-size change,
retransmission, one-buffer fallback, or release-fence redesign.
