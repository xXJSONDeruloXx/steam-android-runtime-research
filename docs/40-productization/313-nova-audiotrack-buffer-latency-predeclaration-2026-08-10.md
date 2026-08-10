# Nova AudioTrack buffer latency experiment — 2026-08-10

Status: predeclared; source change and device verification are pending.

## Hypothesis

The current Android receiver requests `max(minBuffer * 2, 16384)` bytes for
the streaming `AudioTrack`. On the Nova this produced a `7688`-frame client
buffer at 48 kHz, in addition to the Android mixer/output path. The user heard
Steam UI sounds, but noticeably late. Reducing the client buffer to the
minimum accepted value may reduce queued audio latency without touching the
Steam client or the rootfs ALSA transport.

This is a buffer-size experiment only. The short-write drain correction from
`1a3fd49` remains in place; no new discovery, capture, protocol, rendering,
input, or Gamescope change is included.

## Planned source change

Change `AudioPcmBridge.createTrack()` to request `minBuffer` bytes rather than
doubling that value or imposing the current 16 KiB floor. Retain the same
48 kHz stereo S16 format, `USAGE_GAME`, `MODE_STREAM`, and blocking write
drain. The result must record the actual AudioFlinger frame count rather than
assuming the platform honors the requested size exactly.

## Device run contract

Build and install a fresh APK containing only this buffer-size change. Use the
same Nova session profile:

- `run_audio_bridge_steam=true`, port `29100`;
- hardware launcher path, CEF GPU disabled, Steam `gamepadui`;
- software Mesa client rendering and CEF environment split;
- X11 stretch `1280x800` on the `1280x960` Android surface;
- no physical, synthetic, keyboard, pointer, touch, or controller input.

Capture the APK/preload hashes, launcher/client/bridge logs, AudioFlinger
active-track frame count and latency, and any operator audio observation that
occurs naturally. Complete exact Nova/X11 cleanup and verify the final process
set is empty.

## Acceptance and interpretation

The transport must retain the completed-stream equality established by the
short-write control: no negative/zero write loop, no sender failure, and equal
preload-sent versus Android-accepted frames for any naturally closed stream.

The primary comparison is the actual AudioFlinger `FrmCnt`/latency against the
previous `7688`-frame track. A smaller queue with unchanged late UI sounds
would move the cause upstream into Steam/CEF/ALSA batching; a smaller queue
with an audible improvement supports the buffer hypothesis. Steam Settings may
still report no devices because the playback bridge remains a data-plane sink
without a discovery or capture endpoint.
