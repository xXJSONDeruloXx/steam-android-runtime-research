# Nova AHardwareBuffer socket-trace experiment card

Date: 2026-08-08

Status: predeclared; no device result yet.

## Motivation

The seqpacket run
`legacy-20260808T231050Z-ahbseqpacket` reached the same class of deadlock as
the earlier stream run: Gamescope waited for a release message while Android
stopped progressing in its ACK receive loop. The seqpacket variant failed at
frame 168 / buffer 0; the earlier stream variant failed at frame 247 / buffer
1. Existing traces show the high-level phase boundary but not whether a
`sendmsg` or `recvmsg` returned a short/error result, whether ancillary data
was truncated, whether the fence descriptor was valid, or whether a socket
connection changed identity.

## Experiment profile

Use the original `SOCK_STREAM` transport with diagnostic logging enabled. The
transport is restored to the stream baseline from before the seqpacket
experiment; the only new behavior is opt-in logging. Do not change the
three-slot ring, AHardwareBuffer ownership, SurfaceControl transactions,
fence waits, pacing, resolution, composition mode, or input bridge.

The Android and Gamescope logs must record, for every relevant operation:

- frame and buffer index;
- socket FD and `fstat` inode/connection identity;
- socket type at setup;
- `sendmsg`/`recvmsg` return value and errno when it is meaningful;
- payload byte count and expected message/buffer;
- `msg_flags`, including `MSG_CTRUNC` or `MSG_TRUNC`;
- ancillary-message count, `SCM_RIGHTS` count, and the received fence FD;
- `poll` result, revents, timeout, and errno when the poll fails or times out.

The trace is opt-in through the existing Nova diagnostic-property mechanism and
must be disabled by default. It must not alter blocking, retry, close, or
ownership behavior.

## Expected evidence

The run is useful even if it fails again. It should classify the boundary:

1. If Gamescope logs a full ACK `sendmsg` for frame N on a stable connection
   but Android has no matching `recvmsg`, inspect the socket transport or
   peer/connection identity.
2. If Android receives the ACK but reports a missing/invalid fence or the
   wrong buffer sequence, inspect ancillary-data handling and descriptor
   lifetime.
3. If Android sends a complete release record but Gamescope's poll sees no
   readable event on the same inode, inspect connection replacement and the
   stream record boundary.
4. If both syscalls and descriptors are valid through the route transition,
   leave the socket hypothesis and move to SurfaceControl release/latch or
   buffer ownership with a new experiment card.

Acceptance remains the same 1280x960 fullscreen profile: the fresh CDP route
must correlate with the same-run X11 and Android captures, and the report must
show complete release/ACK phases beyond the prior boundary. A repeated stall
is not a generic failure; the new syscall-level fields must make its failing
edge explicit.

## Run gate

Before launch, read `docs/34-nova-runtime-harness-lifecycle.md`, run the exact
Nova cleanup helper, use a new run ID and artifact directory, and record the
Gamescope binary/source/diff/dependency hashes plus the exact APK SHA-256.
Rediscover focus before each A event and the mapped X11 window before each
capture. Stop when the network route is correlated or the traced handshake
boundary is classified. Require runtime, app-file, and AHB-trace reset pass
markers before documenting the result.

Do not combine this diagnostic run with an ownership, ring-size, fence-policy,
or timing workaround. If a workaround becomes necessary, publish this
diagnostic result first and create a separate hypothesis card.
