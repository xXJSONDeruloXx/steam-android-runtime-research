# Nova AHardwareBuffer seqpacket experiment result

Date: 2026-08-08

Run: `legacy-20260808T231050Z-ahbseqpacket`

Status: negative for the seqpacket-only fix. The input route advanced through
the network page upstream, but the Android presentation stayed on the prior
timezone frame and the same release-wait/ACK stall recurred. No ownership or
ring change was made.

## Conclusion

The experiment changed the AHB control sockets on both endpoints from
`SOCK_STREAM` to `SOCK_SEQPACKET`. It did not make the presentation path
continue. Gamescope still blocked waiting for a release message and the app
then stopped producing ACK progress; the boundary moved earlier in this run
to frame 168 / buffer 0 rather than the prior stream run's frame 247 / buffer
1.

This does not support “stream record coalescing alone is the fix.” Because the
failure boundary moved, it is not evidence that a particular buffer or frame
is intrinsically bad, and it does not identify whether the remaining fault is
message delivery, fence/control-FD handling, socket lifecycle, or ring
ownership. The next experiment should instrument those return values and
descriptor identities before changing ownership or pacing.

## Run identity and provenance

- Artifact directory:
  `android/nova-lab/build/legacy-20260808T231050Z-ahbseqpacket/`
- Gamescope binary:
  `android/nova-lab/build/gamescope-headless-build-trace-seqpacket/src/gamescope`
- Gamescope SHA-256:
  `04d81413b0dc136450346b7571768a0c08910136cf53268e629dc56e45d09c64`
- Gamescope source tree:
  `android/nova-lab/build/gamescope-headless-source-eight`
- Gamescope source commit:
  `fb9f84ee247a1f02b1a132da60e94585db84bf61`
- Source worktree state: dirty by design because the experiment patch was
  applied; status SHA-256 `ec1bc363967af61820e36492ea5fe322c40bd9c924fbdd22a36c0724c78a172f`.
- Source diff SHA-256:
  `80537d642f49a54ebf831b0b03ae9a997aece6add5b5b56e479e7c0db80baef9`
- Source submodule/dependency state SHA-256:
  `ffb0e5c788894ee2a5498ccffe0fcabd659805200bc9bed025ce78e02cc0f8b0`
- Installed APK:
  `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256:
  `4c2b4f200a15d12f66d6288010f8782a6c0433cd3ed796ed617d95ec1ca19d5a`
- Gamescope libei build: enabled
- Input emulation: enabled
- Presentation: fullscreen 1280x960, GPU composition disabled
- AHB trace: enabled

The metadata is in
`device-gamescope-headless-ahb-metadata.txt` in the run directory. It now
contains the APK and dirty-source digests required by the harness gate.

## Input and presentation correlation

The fresh baseline CDP target was `/routes/oobe/1/language`. The focus check
immediately before the first A event reported the Nova `MainActivity`. The
X11 helper rediscovered the mapped Steam window as `0x240003b`, 1280x960, for
each capture; it was not assumed from a prior run.

The first `adb shell input keyevent 96` was forwarded and dispatched by the
Android app. CDP advanced to `/routes/oobe/1/timezone` at
`2026-08-08T23:12:42Z`. The Android timezone capture and same-run X11
timezone capture showed the same page.

After a new focus check again reported `MainActivity`, the second A event was
sent. CDP advanced to `/routes/oobe/1/network` at
`2026-08-08T23:13:25Z`. The X11 capture showed the network page, but the
Android capture still showed the timezone page. This is an upstream-state to
Android-presentation divergence, not an input-focus failure.

The relevant capture hashes are:

| State | Capture | SHA-256 |
| --- | --- | --- |
| Initial language | `android-baseline.png` | `83072c899f7d7a2886c630aba06f79bc891eed5fda8947564e3100b182d587ec` |
| Android after first A | `android-after-language-timezone.png` | `ffbd9942546ea26b0a792de50766c5c42d0f50314aa32b6092a04f3a9a52c133` |
| X11 timezone | `x11-timezone.png` | `1e6f01430d316c758bb2f5fe3f8af84e134397a037a0b370738e3717994c7924` |
| Android after second A | `android-after-timezone-network.png` | `a2b2b7f932da19792f608e36ccedcacebebc11f92627273e460ed48e425bdad5` |
| X11 network | `x11-network.png` | `40b69fea7d7ed251a87a04ddf12c14cf2af22af724b6144055e17fc21a1842a2` |

The X11 capture log records `nova_x11_capture=pass` at 1280x960 for the
network window. The Android and X11 images are both 1280x960; their status-bar
clock text is not used as a route identity because the captures occur at
different times.

## AHB trace boundary

Before the stall, the Android trace continued through ACKs and releases. Its
last useful progression was:

```text
ahb_double_buffer_trace frame=165 buffer=0 phase=surface_present ...
ahb_double_buffer_trace frame=165 buffer=2 phase=release_sent ...
ahb_double_buffer_trace frame=166 buffer=1 phase=wait_ack ...
```

Gamescope completed frames 165 through 167, including `release_message`,
`release_complete`, and `ack_sent`. It then reached:

```text
android_ahb_trace frame=168 index=0 submitted=1 phase=wait_release
Android release message wait failed buffer 0 poll=0 revents=0x0 errno=11
Android output release fence wait failed for buffer 0
```

The release-wait error repeated for buffer 0 until the deliberate stop. There
was no later Android `ack_received` record after the frame-166 wait, and no
later complete Gamescope release cycle. The full report is
`device-gamescope-headless-ahb-report.txt`; the filtered live Android trace is
`logcat-trace-network-live.txt` in the run directory.

## Cleanup

The explicit stop path returned all required pass markers:

```text
nova_runtime_cleanup=pass ... remaining=
native_steam_runtime_cleanup=pass
native_steam_app_files_cleanup=pass
native_steam_ahb_trace_reset=pass
```

The nested report also recorded `headless_ahb_runtime_cleanup=pass` and
`nova_app_runtime_files_cleanup=pass`. The later Xwayland restart messages
are teardown output after the intentional process stop, not evidence from a
new run.

## Next bounded gate

Keep the seqpacket result as a negative transport checkpoint and do not stack
an ownership change on top of it. Before the next device run, add one
diagnostic-only socket experiment that records, at both endpoints, the
`sendmsg`/`recvmsg` return value, payload length, ancillary-message count,
received fence FD, buffer/frame sequence, socket inode/connection identity,
and `poll` result/errno. Preserve the existing ring, fence, and ownership
algorithm. Write that experiment card first, then run a fresh stream baseline
with the same 1280x960 profile and exact cleanup/provenance gate.
