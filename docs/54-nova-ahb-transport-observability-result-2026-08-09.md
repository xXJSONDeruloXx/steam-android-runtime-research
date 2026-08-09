# Nova AHardwareBuffer transport observability result — 2026-08-09

Date: 2026-08-09

Run: `manual-20260809T002802Z-ahbtransportobs`

Profile: `manual-stream-transport-observability`

Status: the reproducible ACK-to-release deadlock survives complete endpoint,
syscall, and ancillary-data tracing. This run strongly disfavors a replaced
connection, a short/failed Gamescope ACK send, and SCM_RIGHTS truncation as the
initiating defect. It does not yet prove why a full ACK send does not wake the
intended Android receive, and it does not absolutely exclude a second reader
because a device-wide `strace -ff` capture was not available in this run.

## Causal boundary

The run used the original `SOCK_STREAM` transport, three buffers, the existing
AHardwareBuffer/SurfaceControl ownership loop, fullscreen 1280x960 output, and
the same Android-keyevent input mode. The first A event advanced the live CDP
route from language to timezone. The transport then reproduced the stall:

```text
Android:
frame=317 buffer=2 phase=ack_received
frame=318 buffer=0 phase=wait_ack
ack_wait_begin fd=108 inode=9954860 generation=1 cookie=90301 peer_pid=14026
ack_wait_probe result=0 revents=0x0
... no ack_wait_end or ack_recv for frame 318 before stop ...

Gamescope:
frame=318 index=0 phase=ack_send
ack_send fd=15 inode=9957110 generation=1 cookie=87212 peer_pid=13616
    result=103 msg_flags=0x0 msg_controllen=24 cmsgs=1:1:20:aligned rights=1
frame=318 index=0 phase=ack_sent
frame=319 index=1 phase=ack_send
ack_send fd=16 inode=9957111 generation=1 cookie=87213 peer_pid=13616
    result=103 msg_flags=0x0 msg_controllen=24 cmsgs=1:1:20:aligned rights=1
frame=319 index=1 phase=ack_sent
frame=320 index=2 phase=wait_release
release_wait result=0 revents=0x0 errno=0
Android release message wait failed buffer 2 poll=0 revents=0x0 errno=0
```

The important comparison is that Android is waiting on the socket whose peer
is Gamescope PID 14026, while Gamescope reports a complete frame-318 ACK on
the socket whose peer is Android PID 13616. The local cookies differ because
they identify the two endpoint objects, but their peer credentials and stable
slot paths identify the expected connection pair. The later Gamescope release
timeout is therefore still the ring's downstream consequence of the earlier
missing Android ACK, not evidence that the release fence initiated this run's
stall.

## Endpoint identity

All six control endpoints remained at connection generation 1 and reported
`SOCK_STREAM` (`type=1`) through the boundary.

| Buffer | Android endpoint | Gamescope endpoint | Peer relationship |
| --- | --- | --- | --- |
| 0 | fd 108, inode 9954860, cookie 90301, path `.0` | fd 15, inode 9957110, cookie 87212 | Android peer PID 14026; Gamescope peer PID 13616 |
| 1 | fd 99, inode 9956265, cookie 90302, path `.1` | fd 16, inode 9957111, cookie 87213 | Android peer PID 14026; Gamescope peer PID 13616 |
| 2 | fd 100, inode 9956266, cookie 90303, path `.2` | fd 17, inode 9957112, cookie 87214 | Android peer PID 14026; Gamescope peer PID 13616 |

The Android logs record `peer_uid=0 peer_gid=0`; Gamescope records
`peer_uid=10121 peer_gid=10121`. The saved `/proc/$pid/fd` and
`/proc/net/unix` snapshots agree with the per-message identities. No
replacement connection or generation change was observed.

## Syscall and ancillary state

Every complete ACK send before the boundary returned the full 103-byte
payload. Every complete ACK/release receive returned its expected payload and
one descriptor. The relevant messages consistently reported:

- sender `msg_flags=0x0`, `msg_controllen=24`, one aligned `SOL_SOCKET` /
  `SCM_RIGHTS` header of length 20, and `rights=1`;
- receiver `msg_flags=0x40000000` from the `MSG_CMSG_CLOEXEC` receive path,
  `msg_controllen=24`, the same single rights header, and `rights=1`; and
- no `MSG_CTRUNC`, `MSG_TRUNC`, malformed cmsg, or protocol-error record.

The received fence descriptors were installed with close-on-exec. The sender
side release messages also completed with 17-byte payloads and one rights FD
until Android stopped producing the frame-318 release successor. The trace
therefore does not support a short send, an `EINTR`/`EPIPE` send failure, or
ancillary truncation as the cause of this particular missing ACK.

## Reader ownership

The app source contains two AHB `recvmsg()` call sites: the double-buffer ACK
path and the older single-buffer path. The only other `recvmsg()` in the app
is the raw input bridge's private socketpair; it is not an AHB control socket.
During the run, Android's AHB wait was executing on thread 13988
(`pool-2-thread-1`). No second AHB consumer was identified in source or in the
captured thread inventory.

This is not a complete runtime exclusion: the run did not attach
`strace -ff`/eBPF to every process and thread. The next transport diagnostic
must make that check explicit before escalating to AF_UNIX kernel queue/wake
behavior.

## UI and presentation correlation

The first A event was accepted with `MainActivity` focused and moved CDP from
`/routes/oobe/1/language` to `/routes/oobe/1/timezone` on the next bounded poll.
The immediate Android capture still showed the language page while the same
run X11 window already showed timezone; a later final capture showed timezone
on both surfaces. This is a repeat of the known transient stale-frame
observation and is kept separate from the transport boundary. It is not a
claim that the app reached the network page.

| Artifact | SHA-256 |
| --- | --- |
| Android baseline | `3c95016476f01863a6cab4384123a0dd184e6f44bab235a0c66b87cb8c68839f` |
| X11 baseline PPM | `ded6675f1fb7fa35be0a363f4e6cebf1c48376ca400b7e62ed035f0a41f21cc1` |
| Android after A | `1ed2e9deb0ef5050584f24868284ecc91cc83c9a9fb1e7db5238f97402c08974` |
| X11 after A PPM | `c211372e1cdb4e97abfc3a7ac37d7b433cf55866e7dede346bde1b2fac51c28a` |
| Android final | `d35f5daba732ec7d3176673abc06e4a2c34895c78103dee7bb18f776128b48bb` |
| X11 final PPM | `c1a5640dca7bf11a3624471197ab9e71f2e92c18ae2ace1542e684653000e0c` |

The X11 window was rediscovered from the live tree as `0x1a0003b`, with
1280x960 dimensions. The CDP final route remained
`/routes/oobe/1/timezone`.

## Provenance

- Gamescope binary:
  `android/nova-lab/build/gamescope-headless-build-observability/src/gamescope`
- Gamescope SHA-256:
  `9b9c0966e99566b1b45fe25f7083643cf62476c46cc1bcf5f77cee0c38d15d3e`
- Gamescope source tree:
  `android/nova-lab/build/gamescope-headless-source-observability`
- Gamescope source commit: `fb9f84ee247a1f02b1a132da60e94585db84bf61`
- Gamescope source status SHA-256:
  `e2ee88158467e2b5255510f5829a20e36a98b57d9b57b6f280865ae954016ed4`
- Gamescope source diff SHA-256:
  `1ce71f25727a55b0765cf88b31a28ce811a0de17cbdc396a5838388f61bf1fc2`
- Gamescope source submodules SHA-256:
  `ffb0e5c788894ee2a5498ccffe0fcabd659805200bc9bed025ce78e02cc0f8b0`
- APK:
  `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256:
  `62c1a2e7259243dda4a1bec0f9d4b48a10bd3087165049b3e2dfc0151ef2b103`
- X11 capture helper SHA-256:
  `a8971824bfcb812139bcc7451a1ab2c262b4a2af0ff9d462e25206a3efb4b017`
- Presentation: fullscreen 1280x960; GPU composition disabled
- Gamescope libei build: enabled; input emulation: enabled
- AHB/socket tracing: enabled
- Steam/Gamescope bounded timeouts: 900 seconds
- Preflight manifest:
  `android/nova-lab/build/runs/manual-20260809T002802Z-ahbtransportobs/device-gamescope-headless-ahb-preflight.txt`

All run-scoped reports, phase logs, CDP/focus captures, X11 captures, socket
snapshots, and cleanup records are retained under:

`android/nova-lab/build/runs/manual-20260809T002802Z-ahbtransportobs/`

## Cleanup and methodology notes

The explicit stop and independent post-stop checks passed:

```text
nova_runtime_cleanup=pass
native_steam_runtime_cleanup=pass
native_steam_app_files_cleanup=pass
native_steam_ahb_trace_reset=pass
ahb-trace=0
ahb-socket-trace=0
runtime_files_status=0
filtered_residual_processes=empty
adb_forward_18082=removed
```

Two ad-hoc host probes initially reproduced the shell-portability problem
already documented in the lifecycle notes: passing a compound `su -c` or
`run-as sh -c` command as flattened `adb shell` arguments caused a syntax or
false-status result. The corrected probes used one explicitly quoted remote
command string and passed. This did not contaminate the device run, but it is
another reason to keep post-stop verification inside the harness rather than
retyping nested shell commands during evidence collection.

## Next boundary

The result moves the high-value unknown from endpoint identity and ancillary
format toward read ownership and socket queue/wake behavior:

1. Add a device-capable `strace -ff` or equivalent syscall observer that covers
   every AHB process/thread, or add an exclusive-reader assertion around the
   Android control sockets.
2. At the first blocked ACK, record unread queue state (`FIONREAD` where
   supported) and the Android thread's exact wait stack without peeking SCM_RIGHTS
   in the normal path.
3. Only if the same connection, one reader, full send, empty queue, and blocked
   receive are proven together should the investigation escalate to AF_UNIX
   wake/queue behavior.

Do not mix this with the independent SurfaceControl correction for a previous
release-fence FD of `-1`, ring-count changes, or a one-socket protocol redesign.
Those remain separate hypotheses.
