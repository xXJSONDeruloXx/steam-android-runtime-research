# Nova AHB pre-marker content probe experiment — 2026-08-09

Status: predeclared; device result pending.

## Causal basis

Doc 102 established a synchronized split: the settled Gamescope X11 window
contains visible Steam UI, while the immediately sampled Android
AHardwareBuffer screenshot remains dark and marker-only. The existing AHB
identity checksum and surface marker prove ownership/fence progression and that
the app's marker reaches SurfaceControl, but they do not prove that the complete
Gamescope image was written into the AHB before the marker write.

## One-variable diagnostic change

Keep the doc 102 1280x960 producer/destination, Gamescope binary and source
tree, Steam software-renderer flags, settled X11 capture, frame cadence,
readiness gate, input mapping, and cleanup contract unchanged. Build only the
Nova APK/bridge diagnostic addition and enable:

```text
NOVA_AHB_CONTENT_PROBE=1
debug.nova.ahb_content_probe=1
```

After the Gamescope acquire fence is observed and before the existing app-side
frame marker is written, the bridge will record a bounded set of samples
(frames 0–2, every 30th frame, and the final bounded frame). Each sample will
include:

- the actual `AHardwareBuffer_Desc` width, height, stride, layers, format, and
  usage;
- the active-region raw FNV-1a checksum already used by frame identity; and
- RGBA min/max/average values plus integer luma min/max/average computed before
  marker writing.

The probe does not alter the dmabuf protocol, Gamescope import description,
Vulkan composition, SurfaceControl geometry, frame marker payload, or input
delivery. The property is explicitly reset by the bounded harness, manual
session cleanup, and the post-stop verifier.

## Device acceptance gate

Require all existing lower-level gates from doc 102, plus:

```text
ahb_double_buffer_content_probe=enabled
ahb_double_buffer_frame_content_0=pass
ahb_double_buffer_frame_content_<final>=pass
```

The strict visible Android Steam-surface gate remains unchanged. Do not send an
A-button when that gate fails. The run must also retain a fresh settled X11
capture, the Android screenshot, full provenance metadata, and explicit
post-stop cleanup with `debug.nova.ahb_content_probe=0`.

## Interpretation matrix

1. Pre-marker AHB samples are uniformly dark or match the initialized/marker
   pattern while settled X11 is visible: prioritize Gamescope's imported AHB
   target, format, stride, modifier, or linear-tiling path.
2. Pre-marker AHB samples contain varied Steam-like pixels but Android remains
   dark: investigate the SurfaceControl/HWC handoff or downstream composition,
   not Gamescope rendering.
3. The descriptor reports a stride different from `width` or a format/usage
   different from the hard-coded Gamescope import assumptions: treat that as
   direct metadata evidence before changing the import path.
4. The probe fails before mapping or fence completion: preserve the exact
   failure and stop; do not interpret the Android screenshot as a rendering
   result.

Hardware GL, audio, touchscreen, login, networking acceptance, and standalone
launcher acceptance remain unclaimed by this diagnostic.
