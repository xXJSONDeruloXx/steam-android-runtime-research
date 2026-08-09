# Nova Steam-to-Android AudioTrack PCM bridge — 2026-08-09

Status: experiment predeclared; no bridge implementation or device result yet.

## Question

The Nova Android speaker and `AudioTrack` sink pass an independent proof, while
the rootfs ALSA path opens/configures but rejects the first `snd_pcm_writei`
with `EINVAL`. Can a lifecycle-owned APK audio endpoint receive the Steam
client's negotiated PCM without changing Android's kernel ALSA driver or
touching the physical-controller path?

## Proposed boundary

The bridge will be opt-in and separately identifiable:

1. `LauncherService` binds a loopback-only PCM server before starting Steam and
   owns a streaming Android `AudioTrack` for the session.
2. A rootfs glibc preload intercepts only playback `snd_pcm_writei` calls. It
   leaves ALSA open/parameter negotiation intact, sends a small versioned
   header followed by S16 interleaved PCM to the loopback endpoint, and returns
   the number of frames accepted by the Android side.
3. The one-click root launcher passes the bridge mode and port into the
   private X11 namespace. The product default stays disabled until a fresh
   stream run passes.
4. Service stop closes the listener/track before exact Nova cleanup completes;
   the preload falls back to the existing ALSA write path when the endpoint is
   unavailable, so a bridge failure cannot silently change the default profile.

The initial protocol is 48 kHz, two-channel, signed 16-bit little-endian PCM,
with a fixed magic/version header and one client per session. The server binds
only to `127.0.0.1`; it is not an Android network-service feature.

The implementation is now present but remains opt-in and untested on the
device. `AudioPcmBridge` is owned by the foreground `LauncherService`, the
root launcher passes `NOVA_ANDROID_LAUNCHER_AUDIO_BRIDGE` and its port, and
`build-alsa-audiotrack-bridge.sh` produces the ARM64 preload. Local validation
passed: shell syntax, ARM64 shared-library compilation, exported ALSA symbol
inspection, Java compilation, APK signing, and APK build.

## Acceptance gates

The bounded device run must establish, in order:

- a fresh exact-scope cleanup baseline and no physical or synthetic input;
- APK, rootfs Steam, preload, namespace helper, and bridge source hashes;
- listener-ready before the Steam client starts;
- a fresh bridge connection and valid header;
- nonzero PCM frames received and written to a streaming `AudioTrack` without
  short writes or negative status;
- Steam remains alive long enough to reach its existing UI readiness boundary;
- service stop, rootfs cleanup, socket closure, and no matching process/state
  residuals.

This is not an audible-listener claim until a person confirms sound on the
device. A failed bridge run must retain the exact PCM counters and errors and
leave the known software/no-bridge profile unchanged.

## Stop conditions and follow-up

Do not patch the Android ALSA kernel driver or re-enter the Gamescope/AHB path
for this experiment. If the preload does not observe Chromium's write path,
record that boundary and inspect the exact ALSA symbol/API used. If transport
passes but `AudioTrack` rejects the stream, keep the Steam-side logs and adjust
only the Android format/buffer contract in a new run.
