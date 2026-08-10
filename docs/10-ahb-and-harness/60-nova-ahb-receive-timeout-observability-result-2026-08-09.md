# Nova AHardwareBuffer receive-timeout observability result — 2026-08-09

Date: 2026-08-09

Run: `manual-20260809T005725Z-ahbtimeout`

Profile: `manual-stream-timeout-observability`

Status: the Android socket timeout is successfully installed and reads back as
15 seconds on all three AHB connections. The reproducible deadlock still
survives it: Android remains in the blocking ACK `recvmsg()` beyond the
configured timeout, while Gamescope completes the matching ACK send and later
times out waiting for the wrapped release message.

## Timeout setup result

The new diagnostic logged one setup record per accepted AHB client:

```text
buffer=0 requested=15.000000s set_result=0 set_errno=0
    get_result=0 get_errno=0 effective=15.000000s effective_len=16
buffer=1 requested=15.000000s set_result=0 set_errno=0
    get_result=0 get_errno=0 effective=15.000000s effective_len=16
buffer=2 requested=15.000000s set_result=0 set_errno=0
    get_result=0 get_errno=0 effective=15.000000s effective_len=16
```

This removes the ignored `setsockopt()` call and option-rounding hypothesis
from the front of the current investigation. It does not explain why the
subsequent blocking `recvmsg()` did not return.

## Causal boundary

The run preserved the original `SOCK_STREAM` transport, three-buffer ring,
AHardwareBuffer/SurfaceControl ownership loop, fullscreen 1280x960 output,
libei input path, and Gamescope fence generation. The final sequence was:

```text
Android:
frame=270 buffer=0 ack_received
frame=271 buffer=1 ack_received
frame=272 buffer=2 ack_received
frame=273 buffer=0 wait_ack
ack_wait_begin fd=108 inode=10161218 type=1 generation=1 cookie=84183 peer_pid=29920
ack_wait_probe result=0 revents=0x0
... no ack_wait_end, ack_recv, or recv_timeout_queue_bytes ...

Gamescope:
frame=273 index=0 ack_send result=103 errno=0 msg_flags=0x0
    msg_controllen=24 cmsgs=1:1:20:aligned rights=1
frame=273 index=0 ack_sent
frame=274 index=1 ack_send result=103 errno=0 msg_flags=0x0
    msg_controllen=24 cmsgs=1:1:20:aligned rights=1
frame=274 index=1 ack_sent
frame=275 index=2 release_wait result=0 revents=0x0 errno=0
Android release message wait failed buffer 2
Android output release fence wait failed for buffer 2
```

The unchanged Android frame-273 wait marker was observed for a further 30
seconds by the marker-driven poll and was still the terminal Android event in
the final log. The `FIONREAD` helper only runs after a negative `recvmsg()`
return, so it correctly produced no queue record in this run; the absence of a
queue value must not be interpreted as an empty queue.

The socket identities remained stable through the boundary:

| Buffer | Android endpoint | Gamescope endpoint | Peer relationship |
| --- | --- | --- | --- |
| 0 | fd 108, inode 10161218, cookie 84183 | fd 15, inode 10160041, cookie 79222 | Android peer PID 29920; Gamescope peer PID 29512 |
| 1 | fd 99, inode 10161281, cookie 79223 | fd 16, inode 10161282, cookie 84184 | Android peer PID 29920; Gamescope peer PID 29512 |
| 2 | fd 100, inode 10160042, cookie 84185 | fd 17, inode 10160043, cookie 79224 | Android peer PID 29920; Gamescope peer PID 29512 |

The local socket cookies differ as expected for the two endpoint objects; the
slot paths, peer credentials, generation 1, and stable endpoint identities
continue to identify the intended pairs. The complete frame-273 send therefore
still precedes the Android-side missing ACK return in this run.

## Thread and reader evidence

The Android ACK thread was PID 29512, TID 29886 (`pool-2-thread-1`). Its
captured `/proc` state reported `State: R`, `TracerPid: 0`, `Threads: 23`, and
an empty/zero `wchan` and kernel stack in the available snapshot. This is not a
valid wait-stack proof: the device did not provide `strace`, and the snapshot
cannot distinguish a userspace wrapper, a transient running state, or a
kernel-side socket wait.

The run therefore still does not exclude a second runtime reader with a
device-wide syscall trace. It does, however, exclude a simple timeout-option
setup failure and reproduces the same endpoint/send/receive ordering as the
earlier transport-observability run.

## UI and presentation correlation

The baseline CDP target was
`/routes/oobe/1/language`. The injected Android A-button event was logged as
`keycode=96` down/up and `android_input_key_forwarded=pass`; the final CDP
target was `/routes/oobe/1/timezone`. This run makes no network-route claim.
The same-run X11 window remained mapped at 1280x960, and its capture changed
after the input while the Android final image matched the post-A capture.

| Artifact | SHA-256 |
| --- | --- |
| Android baseline | `28f26d6e33d5175eef35256d81b13ea7ea50a6eeccaf25b175858af8e7fed551` |
| X11 baseline PPM | `84a6949483f4eaea651c3e2666309b34e16592455c4137f39aa286c88beabb56` |
| Android after A | `e8796327a0730baeb33e6d0710fb63c1e6d0fb34377a3991d952507279265bee` |
| X11 after A PPM | `876f1f068dd6867cdc139c0ea13350f04eff79fe1a1d60d663e4b24c1d726131` |
| Android final | `e8796327a0730baeb33e6d0710fb63c1e6d0fb34377a3991d952507279265bee` |
| X11 final PPM | `d56bc85bb7557b507e3454e55a657e4dcb80ac611527fd4586fa3ea572e6958b` |
| CDP baseline JSON | `3262b708424583c84bf83984a2dfd1ed2072ed9e3a37e4f1663fba95b520768e` |
| CDP after A/final JSON | `e2166cfeb65a8ba0312562eb82439ed3ee29379d83279f0a88f91303d337464a` |

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
- APK SHA-256 recorded by the run manifest:
  `2a3f42aa72bcef23bc38d567ecea44242eb4203a99cb8c0f58f28ac1fb87f87a`
- Presentation: fullscreen 1280x960; GPU composition disabled
- Gamescope libei build: enabled; input emulation: enabled
- AHB/socket tracing: enabled
- Steam/Gamescope bounded timeouts: 900 seconds
- Preflight manifest:
  `android/nova-lab/build/runs/manual-20260809T005725Z-ahbtimeout/device-gamescope-headless-ahb-preflight.txt`

Run-scoped logs, marker polling, thread/process snapshots, screenshots, X11
captures, and reports are retained under:

`android/nova-lab/build/runs/manual-20260809T005725Z-ahbtimeout/`

## Cleanup and methodology

The exact stop path required two cleanup passes for the runtime process tree;
the second pass was clean, and the independent post-stop verifier passed:

```text
nova_runtime_cleanup=pass
native_steam_runtime_cleanup=pass
native_steam_app_files_cleanup=pass
native_steam_ahb_trace_reset=pass
post_stop_report_sha256=e6abd96877eb67ac4457769b4f9ecaf0d532c9671163cc2f76e59ebce24c579d
post_stop_adb_forward=pass port=18084
post_stop_residual_processes=pass
post_stop_app_files=pass
post_stop_trace_state=pass
post_stop_verification=pass
```

## Next boundary

The receive-timeout configuration is no longer the leading unknown. The next
diagnostic should observe the blocked socket while the receive call is still
active, or replace only that blocking boundary with an explicitly timed
`poll()`/`recvmsg()` diagnostic so queue state can be collected at a known
deadline. It must preserve the same stream sockets, frame identity, ring,
fences, SurfaceControl path, and input sequence. A device-capable syscall
observer remains the preferred way to exclude another reader; the Nova image
currently has no `strace`.

Do not combine this with a one-socket redesign, ring changes, reconnect logic,
or the independent SurfaceControl previous-release-fence `-1` correction.
