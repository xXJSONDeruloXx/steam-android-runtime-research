# Nova AudioTrack short-write drain result — 2026-08-10

Status: the receiver correction passed a naturally closed stream; a second
stream was interrupted by bounded teardown. No short or zero writes were
observed. Latency remains a separate issue.

## Run identity and provenance

- Experiment: `nova-audio-short-write-drain-20260810T145829Z`
- Launcher session: `20260810T145902Z-26095`
- Device: Retroid Pocket Nova, Android 13, adb serial `675a2365`, `kalama`
- Source commit: `1a3fd49`
- APK SHA-256: `baaaa1e3341024ec111f12a970a24453df1f116f94884160dc92b5b902a8503e`
- Preload SHA-256: `741943aead509f6179811633d018d8ad8246bedd27d3641dab9b576435358143`
- Profile: same hardware launcher, CEF-disabled, Steam `gamepadui`, software
  client GL, CEF environment split, and stretched `1280x800` X11 display
- Audio mode: `run_audio_bridge_steam=true`, port `29100`
- Host evidence: `android/nova-lab/build/runs/nova-audio-short-write-drain-20260810T145829Z/`

## Completed stream result

The first Steam-side audio connection closed naturally before teardown. Its
frame totals matched exactly:

```text
C preload attempted: 1568768 frames
C preload sent:      1568768 frames
Android accepted:    1568768 frames
short_writes=0
zero_writes=0
send_failures=0
```

The Android log recorded:

```text
audio_bridge_stream=closed frames=1568768 bytes=6275072 short_writes=0 zero_writes=0
AudioTrack: stop ... 1568768 frames delivered
```

This is a clean receiver-accounting pass for a complete stream. The updated
loop drains the remainder after a short positive `AudioTrack.write` instead of
discarding it.

## Teardown boundary

A second Steam connection opened and continued producing PCM when the bounded
session was stopped. The preload had logged `3424256` frames for that second
connection when teardown interrupted it; Android's final `AudioTrack.stop`
reported `2818568` frames delivered. That difference is in-flight data at
forced teardown, not evidence of a short write. The run therefore does not
claim whole-session equality, only equality for the naturally closed stream.

The active track retained the existing `7688`-frame client buffer and about
`268 ms` of AudioFlinger-reported track latency. The code change did not alter
that buffering, so the user's delayed UI-sound observation remains open.

The captured Steam surface was healthy and showed the Geometry Wars library
page. No physical or synthetic input was used. The exact cleanup passed after
two process-snapshot attempts, with `nova_x11_cleanup=pass`,
`nova_runtime_cleanup=pass`, and no matching Nova process remaining.

## Next experiment

The short-write correction is now pushed. The next isolated change should
reduce only the Android `AudioTrack` buffer from the current
`max(minBuffer * 2, 16384)` to the device's minimum accepted buffer. Keep the
write-drain loop and all Steam/display flags unchanged, then compare the
AudioFlinger frame count/latency and operator-perceived delay. Do not combine
that buffer change with a new Steam device-discovery or capture endpoint.
