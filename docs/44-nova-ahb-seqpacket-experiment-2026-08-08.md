# Nova AHB seqpacket transport experiment

Date: 2026-08-08

Status: executed once; the transport-only result is recorded in
[`docs/45-nova-ahb-seqpacket-result-2026-08-08.md`](45-nova-ahb-seqpacket-result-2026-08-08.md).

## Hypothesis

The reproduced stream run reached a cross-process cycle at app frame 245 /
Gamescope frame 247: Android blocked in one `recvmsg` waiting for an ACK while
Gamescope blocked in `poll` waiting for the next release message. Both sides
use `SOCK_STREAM` but consume each `sendmsg`/`recvmsg` call as if it were one
complete record. Unix stream coalescing or partial record/control-message
delivery could therefore lose the per-buffer framing or an associated fence.

## Single variable

The experiment changes only the three AHB control sockets on both endpoints
from `SOCK_STREAM` to `SOCK_SEQPACKET`:

- Android `ahbbridge.c` server sockets;
- Gamescope `HeadlessBackend.cpp` client sockets.

AHardwareBuffer ownership, the three-slot ring, frame cadence, release-fence
logic, composition mode, resolution, input bridge, Steam state, and cleanup
profile remain unchanged. The seqpacket binary is built from the same base
Gamescope commit and the same patch stack in a separate source/build
directory.

## Expected evidence

The variant supports the framing hypothesis if it runs past the prior
frame-247 buffer-1 `wait_release` failure and the second A event advances CDP
timezone → network, with matching X11 and Android network captures. Its
Gamescope report should show complete `release_message` and `release_complete`
phases after frame 247, while the Android log continues to show
`ack_received` for each frame.

If the same failure recurs at the same buffer/frame boundary, seqpacket did not
remove the cause; keep the result as a disproved framing hypothesis and inspect
ACK send/receive return values and fence descriptors before touching ownership.
Any other failure before the frame boundary is a separate artifact or startup
regression and is not evidence about the hypothesis.

## Acceptance and stop condition

Use a new run ID, unique artifact directory, explicit 1280x960 fullscreen
profile, libei-enabled Gamescope, APK/source/binary/diff/dependency hashes, and
the lifecycle gate in `docs/34-nova-runtime-harness-lifecycle.md`. Send one A
event from language → timezone, then one from timezone → network only after a
fresh focus check. Poll CDP for route changes instead of sleeping for a fixed
capture delay; rediscover the mapped X11 window before each capture.

Stop after the network route is either correlated or the frame-247 handshake
failure is reproduced. Run the exact stop helper and require runtime, app-file,
and trace-reset pass markers before documenting the result. Do not combine a
transport result with an ownership or ring change in the same run.
