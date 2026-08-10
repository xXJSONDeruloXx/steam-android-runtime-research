# Nova AHardwareBuffer read-queue result — 2026-08-09

Date: 2026-08-09

Run: `manual-20260809T004756Z-ahbqueue`

Profile: `manual-stream-read-queue`

Status: the reproducer reached the same Android ACK wait, but the diagnostic
receive timeout never returned during the bounded observation window. The
`FIONREAD` result was therefore not available. This is a valid transport
boundary, not evidence that the socket queue was empty or nonempty.

## Causal boundary

The run kept the original `SOCK_STREAM` transport, three-buffer ring,
AHardwareBuffer/SurfaceControl ownership loop, fullscreen 1280x960 output,
libei input path, and Gamescope fence generation unchanged. It used the
Android-only `FIONREAD` snapshot added after a negative ACK `recvmsg()` return.

The same frame ordering reproduced:

```text
Android:
frame=132 buffer=0 ack_received
frame=132 buffer=2 release_sent
frame=133 buffer=1 wait_ack
ack_wait_begin fd=99 inode=10055034 type=1 generation=1 cookie=84027 peer_pid=21036
ack_wait_probe result=0 revents=0x0
... no ack_wait_end and no recv_timeout_queue_bytes before stop ...

Gamescope:
frame=133 index=1 ack_send result=103 errno=0 msg_flags=0x0
    msg_controllen=24 cmsgs=1:1:20:aligned rights=1
frame=133 index=1 ack_sent
frame=134 index=2 ack_send result=103 errno=0 msg_flags=0x0
    msg_controllen=24 cmsgs=1:1:20:aligned rights=1
frame=134 index=2 ack_sent
frame=135 index=0 release_wait result=0 revents=0x0 errno=0
Android release message wait failed buffer 0
```

The Android `wait_ack` line was timestamped `20:49:29.714` in the device
log. The marker-driven observation continued through `00:51:07Z`, when it
ended with `marker_timeout=recv_timeout_queue`; no negative `recvmsg()` return
was logged. The source sets `SO_RCVTIMEO` to 15 seconds after each accepted
client, but the `setsockopt()` return and the effective socket timeout were not
recorded. Therefore this run establishes that the receive did not return in
the observed window, while leaving the timeout configuration itself as the
next diagnostic question.

The later Gamescope release timeout remains the ring's downstream consequence
of the missing Android ACK. The run does not change the earlier conclusion
that the ACK boundary precedes the release deadlock.

## Queue and thread evidence

No `recv_timeout_queue_bytes` record was produced, so there is no valid
`FIONREAD` value for this run. The probe must not be interpreted as
`FIONREAD=0`.

The captured ACK thread was Android PID 20626, TID 21005
(`pool-2-thread-1`). Its `/proc` snapshot reported `State: R`, `TracerPid: 0`,
and `Threads: 22`; `wchan` and the kernel stack were unavailable in the
captured environment. This is insufficient to distinguish a userspace
blocking wrapper from a kernel wait.

The Nova device does not have `strace` installed, so this run still does not
exclude another runtime reader with a device-wide syscall trace. The source
inspection remains unchanged: the AHB paths have the expected ACK and legacy
receive call sites, while the raw input socketpair is unrelated.

## UI correlation

The deterministic A-button transition was accepted by the live CDP target;
the final CDP artifact remained on the timezone route. The same-run X11
capture advanced independently of the Android surface, preserving the known
presentation-staleness separation from Steam/Xwayland state.

| Artifact | SHA-256 |
| --- | --- |
| Android baseline | `5df49721397143cd065893592f8c34f52097e3d1a34eacb1d7cbb3e7b5678531` |
| X11 baseline PPM | `6593207c938534a0f1a1288c5b31fbcd5e4e88df8657e3b9498ecb0b3d3d7b70` |
| Android after A | `e506e79ebbce1553149fc3e604ec4c149615bf42a0d17742e84b33c8c889ae73` |
| X11 after A PPM | `225b7c1fdee9ede53449c4ba608aa1f9f3c90f278cef9d72d78ed8d71573740f` |
| Android final | `19a8457a09b91aeabf82d4ee9dd66c064e49a38dc2cb670d8ec23a94077d5357` |
| X11 final PPM | `2da148b807fc71f3543cc892b60f9bb708daa19add8a9e3584d9c50a886c11cc` |
| CDP final JSON | `a73d1fc97e065592fb87f548abb350f953e01f02668d56cfdfd43b07f3a2a877` |

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
  `021b9f13a7cdb6f2c17c3c59d99a7638667af3509a764f669179ab2a5c0eabd4`
- Presentation: fullscreen 1280x960; GPU composition disabled
- Gamescope libei build: enabled; input emulation: enabled
- AHB/socket tracing: enabled
- Steam/Gamescope bounded timeouts: 900 seconds
- Preflight manifest:
  `android/nova-lab/build/runs/manual-20260809T004756Z-ahbqueue/device-gamescope-headless-ahb-preflight.txt`

Run-scoped logs, queue polling, thread snapshots, screenshots, X11 captures,
and reports are retained under:

`android/nova-lab/build/runs/manual-20260809T004756Z-ahbqueue/`

## Cleanup and methodology

The exact stop path and independent post-stop verifier both passed:

```text
nova_runtime_cleanup=pass
native_steam_runtime_cleanup=pass
native_steam_app_files_cleanup=pass
native_steam_ahb_trace_reset=pass
post_stop_report_sha256=d02b790bdebfa933d77dd4a3999618ab48509562c441cc010386e40fded2c8ca
post_stop_adb_forward=pass port=18083
post_stop_residual_processes=pass
post_stop_app_files=pass
post_stop_trace_state=pass
post_stop_verification=pass
```

## Next boundary

The next diagnostic must verify the timeout setup before interpreting queue
state. At each accepted client, log the result and conditional errno for
`setsockopt(SO_RCVTIMEO)`, then read back `SO_RCVTIMEO` with `getsockopt()` and
record the effective seconds/microseconds. Keep the stream transport, ring,
fence path, SurfaceControl behavior, and input sequence unchanged. If the
timeout is effective, add a separate bounded wait-state probe around the
blocking `recvmsg()`; if it is not, fix only the timeout setup/diagnostic
path. Do not combine this with a one-socket redesign, ring changes, or the
independent previous-release-fence `-1` correction.
