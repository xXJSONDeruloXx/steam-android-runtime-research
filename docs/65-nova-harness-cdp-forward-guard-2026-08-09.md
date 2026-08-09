# Nova harness CDP-forward guard — 2026-08-09

Status: repaired after an invalid observation attempt; no device evidence from
the invalid run is used.

## Incident

Run `manual-20260809T012135Z-ahbpoll` started successfully with the new
15-second ACK poll instrumentation, but the first baseline capture was invoked
before the host had created its required ADB forward. The capture helper
therefore failed at `curl` with “failed to connect,” leaving a
`capture_status=fail` artifact in the run directory.

The session was immediately stopped through
`finish-nova-manual-run.sh`. Exact runtime cleanup, app-file cleanup, trace
reset, ACK-poll-property reset, forward removal, and post-stop verification all
passed. Because the baseline artifact was invalid, the session is not a
transport result and must not be reused under that run ID.

## Repair

`capture-nova-manual-evidence.sh` now snapshots `adb forward --list` into the
phase directory and fails before any CDP/screenshot/X11 capture unless the
requested `tcp:$NOVA_CDP_PORT` forward is present. The phase status records the
forward-manifest path, making the precondition auditable.

The correct order for the next run is now explicit:

1. Start the fresh manual session and wait for its current-PID readiness marker.
2. Create and verify `adb forward tcp:$NOVA_CDP_PORT tcp:8080`.
3. Run the baseline capture helper.
4. Only then inject the controlled input and collect later phases.

This is a harness repair, not a Nova/AHB finding. The next run must use a new
run ID and directory, even though the stopped session itself cleaned up
successfully.
