# Nova Steam-to-Android AudioTrack PCM bridge — 2026-08-09

Status: isolated bridge acceptance passed; combined Steam-session run remains
pending. The product default is still disabled.

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

The implementation is now present and remains opt-in. `AudioPcmBridge` is
owned by the foreground `LauncherService`, the root launcher passes
`NOVA_ANDROID_LAUNCHER_AUDIO_BRIDGE` and its port, and
`build-alsa-audiotrack-bridge.sh` produces the ARM64 preload. Local validation
passed: shell syntax, ARM64 shared-library compilation, exported ALSA symbol
inspection, Java compilation, APK signing, and APK build.

## First device attempt — `audio-20260809T234943Z-loopback-permission`

The app-owned diagnostic entrypoint reached the service, but listener creation
failed before any rootfs probe:

```text
NovaAudioBridge: audio_bridge=fail reason=listen error=java.net.SocketException: socket failed: EPERM (Operation not permitted)
NovaLauncher: Nova audio bridge failed: audio_bridge=fail reason=listen error=java.net.SocketException: socket failed: EPERM (Operation not permitted)
```

The APK had not requested `android.permission.INTERNET`; Android rejected the
loopback `ServerSocket` even though it was bound to `127.0.0.1`. The service
did not remain running, and no PCM or Steam process was launched. The exact
Nova cleanup preflight was pass. The manifest now declares the normal Internet
permission required for a loopback socket; the bridge still binds only to
localhost and remains opt-in.

## Isolated AudioTrack acceptance — `audio-20260809T235025Z-loopback-audiotrack`

After adding the manifest permission, the diagnostic entrypoint was rerun as a
bridge-only session. It did not start Steam, Gamescope, X11, or any input
relay, and no physical or synthetic input was used. The APK started the
foreground service with `run_audio_bridge_only=true`; the service listened on
`127.0.0.1:29100`.

The device-side ALSA probe opened and configured the rootfs `default` PCM,
prepared a 48 kHz, two-channel, S16_LE stream, and sent 2,048 frames of
silence over the bridge. The captured probe was repeated once during the same
isolated service lifetime:

```text
mount_private=pass path=/
alsa_device=default
alsa_requested_format=S16_LE
alsa_requested_rate=48000
alsa_requested_channels=2
alsa_requested_buffer_us=10000
alsa_write_payload=silence
nova_alsa_audiotrack_bridge event=pcm_open value=0 errno=6
alsa_pcm_open=pass
alsa_pcm_set_params=pass
alsa_buffer_frames=2048
alsa_period_frames=1024
alsa_pcm_prepare=pass
alsa_available_frames=2048
nova_alsa_audiotrack_bridge event=connected value=29100 errno=0
nova_alsa_audiotrack_bridge event=header_sent value=48000 errno=0
nova_alsa_audiotrack_bridge event=pcm_frames_sent value=2048 errno=0
alsa_pcm_write_requested_frames=2048
alsa_pcm_write=pass frames=2048
alsa_pcm_drop_after_write=pass
alsa_pcm_close=pass
```

The Android service reported a valid stream and received both probe writes:

```text
NovaAudioBridge: audio_bridge_listener=ready host=127.0.0.1 port=29100
NovaLauncher: Nova audio bridge ready port=29100
NovaAudioBridge: audio_bridge_client=connected
NovaAudioBridge: audio_bridge_stream=ready rate=48000 channels=2 format=S16_LE
NovaAudioBridge: audio_bridge_stream=closed frames=4096 bytes=16384
```

The second probe transcript hash is
`477047f147e92daea509ad9236300314e21ef6e9f930ac248ddefcc00b4ddbb1`. The
AudioFlinger diagnostic also showed a short-lived app-owned 48 kHz stereo
`AudioTrack` with a 2,048-frame write. This proves the loopback protocol,
Android `AudioTrack` creation, and a positive PCM write independently of the
Steam/Chromium client. It does not yet prove audible output or that Steam uses
this path in a full session.

Run artifacts:

- installed APK SHA-256:
  `f26451df05a3c072b095d776afd8a20a1ecd985ad3c34a94c42bcd2f4a4c4e30`;
- ARM64 preload library SHA-256:
  `07a3d64f07a85e0696eca0420599c95b871af05f5963d84a7dd229944681a330`;
- rootfs probe binary SHA-256:
  `d3385ab5542395659c3a05cda3123ad596ab1c6e9c5e4d07c63cfba08f5580ed`;
- the app-owned audio service stopped with cumulative counters
  `frames=4096 bytes=16384`;
- exact Nova cleanup completed with
  `nova_runtime_cleanup=pass ... attempts=1 ... remaining=` and no matching
  runtime service or process remained.

The isolated bridge acceptance therefore passes. The next bounded run is the
same software Steam profile with the bridge enabled, checking whether the
actual client reaches the endpoint and whether its existing UI readiness
boundary remains intact.

## Combined Steam-session run contract

Before the next device launch, the APK now exposes the opt-in diagnostic extra
`run_audio_bridge_steam=true`. It uses the normal one-click launcher and
notification lifecycle, copies the bridge preload into the app-owned launcher
asset directory, starts the loopback `AudioTrack` service before the root-side
Steam command, and passes the bridge flag and port through the existing
launcher environment. A normal launcher start remains bridge-disabled.

The run will use the known software presentation profile and will not sample
physical or synthetic input. The result is a transport/lifecycle check only:
the useful pass is a Steam-owned bridge connection with nonzero PCM frames,
the existing UI readiness boundary, and exact cleanup. A Steam crash, no
connection, or `AudioTrack` error will be recorded without changing the
default profile.

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
