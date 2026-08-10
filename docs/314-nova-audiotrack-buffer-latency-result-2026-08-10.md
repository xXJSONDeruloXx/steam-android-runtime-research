# Nova AudioTrack buffer latency result — 2026-08-10

Status: the isolated smaller-buffer run passed the playback transport and
reduced the Android client queue. The user's earlier live-session observation
still stands: Steam UI sounds are audible, but noticeably delayed. No new
operator timing comparison was made during this bounded run.

## Run identity and provenance

- Experiment: `nova-audio-buffer-latency-20260810T150326Z`
- Launcher session: `20260810T150402Z-28830`
- Device: Retroid Pocket Nova, Android 13, adb serial `675a2365`, `kalama`
- Source commit: `0c26f71`
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256: `85131f1c4a5b18f3653f8b31b9545787c370b92b6469f068902d05c060424dfb`
- Preload SHA-256: `741943aead509f6179811633d018d8ad8246bedd27d3641dab9b576435358143`
- Profile: hardware launcher path, CEF GPU disabled, Steam `gamepadui`,
  software Mesa client rendering, CEF environment split, X11 stretch
  `1280x800` on the `1280x960` Android surface
- Audio mode: `run_audio_bridge_steam=true`, loopback port `29100`
- Host evidence: `android/nova-lab/build/runs/nova-audio-buffer-latency-20260810T150326Z/`

The only source change from the short-write control was the Android receiver's
requested streaming buffer: `AudioPcmBridge.createTrack()` now passes the
device-reported `minBuffer` directly. The short-write drain loop, 48 kHz
stereo S16 format, `USAGE_GAME`, blocking writes, rootfs preload, Steam
profile, and display flags were unchanged.

## Playback and transport result

The first and only bridge connection in this run closed before teardown and
matched exactly:

```text
C preload attempted: 2062336 frames
C preload sent:      2062336 frames
Android accepted:    2062336 frames
short_writes=0
zero_writes=0
send_failures=0
```

The Android log recorded:

```text
audio_bridge_stream=closed frames=2062336 bytes=8249344 short_writes=0 zero_writes=0
AudioTrack: stop ... 2062336 frames delivered
```

The close marker's peer-close errno was not a sender failure. This is another
clean naturally closed stream after the receiver-side drain correction.

## Buffer comparison

The active-track snapshot taken after launch showed an Android client buffer
of `3844` frames, with `FrmRdy=3844` and an AudioFlinger-reported latency of
about `228.89` in the dump's latency field. The prior short-write control used
`7688` frames and reported about `268.42` in the same field. The requested
buffer was therefore honored at half the prior frame count, and the reported
track latency fell by roughly `39.5` on this device.

The final AudioFlinger dump also retained the retired track record with the
`3844`-frame buffer. The final dump was taken after exact teardown, so it no
longer contained an active track from which to re-read the live latency field.
The run evidence therefore treats the startup active-track snapshot and the
final retired-track record as separate observations.

This supports the buffer hypothesis at the Android receiver boundary, but it
does not prove that the remaining user-visible delay is entirely in
AudioTrack. The Android output thread reported a 960-frame HAL buffer, and
additional delay may come from the Steam/CEF mixer, ALSA batching, or the
loopback handoff.

## Display and cleanup

The launcher reached `nova_launcher_ready=pass` with `display=:0`
`geometry=1280x960`. The captured frame showed the live Steam Big Picture
home page, including the Geometry Wars library selection. No physical or
synthetic input was used.

The exact launcher stop passed, `nova_x11_cleanup=pass`, and
`nova_runtime_cleanup=pass`. The final matching-process audit was empty; no
Nova rootfs, Steam, X11, Gamescope, Proton, Wine, or uinput process remained.

## Conclusion and next step

Keep the smaller Android buffer for the next audio investigation: it reduces
the measured receiver-side queue without reintroducing frame loss. Do not
combine the next change with Steam device discovery, capture, or rendering.

The next bounded experiment should measure where the remaining delay is
introduced—preferably by correlating a known PCM marker at the preload, bridge,
and speaker path, or by recording the actual `snd_pcm_writei` batch cadence.
If the user confirms the smaller buffer feels better, it can become the
candidate playback default; if it still feels very late, investigate upstream
Steam/CEF or ALSA batching before reducing the AudioTrack buffer again.

Steam Settings may continue to show no input/output devices: this experiment
only changes playback queueing and does not add an ALSA/Pulse discovery or
capture endpoint.
