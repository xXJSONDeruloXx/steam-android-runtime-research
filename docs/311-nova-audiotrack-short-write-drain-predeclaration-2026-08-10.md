# Nova AudioTrack short-write drain experiment — 2026-08-10

Status: predeclared; source change and device verification are pending.

## Reason for the control

The bridge-enabled Steam session made audible output, but the C preload logged
`9211904` frames sent while the Android service reported `8701064` frames
accepted. There were no sender-side socket failures. The current receiver
calls `AudioTrack.write` once for each received byte buffer and then advances
past the whole buffer, so a short positive return can drop the unwritten tail.

This experiment addresses only that receiver-side accounting/loss hypothesis.
It does not change the `AudioTrack` buffer size, the PCM format, the socket
protocol, Steam flags, rendering profile, or device-discovery behavior.

## Planned source change

In `AudioPcmBridge`, drain each aligned PCM buffer with repeated blocking
`AudioTrack.write` calls until all bytes are accepted. Count short positive
writes, zero returns, and negative failures in the run status. A zero return
must not silently advance the input cursor or discard data.

## Device run contract

Use a fresh APK built from the source commit containing only this receiver
change, on the Retroid Pocket Nova (`675a2365`) with:

- `run_audio_bridge_steam=true`, port `29100`;
- hardware launcher path, CEF GPU disabled, Steam `gamepadui`;
- software Mesa client rendering and CEF environment split;
- the existing X11 stretch profile (`1280x800` stretched to `1280x960`);
- no physical, synthetic, keyboard, pointer, touch, or controller input.

Capture the APK and preload hashes, fresh launcher/client/bridge logs,
AudioFlinger state, and a final screenshot only if it can be obtained without
input. Stop through the exact Nova launcher cleanup and verify no matching
process, socket, or run-staged artifact remains.

## Acceptance and interpretation

A clean transport result requires:

1. the bridge listener is ready before Steam;
2. the client connects and negotiates 48 kHz stereo S16 PCM;
3. the C-side sent-frame total matches Android's accepted-frame total after
   the final stream close;
4. any short writes are drained and counted, with no negative or unbounded
   zero-write loop; and
5. exact Nova and X11 cleanup passes.

The user-reported audible delay is not expected to be resolved by this control;
it establishes a lossless baseline before a separate buffer/latency experiment.
Steam Settings may still show no devices because this bridge has no discovery
or capture endpoint.
