# Nova OOBE A-button surface-correlation experiment — 2026-08-09

Status: predeclared; device result pending.

## Question

The Android input bridge has already been shown to transport
`KEYCODE_BUTTON_A` (96) as Linux `BTN_SOUTH` (304), and the no-trigger
Gamescope path has a visible downstream Steam surface. The remaining narrow
question is whether Steam consumes that A-button event on the fresh Android
presentation while the selected OOBE language is visible.

## One-variable run

Use the current no-trigger Gamescope artifact and the current test-bench APK.
Keep the fullscreen 1280x960 native Steam/Xwayland session, software CEF/GL,
blocking AHB ACK/release ring, and current cleanup harness unchanged. Enable
the diagnostic AHB surface marker so the final Android screenshot must
correlate with the producer frame, and enable frame identity as an additional
same-buffer record.

The only controlled input is one Android key event:

```text
KEYCODE_BUTTON_A=96
BTN_SOUTH=304
```

The run must use a fresh ID/profile, fresh Steam readiness baselines, and
strict artifact provenance. The marker is intentionally visible and is not an
end-user presentation result.

## Acceptance gates

Accept the transport/presentation portion only when all of these hold:

- 240 AHB frames and 239 releases complete;
- the marker decoder identifies the final screenshot frame and its checksum;
- that frame/checksum matches the app's producer record;
- the screenshot passes the Steam surface gate; and
- explicit post-stop cleanup and property-reset verification pass.

Accept A-button UI consumption only when the strict Steam navigation region
changes after the event and the app/relay logs prove the requested
press/release reached the exact virtual Xbox device. A stable or unrelated
surface change is a negative result, not a navigation pass.

If the A-button gate passes, the next experiment should repeat the same
marker-correlated session with a bounded sequence of OOBE touch or controller
actions and capture CDP route/state after each transition. If it fails, keep
the mapping/transport result separate and inspect Steam focus/OOBE semantic
state before changing the AHB path.
