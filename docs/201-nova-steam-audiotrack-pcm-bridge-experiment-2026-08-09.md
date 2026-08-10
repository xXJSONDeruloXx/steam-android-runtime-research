# Nova Steam-to-Android AudioTrack PCM bridge — 2026-08-09

Status: isolated and combined Steam-session transport passed, with connection
rollover warnings still requiring hardening. The product default is still
disabled and no audible-listener claim is made.

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

## Combined Steam-session result — `audio-20260809T235800Z-steam-session`

This run used the APK built from commit `605c9ee` at
`android/nova-lab/build/nova-lab-debug.apk`, with the known software profile:
`HARDWARE_ACCEL=0`, `-cef-disable-gpu`, fullscreen, and
`-fulldesktopres`. It did not use Gamescope/AHardwareBuffer. No physical or
synthetic input was sampled; the normal launcher initialized its relay but no
button or touch event was exercised.

The one-click service started the bridge before the root-side client and
reported:

```text
nova_launcher_audio_bridge=1
nova_launcher_audio_bridge_port=29100
nova_launcher_ready=pass display=:0 geometry=1280x960
```

The fresh client log then recorded the same opt-in mode and preload chain:

```text
client_audio_bridge=1
client_audio_bridge_port=29100
client_preload=/opt/nova-kgsl-driver/libnova-alsa-audiotrack-bridge.so:/opt/nova-kgsl-driver/libsysv-sem-shim.so
client_started=pass
```

Android logcat showed the real Steam session connect to the loopback listener
and negotiate the expected stream:

```text
NovaAudioBridge: audio_bridge_listener=ready host=127.0.0.1 port=29100
NovaAudioBridge: audio_bridge_client=connected
NovaAudioBridge: audio_bridge_stream=ready rate=48000 channels=2 format=S16_LE
```

The client remained alive through Steam UI initialization. Current-run
timestamps in `steamui_html.txt` showed webhelper `29933` starting at
`00:00:42`, `CreateMainWindow` at `00:00:58`, and the current-run
`webhelper_js.txt` section reached `SteamApp Init - After Login` at
`00:00:59`. The CEF audio service logged its ALSA fallback at `00:00:45`; the
current-run CEF section contained no `Failed to write to pcm device: Invalid
argument` line, unlike the earlier direct-ALSA run.

The stream was productive: across the session the Android service accepted
`frames=4128536 bytes=16514144` through `AudioTrack`. AudioFlinger recorded
three app-owned 48 kHz stereo tracks for UID/PID `28995`, with writes observed
at the connection turnovers. This establishes that the actual Steam-side
audio path reached Android and was written to an Android `AudioTrack`; it does
not establish that a person heard sound.

One reliability boundary remains. Two Steam-side connection turnovers ended
with a non-frame-aligned tail before the bridge accepted the next connection:

```text
NovaAudioBridge: audio_bridge_client=fail error=java.io.EOFException: partial_pcm_frame bytes=3
NovaAudioBridge: audio_bridge_client=connected
NovaAudioBridge: audio_bridge_client=fail error=java.io.EOFException: partial_pcm_frame bytes=1
NovaAudioBridge: audio_bridge_client=connected
NovaAudioBridge: audio_bridge_stream=closed frames=4128536 bytes=16514144
```

The total accepted byte count is frame-aligned, so the current result is a
transport pass with a connection/framing warning, not a clean continuous
stream acceptance. The next audio experiment should instrument or harden this
handoff before enabling the bridge in the product default.

Run artifacts:

- APK SHA-256:
  `eb34e5e0103467efe48b5475033a43ab461744203fd1b626478fc6ba06e4bce1`;
- ARM64 preload SHA-256:
  `07a3d64f07a85e0696eca0420599c95b871af05f5963d84a7dd229944681a330`;
- bridge source SHA-256:
  `ceb3996df898314d5f91a9b0547d63799edad36e1de042d8c1881fc53b29bdd2`;
- runtime cleanup helper SHA-256:
  `12332bc7e8d9401dfbe9ce72c5aba8feb910c1574a0e28602817bf92da34fb97`;
- X11 namespace helper SHA-256:
  `d870910b03678bb56001e424d5bcd9f1ae8ef4e6c39817e3488ded250aabc937`;
- X11 cleanup helper SHA-256:
  `3e9358bc5f600ca4d2f860730dc43b7eb39411efd02dc1b24a09aaf39cd79528`.

Teardown force-stopped the APK and Termux:X11, then the exact helper returned
`nova_runtime_cleanup=pass` with `remaining=`. The X11 helper returned
`nova_x11_cleanup=pass` with absent server, client, parent, and socket state.
The post-stop process inventory contained no matching Nova runtime; the
run-scoped rootfs preload, launcher state, relay stage, probe files, and APK
asset staging directory were removed after evidence capture.

## Next hardening run contract

The next bounded audio run will keep the same software Steam profile and
opt-in-only launcher flag, but the preload will also write a run-scoped event
log inside the rootfs. It records each intercepted write attempt, successful
PCM send, close, and the exact number of bytes accepted before a socket send
failure. This is intended to distinguish a peer-close during `send()` from a
receiver-side alignment bug; it does not change the PCM protocol or the
product default.

The run will again avoid physical and synthetic input. A clean result requires
no partial-frame warning and a matching stream-close/send record. If the
client still closes mid-write, retain the byte count and treat that as the
Steam audio lifecycle boundary rather than masking it in the Android service.

## Instrumented handoff result — `audio-20260810T001100Z-bridge-instrumented`

The instrumented APK was built from commit `e5d5aa8` and reran with the same
software, fullscreen, signed-in Steam profile. It did not sample physical or
synthetic input. The Android listener and real Steam client again reached the
same 48 kHz stereo `AudioTrack` path before teardown.

The root-side event log made the earlier partial-frame tails attributable:

```text
event=pcm_open                         count=1
event=connected                        count=3
event=header_sent                      count=3
event=pcm_frames_attempted             count=1833
event=pcm_frames_sent                  count=1831
event=pcm_send_failed_bytes            value=3051 errno=11
event=pcm_send_failed_bytes            value=4217 errno=11
event=pcm_close                       count=1
```

`errno=11` is `EAGAIN`; the two byte counts are respectively 3 and 1 modulo
the 4-byte stereo S16 frame size. The Android receiver reported the matching
`partial_pcm_frame bytes=3` and `partial_pcm_frame bytes=1` errors. The
receiver is therefore observing the prefix that the preload sent before its
one-second `SO_SNDTIMEO` expired, not inventing misalignment while reading a
complete PCM write. Successful sends continued across three connections, and
the service closed with `frames=3753752 bytes=15015008`.

This closes the current diagnosis: the bridge needs sender-side backpressure
handling (or a deliberately blocking send policy) before it can be called a
clean continuous stream. The next source change should address the timeout
behavior, then repeat this same run. The product default remains disabled.

Run artifacts:

- APK SHA-256:
  `d5b7a5dfff21e577a134ab544dfec88b0acf967ae009eade353bf1d62fd9e155`;
- instrumented ARM64 preload SHA-256:
  `1a76ef1888242f7e76ac3b07777c66b1fa12538b49777fdaae93c0a031a4e65a`;
- instrumented preload source SHA-256:
  `0877eee7b4496fddc997fcaf19da10a461f7bcee9364f59c410dfabb76e86946`;
- bridge event-log SHA-256:
  `6547815e3e197ecaa3979da09f6b79723574bf16a550f71d64540880dd505c8a`;
- final Android logcat SHA-256:
  `6e4f6d0eacaaad54c10cbcdbe1ba115330505285c74d7663195523d83cddd1df`.

The exact Nova cleanup marker was pass with an empty `remaining=` field, the
X11 cleanup marker was pass with absent server/client/parent/socket state, and
the post-stop check found no matching runtime process or run-scoped bridge
files.

The proposed sender fix is deliberately narrow: the preload removes its
one-second `SO_SNDTIMEO`, enlarges the loopback send buffer, and retries
`EAGAIN` after waiting for writability. Local ARM64 compilation, exported
symbol inspection, shell syntax checks, Java compilation, APK signing, and
APK build all pass for that change. The next device run must use the newly
built APK and library hashes, not the prior instrumented artifact.

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
