# Nova clock-correlated AHB socket trace experiment — 2026-08-09

Status: predeclared; no device result yet.

This run follows the valid blocking-stream correlation in
[`docs/68-nova-ahb-blocking-stream-correlation-result-2026-08-09.md`](68-nova-ahb-blocking-stream-correlation-result-2026-08-09.md).
That run proved a full Gamescope ACK send for frame 124 while Android stayed
inside the matching blocking receive, with stable reciprocal endpoint
metadata. The remaining uncertainty is cross-process ordering and ownership:
the report recommends a syscall-wide trace, but the Nova image has no
`strace` or `trace-cmd` and its tracefs inventory exposes no syscall or
AF_UNIX consumer events.

## One-variable experiment

Add diagnostic-only fields to the existing Android and Gamescope trace lines:

```text
monotonic_ns
pid
tid
```

Emit them on every AHB phase, socket send/receive, and socket-poll event. Use
the same original `SOCK_STREAM` transport, three buffers, blocking Android
`recvmsg(MSG_CMSG_CLOEXEC)`, 1280x960 fullscreen presentation, libei-enabled
Gamescope artifact, and Android-keyevent input path. Do not change ring size,
SurfaceControl pacing, fence generation, socket topology, or Steam behavior.

The fields use the same monotonic clock domain in both processes, so the run
can answer whether the sender's complete `sendmsg()` occurs before or after
the receiver's `ack_wait_begin`, how long the receiver remains blocked, and
whether any unexpected thread ID emits a competing receive event.

## Build gate

An initial implementation edited the dependent transport patch after adding
lines to the output patch. Because the transport patch uses zero-context
hunks, that shifted its insertion points and produced malformed generated
Gamescope source. No device artifact came from that attempt. The output and
transport patches were restored unchanged; the clock fields now live in a
separate post-transport patch. A fresh sequential patch application, ARM64
Gamescope compile/link, and Android APK build all pass for this experiment.

## Required evidence

At the first persistent `wait_ack`, preserve:

```text
Android:   ack_wait_begin(ns,pid,tid) -> no ack_wait_end
Gamescope: release_complete -> ack_send(ns,pid,tid,result=full)
```

Also preserve the complete three-socket endpoint table, all three capture
phases, the Gamescope report, the Android PID-filtered log, and the checked
post-stop verification. If a receiver-side `recvmsg()` returns, retain its
clock/TID even if the protocol then rejects the record.

## Interpretation

- Full sender ACK and no receiver return, with clocks and endpoint identity
  consistent: prioritize socket queue/lifecycle or an unobserved reader; the
  absence of a device syscall tracer remains an explicit limitation.
- Sender ACK occurs only after Android has already returned from a receive:
  the previous topology was an observation-order artifact, so repeat with a
  longer synchronized capture before changing code.
- A second unexpected receive TID appears: the competing reader is the next
  code audit target.
- A valid receiver ACK appears before SurfaceControl: advance to explicit
  buffer identity and release semantics.
