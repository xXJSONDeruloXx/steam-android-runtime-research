# Nova manual harness guards — 2026-08-09

Status: implemented and locally verified; apply these guards before the next
device experiment.

## Timeout policy

`android/nova-lab/deploy-native-steam-manual-session.sh` now uses bounded
defaults for ordinary manual profiles:

- Steam client: 900 seconds;
- Gamescope: 900 seconds;
- EIS touch: 900 seconds; and
- controller relay: 900000 milliseconds.

An ordinary profile rejects values above those limits, including the old
86400-second values. A long-lived manual session must explicitly set
`NOVA_RUN_PROFILE=manual-long-lived` and provide
`NOVA_MANUAL_WATCHDOG_SECONDS`; the host `timeout` command then owns the
deadline. This prevents copied manual commands from silently creating a
day-long orphan runtime while retaining an explicit, bounded escape hatch for
operator sessions.

The guard is run before the manual PID file is created. A rejected profile
therefore cannot leave a stale local session identity behind.

## Fail-closed post-stop verification

`android/nova-lab/verify-nova-post-stop.sh` centralizes the checks that were
previously retyped as ad-hoc nested `adb shell` commands. It requires a run
identity, run directory, and pulled report, then records:

- the report SHA-256;
- absence of the requested ADB forward;
- absence of exact-scope Nova runtime processes;
- absence of app-owned runtime sockets/reports;
- zeroed AHB trace files; and
- a final `post_stop_verification=pass` marker.

Remote compound commands are passed as one explicitly quoted shell string.
ADB failures, missing reports, residuals, trace-state mismatches, and stale
runtime files are hard failures rather than output that can be hidden by
`|| true`.

## Verification

The completed run
`manual-20260809T002802Z-ahbtransportobs` was checked with the new verifier:

```text
post_stop_report_sha256=10d4e6083d1178010a7a491d8c39223c3ff1c02bb54bfeaf46bb3460d4050bd0
post_stop_adb_forward=pass port=18082
post_stop_residual_processes=pass
post_stop_app_files=pass
post_stop_trace_state=pass
post_stop_verification=pass
```

The timeout guard was also tested without launching a device run:

```text
manual-stream-test + NOVA_STEAM_CLIENT_TIMEOUT=86400 → exit 1
manual-long-lived without NOVA_MANUAL_WATCHDOG_SECONDS → exit 1
```

The next bounded run must invoke the verifier after report pull and forward
removal, using its own run ID and report path. The next experiment remains
transport-only: no ring, SurfaceControl, fence, or input behavior changes.
