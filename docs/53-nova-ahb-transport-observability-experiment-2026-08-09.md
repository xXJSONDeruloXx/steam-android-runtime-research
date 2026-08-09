# Nova AHardwareBuffer transport observability experiment — 2026-08-09

Date: 2026-08-09

Status: predeclared; no device result yet.

## Motivation

The receive-wait result in
[`docs/52-nova-ahb-app-receive-wait-result-2026-08-09.md`](52-nova-ahb-app-receive-wait-result-2026-08-09.md)
shows Android entering `recvmsg()` for frame 252 while Gamescope completes
ACK sends through frame 253 and later times out waiting for a release message.
The run records stable per-slot inodes, but not the peer relationship,
connection generation, complete ancillary state, or every possible reader.

## One-variable diagnostic change

Keep the original `SOCK_STREAM` transport, three-buffer ring, AHardwareBuffer
ownership, SurfaceControl transaction, release-fence policy, pacing,
fullscreen 1280x960 presentation, Gamescope composition, and input mode.
Add only transport observability and defensive receive checks on both sides:

- assign each accepted/connected slot a connection generation and log stable
  socket identity (`fstat` inode, `SO_TYPE`, local/peer names, peer credentials,
  and `SO_COOKIE` where supported);
- log the exact `sendmsg()`/`recvmsg()` result and errno only when the syscall
  returns negative;
- log `msg_flags`, `msg_controllen`, every ancillary header's level/type/length,
  and SCM_RIGHTS count/FD;
- receive SCM_RIGHTS with `MSG_CMSG_CLOEXEC`; and
- treat `MSG_CTRUNC`, `MSG_TRUNC`, malformed ancillary lengths, or a non-integral
  SCM_RIGHTS payload as an explicit protocol error.

The normal valid-message path must retain the same payloads, frame schedule,
buffer mapping, and fence ownership. No binary protocol header, ring-size,
SurfaceControl, `-1` release-fence, or retry/reconnect behavior is included in
this experiment.

## Interpretation

1. Full Gamescope `sendmsg()` plus a matching Android endpoint identity and no
   Android `recvmsg()` return, with no other reader, makes socket queue/wake or
   kernel-level tracing the next boundary.
2. Different peer names, credentials, cookies, or generations identify a
   connection lifecycle/routing bug before SurfaceControl is relevant.
3. A second `recvmsg()` consumer, found with `strace -ff` or equivalent,
   identifies an application reader-ownership bug.
4. `MSG_CTRUNC`, `MSG_TRUNC`, malformed cmsg data, or an unexpected FD count
   makes ancillary handling the immediate defect.
5. Clean endpoint identity, one reader, and valid ancillary metadata move the
   investigation downstream to SurfaceControl callback/latch and explicit
   release identity. Do not change those layers in this run.

## Run gate

Before launch, reread `docs/34-nova-runtime-harness-lifecycle.md`, use a new
run-scoped profile and preflight manifest, and record exact APK/Gamescope
artifacts plus source status/diff/submodule digests. Use a fresh stream run;
do not compare it with the earlier seqpacket result except as historical
context. Rediscover focus and the X11 window before each input/capture.

At the first receive boundary, preserve enough report and logcat output to
include the immediately preceding complete ACK, the Android wait, the next
Gamescope ACK/release wait, and all socket identity fields. If practical, run
`strace -ff` against both processes to detect another reader. Stop only after
the boundary is classified, then require exact runtime, app-file, and trace
reset pass markers before documenting the result.

Do not combine this experiment with the independent correction for Android
previous-release-fence FD `-1`; that behavior change gets its own card and
run.
