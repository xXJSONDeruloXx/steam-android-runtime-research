# Nova AHardwareBuffer socket-trace result — 2026-08-08

Date: 2026-08-08

Run: `manual-20260808T234314Z-ahbsockettrace`

Status: negative for a clean stream transport, but the diagnostic boundary is
now explicit. No ownership, ring, fence-policy, pacing, or presentation
change was stacked onto this run.

## Conclusion

The original `SOCK_STREAM` AHB control transport successfully exchanged
complete messages and valid ancillary fence descriptors for hundreds of frames.
Both sides reported stable socket identities, `type=1` (`SOCK_STREAM`), full
payload lengths, `rights=1`, and `msg_flags=0x0`.

The run then stopped at this edge:

- Android's last completed receive was `ack_recv frame=429 buffer=0`; it then
  remained at `ahb_double_buffer_trace frame=430 buffer=1 phase=wait_ack`.
- Gamescope successfully sent ACKs for frames 430 and 431, with 103-byte
  payloads and valid fence descriptors on stable socket inodes.
- Gamescope then waited on frame 432/index 0. Its release poll returned
  `result=0 revents=0x0 errno=0`; no malformed short message or ancillary-data
  truncation was reported.
- Android input remained focused on `MainActivity`, and the second A event was
  dispatched, but the CDP route stayed at timezone for the complete bounded
  60-second poll. The run was stopped at the traced handshake boundary.

This classifies the next investigation as “Gamescope ACK send completed while
the Android-side receive path did not produce a matching `ack_recv` record,”
not as stream record coalescing or missing fence ancillary data. The trace does
not by itself prove whether the Android `recvmsg` is blocked, whether a peer
wake is lost, or whether the app's buffer-state machine has stopped consuming
the socket; that distinction needs a separate app-side pre-receive/wait
experiment.

## Input and presentation correlation

The fresh CDP target was dynamically selected as the Steam loopback page at
`/routes/oobe/1/language`. Focus assertions before and after every input and
X11 capture reported the Nova `MainActivity`; `com.rp.settings` did not own
focus during the evidence pair.

The first Android A event (`keyevent 96`) advanced CDP to
`/routes/oobe/1/timezone` at `2026-08-08T23:47:12Z`. The Android and dynamically
selected 1280x960 X11 window captures both showed the timezone page. The
second A event was dispatched at `2026-08-08T23:48:18Z`, but CDP remained on
timezone through the 60-second bounded poll, so no network-route claim was
made.

The language captures also preserve the previously noted font-coverage issue:
several language entries render as missing-glyph rectangles. This remains a
documented follow-up in `docs/10-ahb-and-harness/33-nova-steam-font-coverage-open-question.md`,
not a variable in the current transport experiment.

| State | Artifact | SHA-256 |
| --- | --- | --- |
| Initial Android | `android-baseline.png` | `34f06ee01f77c6c840bd8d065162151e2529b5206ce29602ec1be12f2ee6d359` |
| Initial X11 | `x11-baseline.png` | `2ec96fbda459ac82229152a06992b0d155087cc5e308b49e686193288eff9898` |
| Android after language A | `android-after-language-timezone.png` | `286902723a7e8f059b99fd70ed9a4c86512f100ce3d25c8c6a37d7ea76637cd3` |
| X11 after language A | `x11-timezone.png` | `b9bf1a29091751fdea705bfd6623c88bf2d5cae6c9c964ee0683364fc1975420` |

The complete same-run CDP polls, focus assertions, X11 tree/capture output,
live filtered logcat, and report tail are retained under:

`android/nova-lab/build/runs/manual-20260808T234314Z-ahbsockettrace/`

## Run provenance

- Gamescope binary: `android/nova-lab/build/gamescope-headless-build-stream-sockettrace-v2/src/gamescope`
- Gamescope SHA-256: `8106a412f1b99fed371c71b5b0bc4a768130cf6fb6f5513e69b3cc281008c22c`
- Gamescope source tree: `android/nova-lab/build/gamescope-headless-source-ten`
- Gamescope source commit: `fb9f84ee247a1f02b1a132da60e94585db84bf61`
- Source status SHA-256: `e2ee88158467e2b5255510f5829a20e36a98b57d9b57b6f280865ae954016ed4`
- Source diff SHA-256: `3b9d55194b760ad1621971ad773526269ac71eb923ba52cb6ef10f55ba8e1f12`
- Source submodule SHA-256: `ffb0e5c788894ee2a5498ccffe0fcabd659805200bc9bed025ce78e02cc0f8b0`
- Gamescope libei: enabled; input emulation: enabled
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256: `65d91ccee05abb7c44da2c9ca30975e4a0719d6b84d1666a598028a1c359955b`
- Presentation: fullscreen 1280x960; GPU composition disabled
- AHB and socket tracing: enabled
- X11 helper SHA-256: `a8971824bfcb812139bcc7451a1ab2c262b4a2af0ff9d462e25206a3efb4b017`
- Preflight manifest SHA-256: `639f2c838b9dab7b37af327190bcca0e24cc30cddf9720db412021c165c086d1`

The metadata and preflight manifest record the same tuple and both cleanup
attempts. The preflight passed before Activity launch.

## Boundary evidence

Gamescope completed valid stream operations immediately before the stall:

```text
android_ahb_socket_trace op=ack_send frame=430 index=1 fd=16 inode=9775795 type=1 result=103 errno=0 msg_flags=0x0 rights=1 fence_fd=157
android_ahb_socket_trace op=ack_send frame=431 index=2 fd=17 inode=9776548 type=1 result=103 errno=0 msg_flags=0x0 rights=1 fence_fd=160
android_ahb_socket_poll op=release_wait frame=432 index=0 fd=15 inode=9776546 type=1 result=0 revents=0x0 errno=0
Android release message wait failed buffer 0 poll=0 revents=0x0 errno=0
```

Android's live log ends at the corresponding wait boundary without a malformed
receive:

```text
ahb_socket_trace op=ack_recv frame=429 buffer=0 fd=108 inode=9775632 type=1 result=103 errno=0 msg_flags=0x0 rights=1 fence_fd=5
ahb_double_buffer_trace frame=429 buffer=0 phase=surface_present bytes=-1 fence=1 status=0
ahb_socket_trace op=release_send frame=429 buffer=2 fd=100 inode=9776547 type=1 result=17 errno=0 msg_flags=0x0 rights=1 fence_fd=118
ahb_double_buffer_trace frame=430 buffer=1 phase=wait_ack bytes=-1 fence=0 status=0
```

The full Gamescope report contains the repeated frame-432 timeout after the
first timeout. The filtered live Android trace contains the second key-event
dispatch and proves that the CDP timeout was not inferred from a stale route.

## Cleanup

The explicit stop passed:

```text
nova_runtime_cleanup=pass ... remaining=
native_steam_runtime_cleanup=pass
native_steam_app_files_cleanup=pass
native_steam_ahb_trace_reset=pass
```

Post-stop verification independently found no matching Nova process, no stale
app-owned bridge/report file, and both trace properties plus rootfs trace files
at zero.

## Next bounded gate

Do not change the socket type, ring ownership, or fence policy based on this
result. Add one diagnostic-only app-side receive-wait trace that records the
pre-`recvmsg` state and a bounded socket-readiness probe without changing the
existing blocking behavior. The goal is to distinguish “Gamescope sent and
the Android receive call is blocked” from “the app stopped entering the receive
path.” Publish that experiment card before the next device run.
