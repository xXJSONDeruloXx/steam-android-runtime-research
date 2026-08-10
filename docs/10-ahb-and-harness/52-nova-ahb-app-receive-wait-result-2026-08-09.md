# Nova AHardwareBuffer app receive-wait result — 2026-08-09

Date: 2026-08-09

Run: `manual-20260808T235856Z-ahbreceivewait`

Profile: `manual-stream-receive-wait`

Status: the diagnostic reproduces the Android-side ACK receive boundary. It
does not yet identify whether the cause is a replaced/wrong connection, a
competing reader, a send/receive lifecycle race, or the ancillary-data path.

## Conclusion

This run strengthens the existing causal ordering:

- Android completed `ack_recv` through frame **251**, then entered
  `ack_wait_begin` for frame **252**, buffer **0**. Its zero-timeout readiness
  probe returned `result=0 revents=0x0`, and there was no later
  `ack_wait_end`/`ack_recv` for that wait before the run was stopped.
- Gamescope completed full 103-byte ACK sends for frame **252**, index **0**,
  and frame **253**, index **1**, with one transferred fence descriptor for
  each. It then reached frame **254**, index **2**, and repeatedly timed out
  waiting for Android's release message.
- The Android process and SurfaceFlinger layer remained alive. The visible
  Android and upstream X11 captures remained on the timezone page.

The most useful paired excerpt is therefore:

```text
Android:
ahb_double_buffer_trace frame=252 buffer=0 phase=wait_ack
ahb_socket_trace op=ack_wait_begin frame=252 buffer=0 fd=108 inode=9860055 type=1
ahb_socket_poll op=ack_wait_probe frame=252 buffer=0 fd=108 inode=9860055 type=1 result=0 revents=0x0 errno=0
... no ack_wait_end or ack_recv for frame 252 ...

Gamescope:
android_ahb_socket_trace op=ack_send frame=252 index=0 fd=15 inode=9860056 type=1 result=103 rights=1
android_ahb_socket_trace op=ack_send frame=253 index=1 fd=16 inode=9860057 type=1 result=103 rights=1
android_ahb_socket_poll op=release_wait frame=254 index=2 fd=17 inode=9860541 type=1 result=0 revents=0x0 errno=0
Android release message wait failed buffer 2 poll=0 revents=0x0 errno=0
```

This establishes that Android entered the blocking receive path before the
three-buffer cycle closed on Gamescope's release wait. The zero-timeout probe
is only a readiness snapshot; it does not prove that the frame-252 ACK had
already been queued at the instant of the probe. The run consequently does
not claim a kernel socket-delivery defect.

## Socket identity evidence

The per-buffer endpoint identities were stable through the boundary:

| Buffer | Android receive endpoint | Gamescope endpoint | Type | ACK result |
| --- | --- | --- | --- | --- |
| 0 | fd 108, inode 9860055, app path `.0` | fd 15, inode 9860056 | `SOCK_STREAM` | 103 bytes, one FD |
| 1 | fd 99, inode 9860540, app path `.1` | fd 16, inode 9860057 | `SOCK_STREAM` | 103 bytes, one FD |
| 2 | fd 100, inode 9860058, app path `.2` | fd 17, inode 9860541 | `SOCK_STREAM` | 103 bytes, one FD |

`/proc/net/unix` and the saved Android FD listing confirm these live endpoint
inodes and the expected three app-owned socket paths. They do not expose a
peer cookie or connection generation, and the current trace does not record
`SO_PEERCRED`, `getsockname`, or `getpeername`. Thus the evidence shows stable
slot-to-endpoint mapping, but does not yet prove that each Gamescope endpoint
is the intended peer of the Android endpoint or exclude a second reader.

The existing trace also reports `msg_flags=0x0` and `rights=1` on every
complete ACK/release exchange before the boundary. It does not yet record
`msg_controllen`, each `cmsghdr`, `MSG_CTRUNC`/`MSG_TRUNC`, or use
`MSG_CMSG_CLOEXEC`; those remain the next diagnostic hardening target.

## Input and presentation correlation

The initial same-run captures were:

| State | Artifact | SHA-256 |
| --- | --- | --- |
| Initial Android | `android-baseline.png` | `71fa6e73ba49b6e9072ab472f10e85219dd9c59a9eec6864f2534b6ac4bb05e5` |
| Initial X11 | `x11-baseline.png` | `d4dd24e4f034ddcb9d68b05cdc36ae3d573c7d4c7f7b85de9310d1b489e7be67` |
| Android after language → timezone | `android-after-language-timezone.png` | `6d2a852f1f8eca9023fc5bf429cee486f56eb3e0d53dddd7fd67a5a814a0d069` |
| X11 after language → timezone | `x11-timezone.png` | `9018ada2c668c133cec6454431879fb0ee29c82c5cb6e4100962a604c58de463` |
| Android after second A attempt | `android-post-timezone-input.png` | `797efce019073b164fd6d5bc2cbd8468f7fb2b089f95cd21c245e3bae747aae4` |
| X11 after second A attempt | `x11-post-timezone-input.png` | `1ff91e00fae86e33817736b898f9a65fd81d9b8dbf5190dabdc510c4b437ad01` |

The first A event advanced CDP from language to timezone, and both Android and
the dynamically rediscovered 1280x960 X11 window showed timezone. The second
`adb shell input keyevent 96` was issued at `2026-08-09T00:04:29Z`; focus
before and after remained the Nova `MainActivity`. A bounded 45-poll CDP
check through `2026-08-09T00:05:14Z` remained at
`/routes/oobe/1/timezone`, so this run makes no network-route claim. The two
post-input captures agree on the timezone page.

The input result is kept separate from the transport conclusion. It confirms
that focus was not owned by `com.rp.settings`, but it does not establish why
the second Steam UI action did not change the route.

## Provenance

- Gamescope binary:
  `android/nova-lab/build/gamescope-headless-build-stream-sockettrace-v2/src/gamescope`
- Gamescope SHA-256:
  `8106a412f1b99fed371c71b5b0bc4a768130cf6fb6f5513e69b3cc281008c22c`
- Gamescope source tree:
  `android/nova-lab/build/gamescope-headless-source-ten`
- Gamescope source commit: `fb9f84ee247a1f02b1a132da60e94585db84bf61`
- Gamescope source status SHA-256:
  `e2ee88158467e2b5255510f5829a20e36a98b57d9b57b6f280865ae954016ed4`
- Gamescope source diff SHA-256:
  `3b9d55194b760ad1621971ad773526269ac71eb923ba52cb6ef10f55ba8e1f12`
- Gamescope source submodules SHA-256:
  `ffb0e5c788894ee2a5498ccffe0fcabd659805200bc9bed025ce78e02cc0f8b0`
- APK:
  `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256:
  `7a9ceb0150bb59e4840e68ed389881de58796d190a3c4b0a5b8c761edf6e2862`
- X11 capture helper SHA-256:
  `a8971824bfcb812139bcc7451a1ab2c262b4a2af0ff9d462e25206a3efb4b017`
- Presentation: fullscreen 1280x960; GPU composition disabled
- Gamescope libei build: enabled; input emulation: enabled
- AHB and socket tracing: enabled
- Preflight manifest:
  `android/nova-lab/build/runs/manual-20260808T235856Z-ahbreceivewait/device-gamescope-headless-ahb-preflight.txt`

The full run-scoped CDP polls, focus assertions, X11 tree/selection/captures,
filtered logcat, complete Gamescope report, socket listings, and cleanup
verification are retained under:

`android/nova-lab/build/runs/manual-20260808T235856Z-ahbreceivewait/`

## Cleanup

The explicit stop and the independent post-stop checks passed:

```text
nova_runtime_cleanup=pass
native_steam_runtime_cleanup=pass
native_steam_app_files_cleanup=pass
native_steam_ahb_trace_reset=pass
debug.nova.ahb_trace=0
debug.nova.ahb_socket_trace=0
ahb-trace=0
ahb-socket-trace=0
post_stop_residual_processes=pass
post_stop_app_files=pass
```

One initial ad-hoc app-file verification command failed because nested shell
quoting produced a remote syntax error; the retry then hit a host-side zsh
collision using the read-only variable name `status`. Neither failure was a
device residual or a cleanup failure. The final check used one explicitly
quoted remote command and `check_status`, and passed. This is recorded as a
methodology defect: future acceptance runs should rely on the harness's
run-scoped post-stop checker instead of hand-written nested shell checks.

## Next diagnostic boundary

Before another device run, publish a diagnostic-only transport observability
change that records, on both endpoints:

- connection generation, `fstat` inode, `SO_TYPE`, local/peer addresses,
  `SO_PEERCRED`, and `SO_COOKIE` where available;
- exact `sendmsg`/`recvmsg` return values and `errno` only when the syscall
  returns negative;
- `msg_flags`, `msg_controllen`, every relevant `cmsghdr`, and SCM_RIGHTS
  count/FD;
- `MSG_CTRUNC`/`MSG_TRUNC` as hard protocol errors; and
- `MSG_CMSG_CLOEXEC` on received SCM_RIGHTS descriptors.

Use the original `SOCK_STREAM` configuration and do not change ring count,
SurfaceControl pacing, fence generation, or input behavior in that run. If
the endpoint pair and syscall results are clean, inspect all readers with
`strace -ff` or an equivalent device trace before changing SurfaceControl.

The separate SurfaceControl correction for a previous release-fence FD of
`-1` remains valid but is intentionally not mixed into this diagnostic result;
Android defines `-1` as “already released,” not as a missing-fence failure.
