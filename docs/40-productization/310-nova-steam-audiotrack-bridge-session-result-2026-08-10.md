# Nova Steam AudioTrack bridge session result — 2026-08-10

Status: audible playback passed through the Android sink, but the session had
user-visible latency and Steam's Audio Settings still reported no input or
output devices. The bridge remains opt-in.

## Run identity and provenance

- Experiment: `nova-audio-settings-bridge-20260810T145029Z`
- Launcher session: `20260810T145054Z-22813`
- Device: Retroid Pocket Nova, Android 13, adb serial `675a2365`, `kalama`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256: `7f94e8bc85717147c2c62b4438fae26a826d1132cbbec4e103c9ddad79b84229`
- Source state: `574d94c`
- Profile: hardware launcher path, CEF GPU disabled, Steam `gamepadui`,
  software Mesa client rendering, CEF environment split, X11 stretch
  `1280x800` on the `1280x960` Android surface
- Audio mode: `run_audio_bridge_steam=true`, loopback port `29100`
- Host evidence: `android/nova-lab/build/runs/nova-audio-settings-bridge-20260810T145029Z/`

The launcher recorded `nova_launcher_audio_bridge=1`, listener readiness before
the root-side client, `nova_launcher_ready=pass`, and a Steam-side preload
containing `libnova-alsa-audiotrack-bridge.so`.

## What worked

The rootfs ALSA preload connected to the Android service twice and forwarded
PCM without sender-side socket failures:

```text
connected=2
pcm_send_failed=0
pcm_frames_attempted=9213952
pcm_frames_sent=9211904
```

Android logcat recorded two valid 48 kHz stereo streams. AudioFlinger recorded
the launcher app's two `AudioTrack` lifetimes as `1775616` and `6925448`
frames delivered, for `8701064` frames total, and the service stopped cleanly
with the same cumulative count. The exact runtime and X11 cleanup markers both
passed with no matching Nova process remaining.

The operator heard the Big Picture startup swell and later UI sounds through
the physical speaker. This is the first end-to-end audible-output observation
for the real Steam client, not merely an `AudioTrack` or socket transport
probe.

## What did not work cleanly

The operator reported that UI sounds arrived noticeably late. The active
AudioFlinger track used a `7688`-frame client buffer at 48 kHz (about 160 ms
of PCM before Android mixer/output latency), and the current Android receiver
uses `AudioTrack.WRITE_BLOCKING` with that buffer. The observed delay may also
include Steam/CEF batching; this run does not yet isolate those contributors.

The operator also still saw Steam Settings report:

```text
No output devices detected
No input devices detected
```

That is consistent with the current architecture. The bridge forwards ALSA
playback writes to `AudioTrack`; it does not provide a Pulse/ALSA device
discovery/control endpoint and it does not implement capture. Android's own
audio policy exposes a speaker and built-in microphone, but the Holo rootfs
has no `/dev/snd` device node for Steam to enumerate.

## New diagnostic: receiver-side frame loss

The C preload logged `9211904` frames sent to the loopback socket, while the
Android service reported `8701064` frames accepted by `AudioTrack`, a gap of
`510840` frames. The sender had no `send_all` failure, so this is not a TCP
backpressure failure. The current receiver performs one `AudioTrack.write`
call for each received buffer and advances past the entire buffer even when
that call returns fewer bytes than requested. A short Android write can
therefore discard the unwritten tail. This needs to be fixed before comparing
latency measurements or calling the stream lossless.

## Next bounded changes

First predeclare and test a receiver-only correction that drains every short
`AudioTrack.write` until the complete aligned PCM buffer is accepted, recording
short-write counts and any negative/zero return. Keep the existing buffer size
and launcher profile for that control.

After that result is documented and pushed, run a separate latency experiment
with a smaller explicitly recorded `AudioTrack` buffer. Do not combine the
short-write fix and buffer-size change in one verdict. Device discovery/input
support remains a third, separate control-plane problem.

The product default remains bridge-disabled until playback is lossless enough,
latency is acceptable, and a deliberate decision is made about the missing
Steam device-discovery and capture surfaces.
