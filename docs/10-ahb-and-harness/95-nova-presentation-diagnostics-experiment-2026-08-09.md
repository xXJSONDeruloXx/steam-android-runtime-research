# Nova presentation diagnostics experiment — 2026-08-09

Status: predeclared; device result pending.

## Causal basis

The doc 94 run reached fresh SteamUI readiness and completed all 240 AHB
producer frames, but its native 1280x960 capture was dark and failed the
frame-marker decoder. The nested smoke wrapper stopped at that failure before
copying the current Steam client stdout/stderr/log files. The same run also
did not retain SurfaceFlinger layer geometry or the producer-to-display
transform, so the observed 960x540 diagnostic rescale cannot yet distinguish
an unrendered Steam surface from a transformed or incorrectly presented one.

## One-variable harness change

Keep the doc 94 Gamescope binary, APK, presentation dimensions, AHB cadence,
software CEF/GL flags, readiness timeout, input mapping, and cleanup contract
unchanged. Change only the AHB deploy harness so that, immediately after the
probe returns and before frame-marker decoding or another acceptance check, it
retains:

- fresh `/tmp/nova-steam-client.log`, stdout, and stderr;
- the current Steam console, SteamUI, webhelper, CEF, and connection logs;
- same-run `dumpsys SurfaceFlinger --list` and `--layers` output; and
- explicit missing/available status for each diagnostic source.

These artifacts are observational. Missing logs or a failed diagnostic dump
must not turn a lower-level AHB result into a pass or fail by itself, and must
not weaken the required cleanup trap.

## Device acceptance gate

Repeat the exact doc 94 run with a fresh run ID/profile and the same binary and
APK provenance checks. The run remains rejected unless the native 1280x960
capture is a visible Steam surface and correlates to the producer marker. The
new diagnostics must answer, from the same run, whether:

1. Steam client and SteamUI rendered content before the capture;
2. SurfaceFlinger retained the expected application layer and transform; and
3. the 960x540 AHB producer buffer was scaled, cropped, or otherwise
   transformed on the 1280x960 destination.

Do not send the A-button, change the AHB compositor, or advance to networking,
audio, hardware GL, or login acceptance until the native-resolution
presentation boundary is resolved.

