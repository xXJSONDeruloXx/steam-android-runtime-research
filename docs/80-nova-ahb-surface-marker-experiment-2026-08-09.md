# Nova AHB downstream surface-marker experiment (2026-08-09)

Status: implementation and build gate defined; device result pending.

## Question

The frame-identity milestone proves that a Gamescope output frame ID and
pre-SurfaceControl AHardwareBuffer checksum arrive coherently in Android, but
the retained Android PNG is a separate downstream capture. The open question
is whether the user-visible SurfaceControl image contains the same received
buffer and frame.

## One-variable diagnostic

Keep the existing native Steam/Xwayland, fullscreen 1280x960, software CEF/GL,
three-buffer, acquire/release-fence, controller, and cleanup profile unchanged.
Enable only `debug.nova.ahb_frame_marker=1` in addition to the existing
`debug.nova.ahb_frame_identity=1`.

After the acquire fence is signaled and the pre-marker FNV-1a checksum is
computed, Android writes a diagnostic-only black/white marker into the
received AHardwareBuffer at `(x=16,y=96)`. Its 12x4 cells, eight pixels per
cell, encode a 16-bit `NV` magic value, the producer frame number, and the low
16 bits of the pre-marker checksum. The normal path remains unchanged when the
property is `0`.

The host decoder converts the same-run Android PNG to RGBA with ffmpeg, samples
the marker cells, and requires all of the following:

1. the marker magic is valid;
2. the decoded frame number and checksum suffix are present in the Android
   app's frame-marker report; and
3. the corresponding identity record has producer-frame equality,
   `marker_status=0`, and `checksum_status=0`.

This is a controlled visible-marker correlation rather than a claim that a
PNG's whole pixel stream is identical to the pre-SurfaceControl AHardwareBuffer.
It is sufficient to establish that the visible surface contains the identified
received buffer before attempting to accept Steam's login screen.

## Rejection conditions

Reject the run if the marker cannot be decoded, if its frame/checksum suffix is
absent from the app report, if any frame marker or identity record fails, if
the screenshot geometry is too small for the marker, or if post-stop cleanup
does not reset both diagnostic properties to `0`.
