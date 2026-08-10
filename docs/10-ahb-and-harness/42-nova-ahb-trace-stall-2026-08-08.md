# Nova AHardwareBuffer trace: timezone-to-network stall

Date: 2026-08-08

Run: `legacy-20260808T225322Z-ahbtrace`

## Run identity

- Gamescope: `android/nova-lab/build/gamescope-headless-build-trace/src/gamescope`
- Gamescope SHA-256: `c3eb79cefb1aba96f25c80b0f2ae73038b39fc1cbb20f12885b8e9e444b12ed2`
- Gamescope source: `android/nova-lab/build/gamescope-headless-source-seven`
- Gamescope source commit: `fb9f84ee247a1f02b1a132da60e94585db84bf61`
- Gamescope libei build: enabled
- Gamescope input emulation: enabled
- Presentation: fullscreen 1280x960, GPU composition disabled
- AHB trace: enabled
- X11 helper SHA-256: `a8971824bfcb812139bcc7451a1ab2c262b4a2af0ff9d462e25206a3efb4b017`
- Run artifacts: `android/nova-lab/build/legacy-20260808T225322Z-ahbtrace/`

The Gamescope metadata is complete. The current host APK artifact after the
launch hashes to
`37217bc94c93becd7d210c5767a3a1e78940403b69c4ce303e5fdb830b0f85c3`, but the
run metadata does not record an APK hash. The next harness checkpoint must add
that field before install; this run cannot prove the exact installed APK from
its metadata alone.

## Input and presentation correlation

At readiness, CDP reported `/routes/oobe/1/language` and
`dumpsys input` reported the Nova `MainActivity` as the focused window. The
dynamic X11 tree found the mapped Steam Big Picture window at `0x1e0003b`,
1280x960.

The first `KEYCODE_BUTTON_A` event (`adb shell input keyevent 96`) was logged
by the app as `android_input_key_forwarded=pass` and dispatched. The CDP route
changed from language to timezone during the bounded route poll. The Android
capture and the same-run X11 window capture both showed the timezone page.

The second event was sent only after another focus check, which again reported
`MainActivity`. The event was forwarded and dispatched at the app log timestamp
`18:55:48.727`, but CDP remained on `/routes/oobe/1/timezone` for the complete
45-second poll. The overlay guard was active throughout the manual session.

The post-stall Android screenshot SHA-256 was
`7ad4cb72607ee4161c2d70d1f350cf5b7e00b789decaa9501a05a6efd121bedf`; the
same-run X11 timezone capture SHA-256 was
`3c2021e39d1af595c53e5456afc5249e6d15273c778a9c8c8bf39dc7bcc43f89`.
Visual comparison showed the same timezone page and selected Pacific row in
both captures. The X11 window remained mapped at 1280x960. This rules out a
focus loss and a persistent X11-versus-Android presentation mismatch as the
cause of this transition failure.

## Trace boundary

The app-side trace ended at:

```text
ahb_double_buffer_trace frame=245 buffer=2 phase=wait_ack
```

There was no later `ack_received` record for that wait. In the same run,
Gamescope completed frames 245 and 246, including `ack_sent`, and then reached:

```text
android_ahb_trace frame=247 index=1 submitted=1 phase=wait_release
Android release message wait failed buffer 1 poll=0 revents=0x0 errno=11
Android output release fence wait failed for buffer 1
```

The release-wait error repeated for buffer 1. The paired traces show a
cross-process handshake stall: the Android side is blocked waiting for an ACK
while Gamescope is blocked waiting for the release message for the next ring
slot. The evidence does not yet identify whether the ACK was lost, delayed,
or consumed with an incompatible message boundary, so no ownership or ring
algorithm change is justified yet.

## Cleanup and next gate

The exact stop path returned:

```text
nova_runtime_cleanup=pass ... attempts=2 ... remaining=
native_steam_runtime_cleanup=pass
native_steam_app_files_cleanup=pass
native_steam_ahb_trace_reset=pass
```

Next work, in order:

1. Record the APK SHA-256 in the run metadata before install.
2. Inspect and instrument the ACK/release socket framing and per-buffer
   sequence at both endpoints, using the fresh frame-245-to-247 reproducer.
3. Repeat the same two-input experiment after one transport-only change, with
   a fresh run identity and no source edits during the live run.

No protocol or ownership code was changed in this checkpoint.

The follow-up harness fix now records `nova_apk` and
`nova_apk_sha256` in every AHB run metadata file and makes the provenance gate
require the APK hash alongside the Gamescope identity.
