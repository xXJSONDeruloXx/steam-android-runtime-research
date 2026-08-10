# Nova manual-capture harness guards — 2026-08-09

Status: repaired after four invalid observation attempts; no device evidence
from any invalid run is used.

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

The replacement run then passed the forward precondition and discovered the
current Steam Big Picture X11 window, but the X11 helper attempted to create
its staging directory at device-global `/tmp`. Nova's device-global `/tmp` is
not present/writable on this build, so the helper failed before producing the
PPM. That run was also stopped through the guarded teardown and its verifier
passed; it is likewise not a transport result.

The next replacement reached the same X11 tree and rootfs staging path, but the
window-ID extraction used `sed | head -n 1` under `set -o pipefail`. Finding the
first matching window caused `sed` to receive `SIGPIPE` and the helper to exit
141 before the PPM capture. That run was also cleaned and verified, and is not
transport evidence.

The following replacement had a valid forward and then failed with status 141
before X11 discovery because focus capture used
`dumpsys input | tr | awk`; the early-exiting `awk` again caused an upstream
SIGPIPE under `pipefail`. It was cleaned and verified without producing runtime
evidence.

## Repair

`capture-nova-manual-evidence.sh` now snapshots `adb forward --list` into the
phase directory and fails before any CDP/screenshot/X11 capture unless the
requested `tcp:$NOVA_CDP_PORT` forward is present. The phase status records the
forward-manifest path, making the precondition auditable.

`capture-nova-x11-window.sh` now stages the PPM under
`$DEVICE_ROOT/tmp/nova-x11-capture-run`, which is the writable device path
corresponding to `/tmp/nova-x11-capture-run` inside the chroot. It no longer
assumes that the device's global `/tmp` exists or is writable.

The window-ID parser now uses one `sed` process with an explicit early exit,
so a successful first match cannot be converted into a failure by `pipefail`.

Focus capture now stores and normalizes the complete `dumpsys input` output
first, then parses it from a file with one early-exit `sed`. No producer in the
capture path is now terminated by a downstream early-exit pipeline.

The bounded boundary poll's “latest wait” extraction was also changed from an
`rg | tail` pipeline to a single-pass `awk`, so the same audit does not leave a
masked SIGPIPE in the evidence poller.

The first successful timed-poll run then showed a separate poller logic bug:
the script retained frame 79 as “blocked” after a later successful ACK and
reported a false `blocked_ack_window`. The poller now clears a blocked frame
when that exact frame has a positive, `status=0` ACK, replaces it when the
current wait frame advances, and recognizes `ack_wait_timeout`/poll-error
events directly.

The correct order for the next run is now explicit:

1. Start the fresh manual session and wait for its current-PID readiness marker.
2. Create and verify `adb forward tcp:$NOVA_CDP_PORT tcp:8080`.
3. Run the baseline capture helper.
4. Only then inject the controlled input and collect later phases.

This is a harness repair, not a Nova/AHB finding. The next run must use a new
run ID and directory, even though the stopped session itself cleaned up
successfully.
