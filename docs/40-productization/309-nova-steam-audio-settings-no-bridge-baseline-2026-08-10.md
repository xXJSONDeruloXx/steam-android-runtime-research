# Nova Steam Settings audio baseline and bridge rerun — 2026-08-10

Status: baseline captured; the bridge-enabled rerun is the next bounded audio
experiment.

## Current display baseline

The live one-click Steam session was inspected before changing its state. The
session identity is `20260810T144236Z-18044`, and the launcher reports:

```text
nova_launcher_hardware_accel=1
nova_launcher_cef_disable_gpu=1
nova_launcher_steam_ui_mode=gamepadui
nova_launcher_steam_force_software_gl=1
nova_launcher_steam_cef_env_split=1
nova_launcher_audio_bridge=0
nova_launcher_ready=pass display=:0 geometry=1280x960
```

The Android capture showed Steam Settings → Audio with both rows disabled:

```text
No output devices detected
No input devices detected
```

The capture was taken from the current device surface before teardown. Its
SHA-256 is
`687cb614e2331f9bfcff6904818f514932752eb66a85cda893404205a4b791e3`.

The current client log independently records `client_audio_bridge=0` and a
preload containing only the SysV semaphore shim and CEF environment split
library. This is therefore a valid no-bridge baseline, not evidence that the
Android audio sink is unavailable.

## Device-side audio boundary

Read-only inspection during the live session found:

- the Holo rootfs has no `/dev/snd` directory;
- the rootfs contains the opt-in
  `/opt/nova-kgsl-driver/libnova-alsa-audiotrack-bridge.so` preload;
- Android AudioFlinger exposes a speaker output and Android audio policy
  exposes a built-in microphone input;
- the rootfs-to-Android playback bridge has already passed an isolated
  AudioTrack probe and a clean Steam-session PCM transport run in
  [`201-nova-steam-audiotrack-pcm-bridge-experiment-2026-08-09.md`](../30-runtime-and-games/201-nova-steam-audiotrack-pcm-bridge-experiment-2026-08-09.md).

The bridge intercepts ALSA playback writes and forwards them to Android
`AudioTrack`. It does not implement an ALSA capture/input endpoint. Thus the
next run can plausibly make output usable, but it is not expected by itself to
make Steam report an input device.

## Next bounded experiment

Stop the current session with the exact Nova cleanup contract, then start a
fresh session using the same display, Steam UI, software-GL, and CEF settings
with `run_audio_bridge_steam=true` (equivalent launcher mode:
`NOVA_ANDROID_LAUNCHER_AUDIO_BRIDGE=1`, port `29100`). Do not sample physical
or synthetic input during this run.

Record, with the new run identity:

1. bridge listener readiness before Steam starts;
2. launcher/client audio flags and preload identity;
3. a fresh Steam Settings → Audio screenshot;
4. bridge connection, stream, frame, and error counters;
5. AudioFlinger tracks and Android audio-policy state; and
6. exact APK, rootfs, preload, process, socket, and staging cleanup.

Interpretation is deliberately split:

- Steam displays an output device and the bridge receives nonzero frames:
  output discovery/transport is a pass;
- the bridge receives frames but Settings still lists no output device: the
  bridge works as a sink but Steam's device-discovery UI needs a separate
  control-plane endpoint;
- input remains absent: expected for this playback-only bridge and a separate
  capture design is required;
- no bridge connection or no frames: retain the fresh client/CEF/ALSA logs and
  investigate the Steam-side audio API before changing Android plumbing.

The product default remains bridge-disabled until this fresh run confirms the
desired UI and audible behavior.
